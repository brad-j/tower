# gaidin, the agent runtime: Node 22, pnpm, bubblewrap and Chromium in its tests. Sourced by lib/tower.sh, which says
# what each setting means and what the ones not set here default to.

repo=brad-j/gaidin
clone=$HOME/novices/gaidin
state=$HOME/novices/state/gaidin
check="pnpm check"

safety_paths=(src/sandbox.ts src/guards.ts src/approvals.ts src/rules.ts src/redact.ts src/fetch.ts src/workspaces.ts
	src/browser/ src/self/ src/connectors/)

vouched=0
automerge=1
