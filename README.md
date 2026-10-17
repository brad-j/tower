# tower

Runs coding agents on Brad's repositories through small GitHub issues, branches and PRs, with tests as the merge gate and an adversarial reviewer that shares no memory with the worker. Each repository gets a settings file; the scripts don't name any one of them.

## Commands

- `bin/novice REPO [--dry-run]`: the loop. Starts the oldest untried `agent` issue or revises the open agent PR, and stops when it's Brad's turn.
- `bin/review-pr REPO PR [--dry-run]` or `bin/review-pr REPO --head REF --issue N`: the reviewer. Sees only the issue, the PR description and the diff.
- `bin/sandbox DIR [BWRAP_OPTION...] -- COMMAND...`: the bubblewrap sandbox the worker runs in.

`REPO` is a file name in `repos/` without `.sh`.

What they leave on a PR:

- review-pr sets the commit status `review`, which the repo's `main` ruleset requires alongside CI: pending while it runs, success, failure on blocking findings, error if it didn't run. An unreviewed or blocked PR can't merge without an admin bypass.
- When it's Brad's turn, novice posts a one-line summary (CI, review, lines changed, flagged files, docs, how many done conditions the reviewer couldn't verify) and adds the `needs-brad` label if the PR touches flagged files or safety code, changes docs, or has unverified done conditions.
- Diffs over 300 changed lines (`max_lines` in `lib/tower.sh`, lockfiles not counted) aren't opened, pushed or reviewed. The issue needs splitting.

## Layout

- `repos/NAME.sh`: per-repo settings (GitHub repo, clone, state dir, setup and check commands, worker tools, sandbox paths, flagged files, safety code, docs, uncounted files, public or not). `lib/tower.sh` loads them, says which ones are missing, and holds the checks both scripts share.
- `log.md`: one line per worker run, with what Brad did and any problem found after merge.
- `~/novices/`, outside this repo: the agents' clones (`~/novices/gaidin`), loop state (`~/novices/state/NAME/`) and issue drafts.

Secrets stay outside the repo: the agent's GitHub token in `~/.config/gh-agents/token`, the worker's Claude token in `~/.config/novices/claude-token`. Scripts that talk to GitHub always set `GH_TOKEN` from the agent's token, so they can't fall back to Brad's keyring login.
