# moiraine, the app for gaidin: TanStack Start in SPA mode, Node 22, pnpm, Playwright with Chromium. It depends on
# gaidin through link:../gaidin, and its tests start gaidin's e2e server from there. Sourced by lib/tower.sh, which says
# what each setting means and what the ones not set here default to.

repo=brad-j/moiraine
clone=$HOME/novices/moiraine/moiraine
state=$HOME/novices/state/moiraine
siblings=(brad-j/gaidin)
check="pnpm check && pnpm e2e"
allowed+=("Bash(taskset *)")

# The deploy to gaidin's VM, what the service worker and offline copies keep on the device, the push subscription, the
# one boundary with gaidin's API, and the rendering of model output.
safety_paths=(scripts/ship.ts public/sw.js src/offline.ts src/push.ts src/api.ts src/markdown.tsx)

flagged_paths+=(vite.config.ts playwright.config.ts)
# Docs, the design system and styles.
unprovable='(\.md$|\.css$)'
# The router's generated route tree.
uncounted+=(src/routeTree.gen.ts)

vouched=0
automerge=0
