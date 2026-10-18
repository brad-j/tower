# Shared by bin/novice and bin/review-pr: loads repos/NAME.sh, and the checks both apply to a diff.
# Sets tower (this repository's root) and repo_name, plus whatever the settings file sets.

tower=$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/.." && pwd)

# Brad's GitHub account, and the machine account the agents act as. Only bin/tower uses Brad's login.
owner=brad-j
agent=brads-agents
agent_email=344078136+brads-agents@users.noreply.github.com
agent_token=$HOME/.config/gh-agents/token
# Bigger diffs aren't opened, pushed or reviewed; the issue gets split instead.
max_lines=300
# A merged PR with no problem found after this many days gets "none" in log.md's After merge column.
quiet_days=7

# Labels tower uses on each repository, as NAME|COLOR|DESCRIPTION.
labels=(
	"agent|5319E7|Ready for an agent to work on"
	"proposed|C5DEF5|Drafted by a model for Brad to read; he promotes it to agent or closes it"
	"safety-ok|B60205|Brad allows an agent to change safety code for this issue"
	"needs-brad|D876E3|Brad reads this PR closely: flagged files, safety code, docs, or something a test can't prove"
	"size:S|0E8A16|Under 30 changed lines, lockfiles not counted"
	"size:M|FBCA04|30 to 99 changed lines, lockfiles not counted"
	"size:L|D93F0B|100 to 300 changed lines, lockfiles not counted"
	"size:XL|B60205|Over 300 changed lines: over the limit, split it"
	"vouch:trusted|0E8A16|Written by Brad, or by the agent on a repo where Brad has vouched for it"
	"vouch:unvouched|FBCA04|Written by the agent before it has earned trust on this repo: read with more care"
	"automerge|0E8A16|novice merges this when its waiting time is up; Brad removes the label to stop it"
)

# The names in labels, space-separated.
join_names() { printf '%s\n' "$@" | cut -d'|' -f1 | paste -sd' '; }

# CI's job name, which the main ruleset requires; every repo's CI workflow has a job by this name.
ci_job=check

# The main ruleset for a repo whose CI runs on the app INTEGRATION (GitHub Actions is 15368): a PR with APPROVALS
# approvals (1, or 0 where novice auto-merges), CI's job and the reviewer's review status required, no force push or
# deletion, and admins (Brad) can bypass.
ruleset_spec() {
	jq -n --arg job "$ci_job" --argjson app "$1" --argjson approvals "$2" '{
		name: "main", target: "branch", enforcement: "active",
		conditions: {ref_name: {exclude: [], include: ["~DEFAULT_BRANCH"]}},
		bypass_actors: [{actor_id: 5, actor_type: "RepositoryRole", bypass_mode: "always"}],
		rules: [
			{type: "deletion"},
			{type: "non_fast_forward"},
			{type: "pull_request", parameters: {
				required_approving_review_count: $approvals, dismiss_stale_reviews_on_push: true, required_reviewers: [],
				require_code_owner_review: false, require_last_push_approval: false,
				required_review_thread_resolution: false, require_extra_approval_for_unattributed_changes: true,
				allowed_merge_methods: ["merge", "squash", "rebase"]}},
			{type: "required_status_checks", parameters: {
				strict_required_status_checks_policy: false, do_not_enforce_on_create: false,
				required_status_checks: [{context: $job, integration_id: $app}, {context: "review"}]}}
		]}'
}

# The size label for a count of changed lines.
size_label() {
	if [ "$1" -lt 30 ]; then echo size:S
	elif [ "$1" -lt 100 ]; then echo size:M
	elif [ "$1" -le "$max_lines" ]; then echo size:L
	else echo size:XL; fi
}

load_settings() {
	repo_name=${1:-}
	local file=$tower/repos/$repo_name.sh var
	if ! [[ $repo_name =~ ^[a-z0-9-]+$ ]] || [ ! -f "$file" ]; then
		echo "no settings for '$repo_name'; repos: $(cd "$tower/repos" && ls -- *.sh | sed 's/\.sh$//' | tr '\n' ' ')" >&2
		exit 1
	fi
	# shellcheck source=/dev/null
	. "$file"
	for var in repo clone siblings state setup check allowed sandbox_ro flagged safety_paths unprovable uncounted public vouched automerge; do
		declare -p "$var" > /dev/null 2>&1 || { echo "$file doesn't set $var" >&2; exit 1; }
	done
	# bwrap options for the sandbox: the repo's caches read-only, and separately its siblings read-only.
	sandbox_args=() sibling_args=()
	local path sibling
	for path in "${sandbox_ro[@]}"; do sandbox_args+=(--ro-bind "$path" "$path"); done
	for sibling in "${siblings[@]}"; do
		path=$(sibling_dir "$sibling")
		sibling_args+=(--ro-bind "$path" "$path")
	done
}

