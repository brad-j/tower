# tower

Runs coding agents on Brad's repositories through small GitHub issues, branches and PRs, with tests as the merge gate and an adversarial reviewer that shares no memory with the worker. Each repository gets a settings file; the scripts don't name any one of them.

## Commands

- `bin/novice REPO [--dry-run]`: the loop. Starts the oldest untried `agent` issue or revises the open agent PR, and stops when it's Brad's turn.
- `bin/review-pr REPO PR [--dry-run]` or `bin/review-pr REPO --head REF --issue N`: the reviewer. Sees only the issue, the PR description and the diff.
- `bin/sandbox DIR [BWRAP_OPTION...] -- COMMAND...`: the bubblewrap sandbox the worker runs in.

`REPO` is a file name in `repos/` without `.sh`.

## Layout

- `repos/NAME.sh`: per-repo settings (GitHub repo, clone, state dir, setup and check commands, worker tools, sandbox paths, flagged files, safety code, public or not). `lib/settings.sh` loads them and says which ones are missing.
- `log.md`: one line per agent PR.
- `~/novices/`, outside this repo: the agents' clones (`~/novices/gaidin`), loop state (`~/novices/state/NAME/`) and issue drafts.

Secrets stay outside the repo: the agent's GitHub token in `~/.config/gh-agents/token`, the worker's Claude token in `~/.config/novices/claude-token`. Scripts that talk to GitHub always set `GH_TOKEN` from the agent's token, so they can't fall back to Brad's keyring login.
