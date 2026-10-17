# gaidin, the agent runtime: Node 22, pnpm, bubblewrap and Chromium in its tests. Sourced by lib/tower.sh.

repo=brad-j/gaidin
# The agents' clone: HTTPS remote, a credential helper that reads only the agent's token, user brads-agents, a pre-push
# hook refusing main.
clone=$HOME/novices/gaidin
state=$HOME/novices/state/gaidin

# Run inside the sandbox before each worker run, since package.json may be the agent's.
setup=(pnpm install --frozen-lockfile)
# What the worker is told must pass before it commits. CI runs the same.
check="pnpm check"

# Worker tools. bin/novice adds its own deny list (push, gh, remote, config, curl) on top.
allowed=(Read Edit Write Glob Grep "Bash(pnpm *)" "Bash(node *)" "Bash(git status*)" "Bash(git diff*)" "Bash(git add *)"
	"Bash(git commit *)" "Bash(git log*)" "Bash(git show*)" "Bash(ls *)" "Bash(cat *)" "Bash(grep *)" "Bash(mktemp *)" "Bash(rm -rf /tmp/*)")

# Mounted read-only in the sandbox, besides Node and the clone: pnpm's store and Playwright's browsers.
sandbox_ro=("$HOME/.local/share/pnpm/store" "$HOME/.cache/ms-playwright")

# Files that steer CI, agents or dependencies (an extended regex over the diff's file names). A PR touching them, or the
# safety code, gets a warning at the top and the needs-brad label.
flagged='^(\.github/|AGENTS\.md|CLAUDE\.md|package\.json|pnpm-lock\.yaml|pnpm-workspace\.yaml)'

# Safety code, as paths or path prefixes. The reviewer blocks a change here that lets more through unless the issue
# asked for it. Agents aren't given issues here until the log earns it.
safety_paths=(src/sandbox.ts src/guards.ts src/approvals.ts src/rules.ts src/redact.ts src/fetch.ts src/workspaces.ts
	src/browser/ src/self/ src/connectors/)

# Files whose claims a test can't prove (an extended regex): docs. A PR touching them gets the needs-brad label.
unprovable='(\.md$|^docs/)'

# Left out of the line count for the size limit.
uncounted=(pnpm-lock.yaml)

# Public repositories get the reviewer's check for host names, addresses, people, home paths and secrets.
public=1
