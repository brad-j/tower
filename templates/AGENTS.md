# NAME

One or two sentences: what this is, and what it works with (sibling repositories, services). Say if the repository is public.

## Commands

- `pnpm install`, then `pnpm check` before every commit: what it runs (type check, lint, tests). Open a PR only with it passing.
- One test file while working: the exact command.
- How to run it locally without keys or network, if there's a way.
- Tests never need a key or the network. If some skip themselves when a tool is missing, say so: CI fails on any skipped test, so treat a skip as a broken setup.

## Where things are

- Where decisions and plans live, and that they're read before starting.
- The layout an agent needs to find its way: source, tests, docs, generated files not to edit.
- Docs that describe behavior are updated in the same change as the behavior.

## Rules

- Lint rules are satisfied by changing the code, not by turning them off.
- The safety code is LIST (the same as safety_paths in tower's repos/NAME.sh). A change that lets through anything it used to stop says so in the PR description and has a test. Never weaken or delete a test of it to make a change pass.
- Dependencies are added or upgraded deliberately. Don't do it as part of a task; say in the PR that one is needed.
- For a public repository: nothing about the owner's own setup in code, tests or docs (real names, host names, addresses, IDs, home paths). Use `example.com`, `*.test` and `192.0.2.x`.
- Commit messages describe the change in a sentence or more of prose, with no `feat:`-style prefixes.

## Working through GitHub

- Work on a branch per issue, and put `Closes #N` in the PR description. Never push to main, and leave merging to Brad.
- The PR description says what changed, how you checked it, and anything you weren't sure of.

## Mistakes agents have made

Add a line here each time an agent gets something wrong that a line here would have prevented.
