# Shared by bin/novice and bin/review-pr: loads repos/NAME.sh, and the checks both apply to a diff.
# Sets tower (this repository's root) and repo_name, plus whatever the settings file sets.

tower=$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/.." && pwd)
# Bigger diffs aren't opened, pushed or reviewed; the issue gets split instead.
max_lines=300

# Labels tower uses on each repository, as NAME|COLOR|DESCRIPTION.
labels=(
	"agent|5319E7|Ready for an agent to work on"
	"needs-brad|D876E3|Brad reads this PR closely: flagged files, safety code, docs, or something a test can't prove"
	"size:S|0E8A16|Under 30 changed lines, lockfiles not counted"
	"size:M|FBCA04|30 to 99 changed lines, lockfiles not counted"
	"size:L|D93F0B|100 to 300 changed lines, lockfiles not counted"
	"size:XL|B60205|Over 300 changed lines: over the limit, split it"
	"vouch:trusted|0E8A16|Written by Brad, or by the agent on a repo where Brad has vouched for it"
	"vouch:unvouched|FBCA04|Written by the agent before it has earned trust on this repo: read with more care"
)

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
	for var in repo clone state setup check allowed sandbox_ro flagged safety_paths unprovable uncounted public vouched; do
		declare -p "$var" > /dev/null 2>&1 || { echo "$file doesn't set $var" >&2; exit 1; }
	done
}

# Lines added plus lines removed between origin/main and REF, leaving out the uncounted files (lockfiles). Run in the clone.
diff_lines() {
	local excludes=() path
	for path in "${uncounted[@]}"; do excludes+=(":(exclude)$path"); done
	git diff --numstat "origin/main...$1" -- . "${excludes[@]}" | awk '{ n += $1 + $2 } END { print n + 0 }'
}

# Of the file names on stdin, the ones Brad reads closely: the flagged pattern and the safety code.
flagged_files() {
	local file path
	while IFS= read -r file; do
		[ -n "$file" ] || continue
		if [[ $file =~ $flagged ]]; then echo "$file"; continue; fi
		for path in "${safety_paths[@]}"; do
			if [[ $file == "$path"* ]]; then echo "$file"; break; fi
		done
	done
}

# Sets the review commit status on SHA, which the main ruleset requires: STATE is pending, success, failure or error.
review_status() {
	local args=(-f state="$2" -f context=review -f description="${3:0:140}")
	[ -n "${4:-}" ] && args+=(-f target_url="$4")
	gh api -X POST "repos/$repo/statuses/$1" "${args[@]}" > /dev/null
}
