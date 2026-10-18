# silviana, the web console for tower: TanStack Start on Node 22, pnpm, Playwright with Chromium. Its tests run against
# fakes of systemd, the journal, /proc and GitHub, so they need no sibling and never touch tower. Sourced by lib/tower.sh.

repo=brad-j/silviana
# The agents' clone: HTTPS remote, a credential helper that reads only the agent's token, user brads-agents, a pre-push
# hook refusing main.
clone=$HOME/novices/silviana
state=$HOME/novices/state/silviana
# Repositories (OWNER/NAME) checked out beside the clone at their main, refreshed before each run, read-only to the worker.
siblings=()

# Run inside the sandbox before each worker run, since package.json may be the agent's.
setup=(pnpm install --frozen-lockfile)
# What the worker is told must pass before it commits. CI runs the same.
check="pnpm check && pnpm e2e"

# Worker tools. bin/novice adds its own deny list (push, gh, remote, config, curl) on top.
allowed=(Read Edit Write Glob Grep "Bash(pnpm *)" "Bash(node *)" "Bash(git status*)" "Bash(git diff*)" "Bash(git add *)"
	"Bash(git commit *)" "Bash(git log*)" "Bash(git show*)" "Bash(ls *)" "Bash(cat *)" "Bash(grep *)" "Bash(mktemp *)" "Bash(rm -rf /tmp/*)")

# Mounted read-only in the sandbox, besides Node and the clone: pnpm's store and Playwright's browsers.
sandbox_ro=("$HOME/.local/share/pnpm/store" "$HOME/.cache/ms-playwright")

# Files that steer CI, agents, dependencies or the checks (an extended regex over the diff's file names). A PR touching
# them, or the safety code, gets a warning at the top and the needs-brad label.
flagged='^(\.github/|AGENTS\.md|CLAUDE\.md|package\.json|pnpm-lock\.yaml|pnpm-workspace\.yaml|vite\.config\.ts|playwright\.config\.ts|tsconfig\.json|\.oxlintrc\.json)'

# Safety code, as paths or path prefixes: who can use the console (the server, the request guard and the LAN and
# tailnet check), what it starts in systemd and how (actions, systemd), the agent's GitHub token and the read-only
# GitHub client, novice's lock, where each source is, and the fakes that keep the tests off the real machine. The
# reviewer blocks a change here that lets more through unless the issue asked for it. Agents aren't given issues here
# until the log earns it.
safety_paths=(server.ts src/start.ts src/server/guard.ts src/server/actions.ts src/server/github.ts src/server/systemd.ts
	src/server/locks.ts src/server/config.ts e2e/fake-bin/ systemd/)

# Files whose claims or look a test can't prove (an extended regex): docs and styles. A PR touching them gets the
# needs-brad label.
unprovable='(\.md$|\.css$)'

# Left out of the line count for the size limit: the lockfile and the router's generated route tree.
uncounted=(pnpm-lock.yaml src/routeTree.gen.ts)

# Public repositories get the reviewer's check for host names, addresses, people, home paths and secrets. silviana is
# private (rulesets on it need GitHub Pro).
public=0

# Brad sets this to 1 to vouch for the agent here, once log.md shows about 10 merged PRs with nothing found after merge.
# It only changes the agent's PRs from vouch:unvouched to vouch:trusted; every check and label still applies.
vouched=0
