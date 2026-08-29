# linux — Omarchy setup for `strogatz` (and the Legion, eventually)

Everything needed to rebuild this Omarchy machine's *configuration* on new hardware.
Written 2026-08-29, when the honest state of things was: **none of it existed anywhere
but one disk**, guarded by btrfs snapshots that live on that same disk.

## Restore

```bash
# after a stock Omarchy install
git clone https://github.com/HoneySpoons/dotfiles ~/Projects/dotfiles
cd ~/Projects/dotfiles && ./linux/install.sh      # DRY_RUN=1 to preview
```

## The governing rule: record the source, don't vendor the artifact

Three things are deliberately **not** stored here, and the reason is the same each time —
**one source of truth**:

| not stored | why | what is stored instead |
|---|---|---|
| `~/.config/omarchy/themes/` (111 MB) | they are git clones of somebody else's repos | `themes.txt` — the clone URLs |
| the `~/.local/bin` AI-CLI shims | **generated** by `mise use -g`, not written by hand | `config/mise-config.toml` — the tool list they come from |
| `omarchy-localsend`, `omarchy-web-search` | each already has its own repo | `plugins.txt` / `tools.txt` — install by URL |

Vendoring any of them would create a second copy that drifts from the first. That failure
has a name in this vault and it has been paid for more than once.

## What is here

```
packages.txt        174 explicit packages. ZERO from the AUR, so a plain
                    `pacman -S --needed` restores all of it.
config/hypr/        autostart · bindings · hyprland · input · looknfeel · monitors
                    · hyprsunset · xdph      (the .bak files are not carried)
config/omarchy/     shell.json (the bar), branding/about + screensaver,
                    defaults/agent, extensions/omarchy-menu.jsonc
config/mise-config.toml   claude · codex · gh · node · ruby
bin/                mic-killswitch · syncthing-watch · upower-sanity
                    — the three scripts actually written here
themes.txt / plugins.txt / tools.txt      pointers, per the rule above
install.sh          idempotent; backs up anything it would overwrite
```

Most of `~/.config/omarchy/hooks/` and `themed/` are untouched stock `.sample` files and
are not carried — if one is ever edited, it belongs here.

## ⚠️ What this does NOT restore, on purpose

**Credentials.** A dotfiles repo is the wrong place for them and this one stays clean —
it was audited for key material before the first commit and had none.

- `gh auth login`
- `tailscale up` — **the same Google account**, or you create a second, invisible tailnet
- Syncthing device pairing, and folder paths — ⚠️ **type paths explicitly.** Accepting the
  offered default once pointed a shared folder at an entire Windows user profile.
- `monitors.lua` is hardware-specific and will need editing on different hardware.

## Known state at time of capture

- `~/.config/omarchy/themes/aether` is an **empty directory with no git remote** — a failed
  or abandoned theme install. Not carried into `themes.txt`; delete it or reinstall it.
- `/usr/share/omarchy/version` reads `4.0.0.alpha` while pacman reports `4.0.1-1`.
  Unexplained; possibly a stale version file upstream.
