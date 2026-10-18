# Playbook

How to add a repository to tower and run the loop on it. Steps marked "session" need judgment and are done by Brad or by an agent session working with him; the rest are tower's commands. Anything done by hand that isn't written here is a gap: fix it in tower or add it here.

## Adding a repository

### 1. Is it ready? (session)

- The stack is one tower supports: Node with pnpm on Linux. Not yet: Swift and macOS (amyrlin) need a Mac worker and a macOS sandbox; Rust needs `~/.cargo` and `~/.rustup` in `sandbox_ro` and its own CI template.
- One command runs the type check, lint and tests, with no keys, no personal config and no network beyond installing packages. If the tests wouldn't catch a broken change, the first issues add tests.
- Public or private. Rulesets on a private repository need GitHub Pro, which Brad has had since 2026-10-17, and its CI spends the plan's Actions minutes, which public repositories don't. `tower add-repo` and `bin/draft` clone as the agent, so a private repository needs brads-agents as a collaborator (step 6 invites it) before `bin/draft` works on it.
- Note any sibling it depends on (`link:../NAME` in package.json) and list it in `siblings`. tower checks it out beside the clone at its main, refreshes and installs it before each run, and mounts it read-only for the worker. Its tests must not write into the sibling.
- tower works only in `~/novices/NAME`. Brad's own checkout and its uncommitted work are never touched.

### 2. Settings (session)

Copy `repos/gaidin.sh` to `repos/NAME.sh` and fill in each field:

- `repo`, `clone` (`$HOME/novices/NAME`, or `$HOME/novices/NAME/NAME` with siblings beside it), `state` (`$HOME/novices/state/NAME`), `siblings`.
- `setup`: the install command, from the lockfile. `check`: the command CI runs.
- `allowed`: the worker's tools. Start from gaidin's.
- `sandbox_ro`: caches the check needs, such as pnpm's store and `~/.cache/ms-playwright`. `tower add-repo NAME --apply` runs the check in the sandbox and shows what fails without them.
- `flagged`: files that steer CI, agents or dependencies: `.github/`, `AGENTS.md`, `CLAUDE.md`, the manifest and lockfiles.
- `safety_paths`: code where a mistake leaks data or lets through something that should be stopped (authentication, sandboxing, approvals, redaction). Agents get no issues there until the repository is vouched for.
- `unprovable`: files whose claims no test checks, usually docs. `uncounted`: lockfiles, left out of the size count.
- `public`: 1 for a public repository, which adds the reviewer's check for personal details. `vouched=0`.

### 3. AGENTS.md (session)

Start from `templates/AGENTS.md`. Carry over every rule from the repository's CLAUDE.md, then make CLAUDE.md the single line `@AGENTS.md`. It needs the exact check command, the safety code (matching `safety_paths`), the rule against adding dependencies in a task, and an empty "Mistakes agents have made" section.

### 4. CI (session)

Copy `templates/ci-node-pnpm.yml` to `.github/workflows/ci.yml`. Keep the job name `check`, which the ruleset requires. Install whatever the tests need so none skip, and keep the step that fails on a skipped test. A repository with a sibling dependency checks the sibling out beside it.

### 5. Land them on main (session)

Before the ruleset exists, Brad can push the AGENTS.md, CLAUDE.md and CI changes to main himself, after reading the diff with the session. Wait for CI's `check` to pass on main: the ruleset needs a run to refer to.

### 6. `tower add-repo NAME` (tower)

Run it without `--apply` and read the plan with Brad. It changes a repository's GitHub settings with his login, so get his go-ahead for each repository; approval for one doesn't extend to another. Then run `tower add-repo NAME --apply`, and again until it says the repository is set up. Each TODO points back to a step here.

### 7. First issues (session)

`bin/draft NAME "what to draft issues for"` has a model read main and open up to three issues labeled `proposed`; `--dry-run` prints them instead. Or write drafts by hand in `~/novices/issues.md`. Brad reads them and promotes the ones he wants by swapping `proposed` for `agent`. Only Brad applies `agent` and `safety-ok`: novice checks who labeled an issue and skips it otherwise.

- One small change, well under 300 changed lines (bigger diffs are refused). Several small issues beat one big one.
- The body names the files and functions involved and what to do.
- "Done when" lists conditions a reader can check: a command with its exit status and output, a test that must exist and what it asserts, and the check passing.
- If a test can't prove it (README wording, UI layout), the issue says so. Its PR gets `needs-brad`.
- An "Out of scope" line for the nearby things it shouldn't touch.
- Nothing in `safety_paths` unless Brad adds `safety-ok` to the issue: novice skips an issue that names safety code without it, and won't push a change that touches safety code without it. Flagged files (CI, the manifest and lockfile, AGENTS.md) only when the issue is about them.
- The loop takes the oldest open `agent` issue first, so post them in the order to work them.