# Where the checkout of sibling OWNER/NAME lives: NAME beside the clone.
sibling_dir() { echo "$(dirname "$clone")/${1##*/}"; }

# Brings each sibling to its origin/main and installs its dependencies with the repo's setup command in the sandbox,
# the only time a sibling is writable there. Appends the output to the file $1.
refresh_siblings() {
	local sibling dir
	for sibling in "${siblings[@]}"; do
		dir=$(sibling_dir "$sibling")
		git -C "$dir" fetch -q --prune origin || return 1
		git -C "$dir" reset -q --hard origin/main && git -C "$dir" clean -qfd || return 1
		"$tower/bin/sandbox" "$dir" "${sandbox_args[@]}" -- "${setup[@]}" >> "$1" 2>&1 || return 1
	done
}

# Lines added plus lines removed between origin/main and REF, leaving out the uncounted files (lockfiles). Run in the clone.
diff_lines() {
	local excludes=() path
	for path in "${uncounted[@]}"; do excludes+=(":(exclude)$path"); done
	git diff --numstat "origin/main...$1" -- . "${excludes[@]}" | awk '{ n += $1 + $2 } END { print n + 0 }'
}

# Of the file names on stdin, the ones in the safety code.
safety_files() {
	local file path
	while IFS= read -r file; do
		[ -n "$file" ] || continue
		for path in "${safety_paths[@]}"; do
			if [[ $file == "$path"* ]]; then echo "$file"; break; fi
		done
	done
}

# Of the file names on stdin, the ones Brad reads closely: the flagged pattern and the safety code.
flagged_files() {
	local file
	while IFS= read -r file; do
		[ -n "$file" ] || continue
		if [[ $file =~ $flagged ]]; then echo "$file"; else safety_files <<< "$file"; fi
	done
}

# The safety paths that the text on stdin names, by path or by file name (src/markdown.tsx or markdown.tsx; a
# directory as src/browser/ or browser/), comma-separated.
safety_named() {
	local text path name found=()
	text=$(cat)
	for path in "${safety_paths[@]}"; do
		name=${path%/}; name=${name##*/}; [[ $path == */ ]] && name+=/
		if grep -qF -e "$path" -e "$name" <<< "$text"; then found+=("$path"); fi
	done
	[ "${#found[@]}" = 0 ] || printf '%s\n' "${found[@]}" | paste -sd, | sed 's/,/, /g'
}

# What bin/novice compares to see whether anything happened on GitHub since its last full run: when the repo's and its
# siblings' issues and PRs last changed (a comment, label, review, merge or close), and the open PRs' heads (a push).
github_stamp() {
	local name
	for name in "$repo" "${siblings[@]}"; do
		gh api "repos/$name/issues?state=all&sort=updated&direction=desc&per_page=1" -q '"'"$name"' \(.[0].updated_at // "")"'
	done
	gh pr list -R "$repo" --state open --json number,headRefOid -q '.[] | "#\(.number) \(.headRefOid)"'
}

# log.md's rows for the repo NAME, oldest first, as tab-separated cells: PR, Brad stepped in, After merge. Cells are
# counted from the row's end, since an issue's title can hold a pipe.
log_rows() {
	awk -F'|' -v name="$1" '
		function trim(s) { gsub(/^ +| +$/, "", s); return s }
		NF >= 13 && trim($3) == name { print trim($(NF - 8)) "\t" trim($(NF - 2)) "\t" trim($(NF - 1)) }' "$tower/log.md"
}

# Sets the review commit status on SHA, which the main ruleset requires: STATE is pending, success, failure or error.
review_status() {
	local args=(-f state="$2" -f context=review -f description="${3:0:140}")
	[ -n "${4:-}" ] && args+=(-f target_url="$4")
	gh api -X POST "repos/$repo/statuses/$1" "${args[@]}" > /dev/null
}
