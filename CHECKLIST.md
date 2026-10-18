# Brad's checklist

What only Brad does. Everything else is tower's job.

## When a PR has `needs-brad`

PRs whose CI and review pass merge themselves. The loop stops on a PR and labels it `needs-brad` only when the review blocked or CI failed even after the agent's automatic revision, when your revisions on it are used up, or when auto-merge is off, paused or failed. Filter on the label to find them.

- Read the summary comment at the bottom of the PR. Its last line says why it stopped.
- Merge (with your admin bypass if the `review` check failed), close it, or choose "Request changes" with what to fix. The agent gets two revisions for you per PR, and a revised PR that passes merges itself.
- Don't bypass a pending or failed `review` check unless you mean to.
- The timer runs `bin/novice NAME` within about 2 minutes of anything you do on GitHub.

## After merging

- novice fills in "Brad stepped in" in `log.md` on its next run. To give a reason for closing, leave it as your last comment on the PR before you close it.
- When something a PR broke turns up later, open an issue saying "Broken by #N" (the PR) or revert it on main, and novice notes it under "After merge". Anything subtler you write in by hand; novice never overwrites your entries.
- Commit your edits to `log.md` and push tower now and then. The loop commits its own log lines but never pushes, and while `log.md` has your uncommitted edits it only appends.

## Issues

- Pick or write each issue before code exists. It's one small change with a "Done when" list you could check yourself.
- Only you add the `agent` label; novice skips an issue labeled by anyone else.
- An issue that has to wait for another gets a line "Blocked by #N", or `brad-j/NAME#N` for another repository. novice also opens a `proposed` issue on a sibling when a worker finds it needs that first.
- `bin/draft NAME "what you want"` opens `proposed` issues. Read them, then swap `proposed` for `agent` on the ones you want, or close them.
- An issue that names safety code waits until you add `safety-ok`. Add it only when you mean an agent to change that code, and read those PRs closely.
- An issue whose change adds over 300 lines gets no PR. Split it, or add `big-ok` if it belongs in one PR; the issue runs again.

## Now and then

- Read `log.md`. A repository with about 10 clean merges can be vouched for: set `vouched=1` in `repos/NAME.sh`. novice says so in its journal when the log shows 10.
- To approve every PR on a repository yourself, set `automerge=0` in `repos/NAME.sh`, then run `tower add-repo NAME` and `--apply` to require an approval again. Set it back to 1 and run it again to return to auto-merge.
- After CI fails on main following an auto-merge: merge or fix the revert PR, which needs your admin bypass for `review`, then remove `~/novices/state/NAME/automerge-paused`.
- Approve each new repository's GitHub setup when `tower add-repo` shows its plan.
- To stop the agents on a repository: `systemctl --user disable --now tower@NAME.timer`.

## Logins and tokens

- Never paste a token into a chat.
- Your gh login, after revoking it: `gh auth login --hostname github.com --git-protocol ssh --web`. Skip the SSH key upload, and answer No to "Authenticate Git with your GitHub credentials?".
- The agent's login is in `~/.config/gh-agents`, separate from yours. PLAYBOOK.md's Lessons say how to redo it.
