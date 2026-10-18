# Agent runs

One line per worker run that produced a PR or tried to. bin/novice writes the first nine columns.

- Brad stepped in: merged as-is, merged after a fix (what), or closed (why).
- After merge: problems found once it was on main, with links: a revert, a follow-up fix, a bug traced to this PR. Fill it in whenever one turns up, however late; "none" once it's been on main a while without one.

| Date | Repo | Issue | PR | Model | Turns | Est. cost | CI | Review | Brad stepped in | After merge |
|---|---|---|---|---|---|---|---|---|---|---|
| 2026-10-17 | gaidin | #1 unknown option stack trace | #6 | sonnet-5.5 medium | 6 | $0.11 | pass, first try | no blocking findings, $0.02 | merged as-is | |
| 2026-10-17 | gaidin | #2 `connector remove` is listed among the rule commands in the usage | #7 | sonnet-5.5 medium | 6 | $0.07 | success | pass | merged as-is | |
| 2026-10-17 | gaidin | #3 Declare the supported Node version in package.json | #8 | sonnet-5.5 medium | 6 | $0.06 | success | pass | merged as-is | |
| 2026-10-17 | gaidin | #4 A "Try it locally" section in the README | #9 | sonnet-5.5 medium | 11 | $0.12 | success | block | merged before the review finished | README on main: the clone line fails if pasted, and it doesn't say each ask appends to slept.log. Follow-up fix: #10 (#4 reopened for it). |
| 2026-10-17 | gaidin | #4 follow-up to #9 (the revision made for #9, pushed after its merge) | #10 | sonnet-5.5 medium | 10 | $0.09 | success | block | | |
| 2026-10-17 | gaidin | #4 revision (auto) | #10 | sonnet-5.5 medium | 4 | $0.08 | success | pass | merged as-is | |
| 2026-10-17 | moiraine | #2 Service worker can keep a shell whose build files it doesn't have, so the app opens blank offline | #10 | sonnet-5.5 medium | 8 | $0.15 | success | pass | merged as-is | |
| 2026-10-17 | moiraine | #3 An open app never notices a new protocol or a new build | #11 | sonnet-5.5 medium | 22 | $0.42 | failure | block | | |
| 2026-10-17 | moiraine | #3 revision (auto) | #11 | sonnet-5.5 medium | 5 | $0.14 | success | pass | merged as-is | |
| 2026-10-17 | moiraine | #1 Alt+Y/A/N answer approvals while typing in any field (Option+N on a Mac denies) | #9 | sonnet-5.5 medium | 13 | $0.16 | success | none, merged before the loop came back | merged as-is | |
| 2026-10-17 | moiraine | #5 Markdown: backslash escapes show their backslash, and task lists render as text | #12 | sonnet-5.5 medium | 29 | $0.41 | success on a rerun (flaky: e2e/browser.spec.ts:12:1 › an agent hands the browser over; the owner takes it over from the dock, types into the page, and is done) | block | | |
| 2026-10-17 | moiraine | #5 revision (auto) | #12 | sonnet-5.5 medium | 11 | $0.17 | success | pass | merged as-is | |
| 2026-10-17 | gaidin | #5 `gaidin --version` | #11 | sonnet-5.5 medium | 10 | $0.13 | success | pass | merged as-is | |
| 2026-10-17 | moiraine | #8 Unsaved edits on pages are dropped on navigation or reload | #13 | sonnet-5.5 medium | 15 | $0.44 | success | block | | |
| 2026-10-17 | moiraine | #8 revision (auto) | #13 | sonnet-5.5 medium | 13 | $0.19 | success on a rerun (flaky: e2e/browser.spec.ts:12:1 › an agent hands the browser over; the owner takes it over from the dock,  types into the page,  and is done) | block | | |
| 2026-10-17 | moiraine | #8 revision (brad) | #13 | sonnet-5.5 medium | 10 | $0.21 | success on a rerun (flaky: `e2e/app.spec.ts:212:1 › an agent in the rail goes back to its conversation shown last, or home from its own conversation`) | pass | merged as-is | |
| 2026-10-17 | moiraine | #7 One app-wide event stream in place of polling activity, approvals, schedule and spend | none | sonnet-5.5 medium | 2 | $0.05 | | | | |
| 2026-10-17 | gaidin | #12 An app-wide event stream, starting with approvals | #14 | sonnet-5.5 medium | 12 | $0.17 | success | block | | |
| 2026-10-17 | gaidin | #12 revision (auto) | #14 | sonnet-5.5 medium | 13 | $0.18 | success | pass | merged as-is | |
| 2026-10-17 | gaidin | #13 Activity and conversation events on the app-wide stream | #15 | sonnet-5.5 medium | 34 | $0.61 | success | block | merged as-is | |
| 2026-10-17 | silviana | #1 /api/usage: worker spend by day and repo from log.md, and tower's limits | #6 | sonnet-5.5 medium | 9 | $0.15 | success | pass | merged as-is | |
| 2026-10-17 | silviana | #2 A usage page: per-repo totals for 30 days and today, and the limits | #7 | sonnet-5.5 medium | 10 | $0.18 | success | pass | merged as-is | |
| 2026-10-17 | silviana | #3 Usage page: a bar chart of daily spend, stacked by repo | #8 | sonnet-5.5 medium | 8 | $0.15 | success | block | | |
| 2026-10-17 | silviana | #3 revision (auto) | #8 | sonnet-5.5 medium | 9 | $0.12 | success | pass | merged as-is | |
| 2026-10-17 | silviana | #4 Usage: reviewer and draft costs from the journal | #9 | sonnet-5.5 medium | 18 | $0.54 | success | pass | merged as-is | |
| 2026-10-17 | silviana | #5 Usage: this month's GitHub Actions minutes on private repos | #11 | sonnet-5.5 medium | 19 | $0.47 | success | pass | merged as-is | |
| 2026-10-18 | backroadtrips | #3 Example days are labeled "Dates flexible" | #14 | sonnet-5.5 medium | 7 | $0.13 | success | pass | merged as-is | |
| 2026-10-18 | backroadtrips | #4 Base town starts prefilled with Albany, NY | #15 | sonnet-5.5 medium | 12 | $0.15 | success | pass | | |
