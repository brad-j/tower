# Setting up tower

How to get tower running on a Linux machine, as it runs on egwene (CachyOS). After this, adding a repository is `PLAYBOOK.md`. Commands are for fish; the scripts themselves are bash.

## What runs where

- On the host, as Brad's user: `bin/novice`, `bin/review-pr` and `bin/tower`. They run git and gh, and push.
- In `bin/sandbox` (bubblewrap): each repository's install and check, and the worker. The sandbox sees an empty home, Node from `~/.local/share/pi-node/current`, `/usr` and `/etc` read-only, the repository's clone, and whatever the repository's `sandbox_ro` and `siblings` add.
- The worker is the Claude Code inside the sandbox, from pi-node, logged in with its own long-lived token. The reviewer is the host's Claude Code (`~/.local/bin/claude`) with Brad's own Claude login, run with no tools in an empty directory. On egwene these are two installs and can be different versions (2.1.288 and 2.1.302 as of 2026-10-17).

## 1. Packages

On Arch or CachyOS:

```fish
sudo pacman -S --needed bubblewrap git github-cli jq util-linux coreutils pnpm
```

- bubblewrap has to work unprivileged and nested, since gaidin's own tests start a sandbox inside tower's. CachyOS allows this by default. Ubuntu 24.04 confines unprivileged user namespaces, and needs `sysctl kernel.apparmor_restrict_unprivileged_userns=0` or an AppArmor profile.
- pnpm comes from the system (`/usr/bin/pnpm`). Its store is `~/.local/share/pnpm/store`, which repositories mount read-only.

## 2. Node and the worker's Claude Code

`bin/sandbox` puts `~/.local/share/pi-node/current/bin` first on the sandbox's PATH, so Node 22 and the worker's Claude Code must be there.

- `~/.local/share/pi-node/current` is a symlink to an unpacked Node 22 release (`node-v22.23.2-linux-x64` on egwene).
- Install Claude Code into it: `~/.local/share/pi-node/current/bin/npm install -g @anthropic-ai/claude-code`. Update it the same way.
- The reviewer uses the host's `claude`, which has to be logged in as Brad (`claude`, then `/login`).

## 3. Browsers for the tests

Repositories with browser tests need Chromium's headless shell in `~/.cache/ms-playwright`, installed from each repository's own Playwright version:

```fish
cd ~/novices/gaidin; pnpm exec playwright-core install --only-shell chromium
cd ~/novices/moiraine/moiraine; pnpm exec playwright install --only-shell chromium
```

On egwene the system libraries Chromium needs are already there. Elsewhere, add `--with-deps` on Debian or Ubuntu, or install them with the package manager.

## 4. The agent's GitHub account

Agents act as `brads-agents` (agents@half.black), never as Brad.

1. The account exists already. On a new machine, skip to the login.
2. Log it in with its own gh config directory. Use `$HOME`, not `~`: fish expands `~` only at the start of a word.

   ```fish
   mkdir -p $HOME/.config/gh-agents; chmod 700 $HOME/.config/gh-agents
   env GH_CONFIG_DIR=$HOME/.config/gh-agents GH_BROWSER=echo gh auth login --hostname github.com --git-protocol https --web
   ```

   - Don't let it open your browser, which is signed in as brad-j and would mint a brad-j token. `GH_BROWSER=echo` prints the URL instead. Press Enter at "Press Enter to open...", then open github.com/login/device in a private window signed in as brads-agents and enter the code.
   - Answer **No** to "Authenticate Git with your GitHub credentials?". Yes adds credential helpers to `~/.gitconfig`; remove them if it happens. `~/.gitconfig` holds only Brad's name, email and default branch.
3. Save its token where the scripts read it:

   ```fish
   env GH_CONFIG_DIR=$HOME/.config/gh-agents gh auth token > $HOME/.config/gh-agents/token
   chmod 600 $HOME/.config/gh-agents/token
   ```

   The token has the scopes gh asks for: gist, read:org, repo, workflow.
4. Check it: `env GH_TOKEN=(cat $HOME/.config/gh-agents/token) gh api user -q .login` prints `brads-agents`.

