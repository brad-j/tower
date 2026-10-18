# Brad's checklist

What only Brad does. Everything else is tower's job.

## When the loop stops on a PR

- Read the summary comment at the bottom of the PR.
- If it has `needs-brad`, read the parts it names: flagged files, safety code, docs, or the done conditions the reviewer couldn't verify.
- Approve and merge, or choose "Request changes" with what to fix. The agent gets two revisions for you per PR.
- Don't bypass a pending or failed `review` check unless you mean to.
- The timer runs `bin/novice NAME` within 15 minutes. Run it by hand to go sooner.

## After merging

- Fill in "Brad stepped in" in `log.md`: merged as-is, merged after a fix (what), or closed (why).
- When something a PR broke turns up later, however late, note it under "After merge" with a link.
- Commit your edits to `log.md` and push tower now and then. The loop commits its own log lines but never pushes, and while `log.md` has your uncommitted edits it only appends.

## Issues

- Pick or write each issue before code exists. It's one small change with a "Done when" list you could check yourself.
- Only you add the `agent` label; novice skips an issue labeled by anyone else.
- `bin/draft NAME "what you want"` opens `proposed` issues. Read them, then swap `proposed` for `agent` on the ones you want, or close them.
- An issue that names safety code waits until you add `safety-ok`. Add it only when you mean an agent to change that code, and read those PRs closely.

## Now and then

- Read `log.md`. A repository with about 10 clean merges can be vouched for: set `vouched=1` in `repos/NAME.sh`.
- Approve each new repository's GitHub setup when `tower add-repo` shows its plan.
- To stop the agents on a repository: `systemctl --user disable --now tower@NAME.timer`.

## Logins and tokens

- Never paste a token into a chat.
- Your gh login, after revoking it: `gh auth login --hostname github.com --git-protocol ssh --web`. Skip the SSH key upload, and answer No to "Authenticate Git with your GitHub credentials?".
- The agent's login is in `~/.config/gh-agents`, separate from yours. PLAYBOOK.md's Lessons say how to redo it.
