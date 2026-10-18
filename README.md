# tower

Runs coding agents on Brad's repositories through small GitHub issues, branches and PRs, with tests as the merge gate and an adversarial reviewer that shares no memory with the worker. Each repository gets a settings file; the scripts don't name any one of them.

To set tower up on a machine, follow `SETUP.md`. To add a repository, follow `PLAYBOOK.md`. What only Brad does is in `CHECKLIST.md`.

## Commands

- `bin/tower add-repo NAME [--apply]`: checks that a repository is ready and sets up its GitHub settings, labels, ruleset, the agents' clone and the check in the sandbox. Without `--apply` it changes nothing.
- `bin/novice REPO [--dry-run]`: the loop. Starts the oldest untried `agent` issue or revises the open agent PR, and stops when it's Brad's turn.
- `bin/review-pr REPO PR [--dry-run]` or `bin/review-pr REPO --head REF --issue N`: the reviewer. Sees only the issue, the PR description and the diff.
- `bin/draft REPO "REQUEST" [--count N] [--dry-run]`: a model reads main and opens up to N issues (default 3) labeled `proposed` for Brad to promote to `agent`.
- `bin/sandbox DIR [BWRAP_OPTION...] -- COMMAND...`: the bubblewrap sandbox the worker runs in.
- `systemd/tower@.timer`: runs `bin/novice NAME` every 2 minutes for each repository whose timer is enabled (SETUP.md, step 9). A run where nothing changed on GitHub exits after a few calls.

`REPO` is a file name in `repos/` without `.sh`.

What they leave on a PR:

- review-pr tells the reviewer CI's result and test counts on the PR's head, so a passing check isn't listed as unverified. It sets the commit status `review`, which the repo's `main` ruleset requires alongside CI: pending while it runs, success, failure on blocking findings, error if it didn't run. An unreviewed or blocked PR can't merge without an admin bypass.
- When it's Brad's turn, novice posts a one-line summary (CI, review, lines changed, flagged files, docs, how many done conditions the reviewer couldn't verify) and adds the `needs-brad` label if the PR touches flagged files or safety code, changes docs, or has unverified done conditions.
- novice labels each agent PR by size (`size:S` under 30 changed lines, `size:M` under 100, `size:L` up to 300, `size:XL` over) and by trust: `vouch:unvouched` until Brad sets `vouched=1` in the repo's settings, then `vouch:trusted`. Brad's own PRs get `vouch:trusted`. Vouching changes only the label. `lib/tower.sh` lists every label tower uses.
- A failed CI run is rerun once before it counts. If the rerun passes, the summary and log name the flaky test.
- novice skips an issue while a "Blocked by #N" (or `OWNER/NAME#N`) line in its body names an open issue. An issue it tried runs again once it's edited or a blocker is closed as completed. When a worker stops because a sibling needs changing first, novice opens the issue it drafted there as `proposed` and treats it as a blocker.
- Each run fills in log.md's "Brad stepped in" for agent PRs merged or closed since (auto-merged, merged as-is, merged after a fix with Brad's commit subjects, or closed with his last comment), and "After merge" for a revert on main or an issue saying "Broken by #N", or "none" after 7 days without one. It never overwrites what Brad wrote, and it says in the journal when a repository has 10 clean merges.
- Where Brad has set `vouched=1` and `automerge=1`, novice labels a PR `automerge` when it's size S or M, touches no flagged files, safety code or docs, passed CI the first time, and passed review with nothing unverified, and merges it an hour later unless Brad removes the label or requests changes. If CI then fails on main, it opens a revert PR, labels it `needs-brad`, and pauses auto-merge on that repository until Brad removes `~/novices/state/NAME/automerge-paused`. `tower add-repo` drops the ruleset's required approval only on such a repository.
- novice starts only issues whose `agent` label Brad applied. It skips an issue that names safety code, and won't push a change that touches it, unless Brad has added `safety-ok`.
- Diffs over 300 changed lines (`max_lines` in `lib/tower.sh`, lockfiles not counted) aren't opened, pushed or reviewed. The issue needs splitting.

## Layout

- `repos/NAME.sh`: per-repo settings (GitHub repo, clone, state dir, setup and check commands, worker tools, sandbox paths, flagged files, safety code, docs, uncounted files, public or not). `lib/tower.sh` loads them, says which ones are missing, and holds the checks both scripts share.
- `lib/tower.sh`: the accounts, labels, size limit and ruleset shared by the scripts. `lib/pre-push`: the hook installed in each clone.
- `templates/`: AGENTS.md and CI to start a new repository from.
- `log.md`: one line per worker run, with what Brad did and any problem found after merge. novice commits each line it adds ("Log REPO: ...") but never pushes tower; Brad's pushes take them up.
- `~/novices/`, outside this repo: the agents' clones (`~/novices/gaidin`), loop state (`~/novices/state/NAME/`) and issue drafts.

Secrets stay outside the repo: the agent's GitHub token in `~/.config/gh-agents/token`, the worker's Claude token in `~/.config/novices/claude-token`. Scripts that talk to GitHub always set `GH_TOKEN` from the agent's token, so they can't fall back to Brad's keyring login.