### 8. First run (tower)

`bin/novice NAME --dry-run`, then `bin/novice NAME`. Watch the first PR through: summary comment, labels, review status, merge. Then turn on its timer: `systemctl --user enable --now tower@NAME.timer`.

## Running the loop

- `bin/novice NAME` steps until it's Brad's turn. Its timer runs it every 15 minutes; `journalctl --user -u tower@NAME` shows what it did.
- An issue the agent didn't finish, or one that came out over 300 lines, is marked tried. Fix or split the issue, then remove `~/novices/state/NAME/issue-N` to let it run again.
- A failed CI run is rerun once before the agent revises. A test that passes on the rerun is named as flaky in the summary comment and log.md's CI column; a flaky test is a bug to fix with its own issue, not something to rerun forever.
- A PR merged or closed before the loop came back to it still gets its log line on the next run.
- novice commits each log line in tower itself and never pushes, since pushing tower uses Brad's SSH key.
- A problem found after merge goes in log.md's After merge column, with a link. If a line in AGENTS.md would have prevented it, add one under "Mistakes agents have made" in a PR.
- Vouching: once log.md shows about 10 merged PRs on a repository with nothing found after merge, Brad can set `vouched=1` in its settings. It changes only the label. Opening safety code to agents is a separate decision.

## Lessons

- fish expands `~` only at the start of a word, so `GH_CONFIG_DIR=~/...` passes a literal `~`. Use `$HOME`.
- `gh auth login --web` opens Brad's default browser, signed in as brad-j, and silently mints a brad-j token. To log in as the agent, use `GH_BROWSER=echo` and open github.com/login/device in a private window signed in as brads-agents. Press Enter at "Press Enter to open...", and answer No to "Authenticate Git with your GitHub credentials?" (Yes adds credential helpers to `~/.gitconfig`; remove them if it happens).
- gh falls back to the keyring login when its config dir has none, so a script meant to act as the agent can act as Brad. Always set `GH_TOKEN` from the agent's token file.
- `gh pr list --author` goes through search and misses a PR opened seconds ago. List all open PRs and filter by author. Right after a push, `gh pr list` can still show the old head.
- Tests that skip themselves when a tool can't start make a broken runner look green. CI fails on any skipped test.
- GitHub's runners have 2 CPUs and egwene has 16, so timing bugs can fail only in CI. Reproduce them with `taskset -c 0,1` in front of the sandbox command and `--workers=1`. moiraine's first CI run found one this way: the New thread page's dock missed requests that opened after it loaded.
- `claude -p --max-budget-usd` works on the subscription, overshoots by about one turn, and each run costs about $0.02 before any work. There's no max-turns flag. Typical costs: worker $0.06 to $0.12, review $0.01 to $0.03.
- A worker run that fails before working (401, crash, timeout) must not mark the issue tried or post to GitHub.
- Brad can merge while CI or the reviewer is still running, so check the PR is still open before revising and before pushing. The required `review` status now stops this unless he bypasses.
- The reviewer sees only the issue, the PR description and the diff. Evidence the worker posts in a revision comment counts only because review-pr includes those comments as the author's claims.
- `Bash(node *)` lets the worker run anything through Node, so the allow list is looser than it reads. The sandbox and the missing tokens are what contain it.
- bash reads a script as it runs, so editing `bin/novice` in place can break a run in progress. Write the new version to another file and `mv` it over; the running loop keeps the old one.
- GitHub won't link a PR to a closed issue with `Closes #N`; reopen the issue first.
- Brad's protected-path gate blocks commands that name credential paths or contain words like `.key` (even in a jq filter) and stops after two blocks. Check sandbox isolation from inside the sandbox without naming those paths in the outer command, or ask Brad to run the check.

## Gaps

Found while adding moiraine, the first repository added through this playbook.

- Fixed: tower had no sibling checkouts, and `add-repo` without `--apply` created the state directory.
- Open: `add-repo` runs its sandbox check on all of egwene's CPUs, so it misses timing failures that GitHub's 2-CPU runners hit. Running it under `taskset -c 0,1` would match CI.
- Open: the sandbox check only runs once AGENTS.md and CI are on main, so a repository's tests are first tried in the sandbox by hand (step 1). `add-repo` could offer the check earlier, on Brad's checkout or a scratch clone.
