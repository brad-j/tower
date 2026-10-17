# moiraine, the app for gaidin: TanStack Start in SPA mode, Node 22, pnpm, Playwright with Chromium. It depends on
# gaidin through link:../gaidin, and its tests start gaidin's e2e server from there. Sourced by lib/tower.sh.

repo=brad-j/moiraine
# The agents' clone, set up by tower add-repo, with gaidin's main beside it.
clone=$HOME/novices/moiraine/moiraine
state=$HOME/novices/state/moiraine
# Repositories (OWNER/NAME) checked out beside the clone at their main, refreshed before each run, read-only to the worker.
siblings=(brad-j/gaidin)

# Run inside the sandbox before each worker run, since package.json may be the agent's. Also installs the siblings.
setup=(pnpm install --frozen-lockfile)
# What the worker is told must pass before it commits. CI runs the same.
check="pnpm check && pnpm e2e"

# Worker tools. bin/novice adds its own deny list (push, gh, remote, config, curl) on top.
allowed=(Read Edit Write Glob Grep "Bash(pnpm *)" "Bash(node *)" "Bash(git status*)" "Bash(git diff*)" "Bash(git add *)"
	"Bash(git commit *)" "Bash(git log*)" "Bash(git show*)" "Bash(ls *)" "Bash(cat *)" "Bash(grep *)" "Bash(mktemp *)" "Bash(rm -rf /tmp/*)")

# Mounted read-only in the sandbox, besides Node, the clone and the siblings: pnpm's store and Playwright's browsers.
sandbox_ro=("$HOME/.local/share/pnpm/store" "$HOME/.cache/ms-playwright")

# Files that steer CI, agents or dependencies (an extended regex over the diff's file names). A PR touching them, or the
# safety code, gets a warning at the top and the needs-brad label.
flagged='^(\.github/|AGENTS\.md|CLAUDE\.md|package\.json|pnpm-lock\.yaml|pnpm-workspace\.yaml|vite\.config\.ts|playwright\.config\.ts)'

# Safety code, as paths or path prefixes: the deploy to gaidin's VM, what the service worker and offline copies keep on
# the device, the push subscription, the one boundary with gaidin's API, and the rendering of model output. The reviewer
# blocks a change here that lets more through unless the issue asked for it. Agents aren't given issues here until the
# log earns it.
safety_paths=(scripts/ship.ts public/sw.js src/offline.ts src/push.ts src/api.ts src/markdown.tsx)

# Files whose claims or look a test can't prove (an extended regex): docs, the design system and styles. A PR touching
# them gets the needs-brad label.
unprovable='(\.md$|\.css$)'

# Left out of the line count for the size limit: the lockfile and the router's generated route tree.
uncounted=(pnpm-lock.yaml src/routeTree.gen.ts)

# Public repositories get the reviewer's check for host names, addresses, people, home paths and secrets.
public=1

# Brad sets this to 1 to vouch for the agent here, once log.md shows about 10 merged PRs with nothing found after merge.
# It only changes the agent's PRs from vouch:unvouched to vouch:trusted; every check and label still applies.
vouched=0