Every script sets `GH_TOKEN` from that file. Without it, gh falls back to Brad's keyring login.

## 5. The worker's Claude token

```fish
claude setup-token
mkdir -p $HOME/.config/novices; chmod 700 $HOME/.config/novices
read -s -P "token: " t; printf '%s' $t > $HOME/.config/novices/claude-token; set -e t
chmod 600 $HOME/.config/novices/claude-token
```

`setup-token` makes a long-lived token on Brad's Claude subscription. bin/novice passes it into the sandbox only as `CLAUDE_CODE_OAUTH_TOKEN` in the environment, never on a command line. Never paste it into a chat.

## 6. Brad's own gh login

`bin/tower add-repo` changes repository settings, which needs an admin, so it uses Brad's gh login from the keyring:

```fish
gh auth login --hostname github.com --git-protocol ssh --web
```

Skip the SSH key upload, and answer No to "Authenticate Git with your GitHub credentials?". bin/novice and bin/review-pr never use this login.

## 7. tower and its working area

```fish
git clone git@github.com:brad-j/tower.git ~/westwood/Projects/Software/tower
mkdir -p ~/novices
```

The scripts find `lib/` and `log.md` relative to themselves, so tower can live anywhere. The agents' clones and loop state live under `~/novices`, as each `repos/NAME.sh` says, and `tower add-repo NAME --apply` creates them.

## 8. Check it works

```fish
cd ~/westwood/Projects/Software/tower
bin/tower add-repo gaidin            # every line ok, or a short list of what it would change
bin/tower add-repo gaidin --apply    # also runs the check in the sandbox
bin/novice gaidin --dry-run          # says what the loop would do next
```

## 9. The timer

A systemd user timer runs `bin/novice NAME` for each repository every 15 minutes, so the loop picks up after Brad approves, merges or requests changes. The units are in `systemd/`; `tower@.service` names tower's path, so update it if tower moves.

```fish
systemctl --user link ~/westwood/Projects/Software/tower/systemd/tower@.service ~/westwood/Projects/Software/tower/systemd/tower@.timer
systemctl --user enable --now tower@gaidin.timer tower@moiraine.timer
loginctl enable-linger $USER    # keeps them running while logged out; already on for egwene
```

## Running

- The timers start `bin/novice NAME` every 15 minutes. Running it by hand still works: while one run is going, another on the same repository exits at once (the lock is `~/novices/state/NAME/lock`), and a run that's still going isn't started again.
- What it did: `journalctl --user -u tower@NAME -e`. When it's next due: `systemctl --user list-timers 'tower@*'`.
- Pause a repository: `systemctl --user stop tower@NAME.timer` (until the next login or reboot) or `disable --now` (until it's enabled again).
- A new repository's timer: `systemctl --user enable --now tower@NAME.timer`, after its first run by hand.
- Limits, in `bin/novice` and `bin/review-pr`: 10 worker runs a day per repository, Sonnet 5.5 at medium effort, $3 and 30 minutes per worker run, $0.75 and 10 minutes per review, one agent PR open at a time, diffs up to 300 lines.

## Where things are kept

| What | Where |
|---|---|
| tower | `~/westwood/Projects/Software/tower` (github.com/brad-j/tower) |
| Agents' clones | `~/novices/NAME`, or `~/novices/NAME/NAME` with siblings beside it |
| Loop state | `~/novices/state/NAME/` |
| Issue drafts | `~/novices/issues.md` |
| Agent's GitHub login and token | `~/.config/gh-agents/` (`token`, mode 600) |
| Worker's Claude token | `~/.config/novices/claude-token` (mode 600) |
| Run log | `log.md` in tower |

## Replacing a token

- Agent's GitHub token: revoke it while signed in as brads-agents (Settings, Applications, GitHub CLI), then redo step 4.
- Worker's Claude token: redo step 5. The old one stays valid until it's revoked in Claude's settings.
- Brad's gh login: revoking GitHub CLI at github.com/settings/applications signs it out. Redo step 6.
