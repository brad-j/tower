# silviana, the web console for tower: TanStack Start on Node 22, pnpm, Playwright with Chromium. Its tests run against
# fakes of systemd, the journal, /proc and GitHub, so they need no sibling and never touch tower. Sourced by
# lib/tower.sh, which says what each setting means and what the ones not set here default to.

repo=brad-j/silviana
clone=$HOME/novices/silviana
state=$HOME/novices/state/silviana
check="pnpm check && pnpm e2e"

# Who can use the console (the server, the request guard and the LAN and tailnet check), what it starts in systemd and
# how (actions, systemd), the agent's GitHub token and the read-only GitHub client, novice's lock, where each source
# is, and the fakes that keep the tests off the real machine.
safety_paths=(server.ts src/start.ts src/server/guard.ts src/server/actions.ts src/server/github.ts src/server/systemd.ts
	src/server/locks.ts src/server/config.ts e2e/fake-bin/ systemd/)

flagged_paths+=(vite.config.ts playwright.config.ts tsconfig.json .oxlintrc.json)
# Docs and styles.
unprovable='(\.md$|\.css$)'
# The router's generated route tree.
uncounted+=(src/routeTree.gen.ts)

# Private: rulesets on it need GitHub Pro.
public=0

vouched=0
automerge=1
