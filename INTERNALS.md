# How tower works

What happens inside a run, who can do what, and what the loop keeps on disk. For setup see `SETUP.md`, for adding a repository `PLAYBOOK.md`, and for Brad's part `CHECKLIST.md`. The scripts' header comments are the authority; this file says how the pieces fit.

## An issue from label to merge

1. Brad writes an issue, or `bin/draft` opens one labeled `proposed`. Brad promotes it by swapping `proposed` for `agent`.
2. The timer starts `bin/novice NAME`. Before any work it:
   - exits if another run holds the lock, or if the last run failed less than 15 minutes ago;
   - exits if the GitHub stamp (when the repository's and siblings' issues and PRs last changed, and the open PRs' heads) matches the last full run's, the day hasn't changed, and no auto-merge is due;
   - fills in log.md's "Brad stepped in" and "After merge" for agent PRs closed since, and says in the journal when a repository reaches 10 clean merges;
   - logs PRs merged or closed before the loop came back to them, and labels Brad's own open PRs `vouch:trusted`.
3. Then it steps until it's Brad's turn. With more than one agent PR open it stops. With one, it steps that PR (step 5). With none, it starts an issue (step 4).
4. Starting an issue. novice takes the lowest-numbered open `agent` issue and skips it if:
   - it was tried, unless it's been edited or a blocker was closed as completed since, or it was too big and Brad has since added `big-ok`;
   - a "Blocked by" line names an open issue;
   - someone other than Brad applied the `agent` label;
   - it names safety code without Brad's `safety-ok` (novice comments once to say so).

   It checks the day's run budget, checks out `agent/issue-N` from `origin/main`, refreshes the siblings, runs the setup command in the sandbox, and runs the worker. Then:
   - a worker that crashed, timed out or hit a login error stops the run and leaves the issue untried;
   - no commits: novice comments on the issue, opens a sibling issue if the worker drafted one, marks the issue tried and logs it;
   - safety code touched without `safety-ok`, or adding over `max_lines` lines without `big-ok`: no PR, the branch stays local, the issue is marked tried with the reason;
   - otherwise novice pushes, opens a PR with `Closes #N` (and a warning for flagged files), sets the `review` status to pending, and steps the new PR.
5. Stepping a PR. novice sets its size and vouch labels, waits for CI (up to 10 minutes for the run to appear, 25 for it to finish), and reruns a failure once, noting the failed tests. It runs `bin/review-pr` unless the reviewer already marked this head, and writes the log line. Then, in order:
   - the PR was merged or closed meanwhile: move on;
   - Brad requested changes since the last one handled: a revision for Brad, up to 2 per PR;
   - CI failed or the review blocked: one automatic revision per PR, with the failed log and the review as feedback;
   - otherwise: the summary comment, then the merge if the repository has `automerge=1` and it isn't paused there or stopped on the PR. If it doesn't merge, the PR gets `needs-brad` and it's Brad's turn.

   A revision adds commits on the same branch. It isn't pushed if the PR closed while the worker ran, if it brings the lines added over `max_lines` without `big-ok`, or if it brings in safety code without `safety-ok`. When the revisions are used up, the summary goes on with `needs-brad` and it's Brad's turn.
6. On a `needs-brad` PR, Brad merges, closes or requests changes. His action changes the stamp, so the next timer run does a full pass.

## Who can do what

| Actor | Runs as | Can | Can't |
|---|---|---|---|
| `bin/tower` | Brad's gh keyring login | change repository settings, labels and the ruleset; accepts the invitation as brads-agents | runs only when Brad or a session with his go-ahead starts it |
| `bin/novice`, `bin/review-pr`, `bin/draft` | brads-agents, `GH_TOKEN` from `~/.config/gh-agents/token` | push branches, open and comment on PRs and issues, set the `review` status, merge (auto-merge only) | push to main (ruleset, and the pre-push hook) or use Brad's login |
| Worker | Claude Code in `bin/sandbox`, worker Claude token in the environment | edit the clone, run the allowed tools, reach the network | push, run `gh`, `git remote`, `git config` or `curl`; see `~/.ssh`, `~/.config` or any GitHub token; change `.git/config` or hooks |
| Reviewer | host Claude Code, Brad's Claude login | read the prompt: issue, PR description, the worker's revision notes, CI's result, the diff | use any tool, read the repository or AGENTS.md |
| Drafter | Claude Code in `bin/sandbox`, worker Claude token | Read, Glob and Grep a fresh shallow clone of main | write or run anything; `bin/draft` opens the issues |

`Bash(node *)` lets the worker run any code through Node, so the sandbox and the missing GitHub token are what contain it, not the allow list. On GitHub, the `main` ruleset requires a PR, one approval (none on an auto-merge repository), CI's `check` job from GitHub Actions and the `review` status. Brad can bypass it as admin.

## Loop state

Everything novice remembers about a repository is in `~/novices/state/NAME/`. Removing a file is the supported way to reset that piece.

| File | Holds | Removing it |
|---|---|---|
| `lock` | flock held by a running novice or `tower add-repo --apply` | don't while a run holds it: the next run locks a new file and runs alongside |
| `stamp` | the day and GitHub stamp from the last full run | forces a full run next time |
| `failed` | when the last run stopped on an error (epoch seconds) | ends the 15-minute wait |
| `runs-YYYY-MM-DD` | one line per worker run that day | gives back the day's runs |
| `issue-N` | that issue was tried, and what happened | lets it run again |
| `body-N` | hash of the issue's title and body when it was tried | an edit is detected against it; removed with `issue-N` |
| `blocked-by-N` | sibling issues the loop opened for issue N, as `OWNER/NAME#N` | forgets those blockers |
| `pending-SHA` | the log line for a pushed head, waiting for CI and review | the run is never logged |
| `rerun-SHA` | tests that failed on the head's first CI run; present once it's been rerun | allows another rerun |
| `pr-N.auto-revisions`, `pr-N.brad-revisions` | revision counts on the PR | gives back revisions |
| `pr-N.brad-handled` | the id of Brad's last "Request changes" acted on | makes the loop act on it again |
| `outcome-N` | the "Brad stepped in" value written for the PR | it's worked out again, but log.md's cell is never overwritten |
| `after-N` | `found` or `none` for "After merge" | a `found` PR is checked again; others are checked until 30 days after merge regardless |
| `automerge-N` | `HEAD SECONDS` when the label went on, or `stopped` once Brad removed it or the merge failed | the PR can be labeled again |
| `automerge-paused` | why auto-merge stopped on the repository | resumes auto-merge |
| `vouch-hint` | the clean and problem merge counts last reported | the hint is said again |

log.md commits take `tower/.git/tower-log.lock`, so runs on different repositories don't commit over each other.

## When the loop does nothing

`bin/novice NAME --dry-run` says what the next step would be, without the stamp check. `journalctl --user -u tower@NAME -e` shows what the timer's runs did. In order of likelihood:

- Nothing changed on GitHub, so the run exited silently. Remove `stamp` to force a full pass.
- The last run failed less than 15 minutes ago. The journal has the error.
- The day's 25 worker runs are used.
- The issue was tried: the journal says "skipping #N, tried before". Edit the issue or remove `issue-N`.
- The `agent` label was applied by someone other than Brad, by brads-agents or by an automation. Remove it and add it again as brad-j.
- The issue names safety code. The issue has a comment saying so; add `safety-ok` or edit the safety code out.
- A "Blocked by" issue is still open. For an issue already tried, closing a blocker as not planned doesn't trigger a retry; only "completed" does.
- More than one agent PR is open. Close or merge one.
- The PR is waiting on Brad: its revisions are used up, or CI and the review passed.
- The timer isn't enabled: `systemctl --user list-timers 'tower@*'`.
