# backroadtrips, a motorcycle getaway planner: TanStack Start on Netlify, Node 22, pnpm, Vitest, and Playwright in
# Chromium and Firefox (WebKit can't launch on egwene, so the check leaves it out). Its tests need no keys: the service
# checks run against mocks and the browser tests start their own dev server on 127.0.0.1:3100. ../bdaytrip is a
# product reference, not a sibling. Sourced by lib/tower.sh, which says what each setting means and what the ones not
# set here default to.

repo=brad-j/backroadtrips
clone=$HOME/novices/backroadtrips
state=$HOME/novices/state/backroadtrips
check="pnpm check && pnpm e2e"

# The server functions, Identity and admin checks and the paid service calls (src/server/, src/domain/spike.ts), the
# paved-only eligibility check (src/domain/trips.ts), and the database smoke test that refuses anything but a local
# database.
safety_paths=(src/server/ src/domain/spike.ts src/domain/trips.ts scripts/check-local-database.ts)

# The checks, deployment and the database schema.
flagged_paths+=(.node-version vite.config.ts playwright.config.ts vitest.config.ts tsconfig.json .oxlintrc.json
	.prettierrc.json .prettierignore netlify.toml drizzle.config.ts db/ netlify/)
# Docs, PLAN.md, the design tokens and styles, and Hallmark's design notes.
unprovable='(\.md$|^docs/|\.css$|^\.hallmark/)'
# Generated migrations.
uncounted+=(netlify/database/migrations/)

# Private: rulesets on it need GitHub Pro.
public=0

vouched=0
automerge=1
