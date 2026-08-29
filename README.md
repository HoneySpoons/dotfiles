# dotfiles

Personal terminal/editor configuration, version-controlled for portability across machines.

## Files

- `PowerShell_profile.ps1` — the real PowerShell profile, sourced from `$PROFILE` on every PowerShell 7+ startup.

## What's in the profile

### Roots

All paths derive from one table at the top of the file:

```powershell
$Vaults = 'C:\Vaults'
$Agents = @{ EVA = "$Vaults\EVA"; CLI = "$Vaults\CLI"; AUD = "$Vaults\AUD"; DES = "$Vaults\DES" }
```

Moving the vaults is a one-line change. Both are left in the session as globals, so `$Agents.DES` works at the prompt too.

### Navigation

| Verb | Goes to |
|---|---|
| `eva` / `wiki` / `vlog` | EVA root · `wiki/` · opens `wiki/log.md` |
| `aud` / `alog` | AUD root · opens `audit-log.md` |
| `des` / `dlog` / `comps` | DES root · opens `log.md` · `DES/comps/` |
| `comp [match]` | **opens the newest `.dc.html` comp in the browser** (substring-filtered) |
| `cdcode` / `changelog` / `kuramoto` / `prev` | CLI root and its projects |
| `handoff` / `returns` | EVA-side claude-sync (canonical) · CLI-side (mirror) |
| `docs` / `andre` / `root` / `dot` | Documents · home · `C:\` · this repo |

`cli` is deliberately **not** defined — see Naming below.

### Vault search

| Command | Does |
|---|---|
| `vsearch "term"` | recursive full-text search of EVA's markdown; `-Agent EVA\|CLI\|AUD\|DES\|All`, `-Regex` |
| `vrecent [-n 10]` | most recently modified notes; same `-Agent` switch |
| `vopen "wiki/log"` | opens a note in Obsidian by vault-relative path |

`vsearch` prints a match/file/searched count so a zero result is distinguishable from a broken search.

### csync — the handoff sync layer

| Command | Does |
|---|---|
| `csync` | syncs based on which agent root you're standing in (walks up for a `CLAUDE.md`) |
| `csync status` | **read-only** drift report across all flows, from anywhere |
| `csync all` | runs every flow regardless of cwd |

Four directed flows: `EVA→CLI`, `CLI→EVA`, `AUD→EVA`, `AUD→CLI`. Copies are **content-addressed** — a file moves only when missing at the destination or differing by length/hash. mtime is ignored, so a touched-but-identical file isn't drift. Per-flow `Skip` lists let each destination keep its own `README.md`.

**DES is a route, not a flow.** DES has no `claude-sync/` of its own; per its `CLAUDE.md` it writes handoffs and returns straight into EVA's canonical folder. So standing in the DES root runs `EVA → CLI`, which is what carries DES's output across.

### DirPick — `Alt+Shift+F`

Fuzzy-pick a file/folder from cwd via fzf, insert at cursor. No-ops with a message if fzf is missing rather than throwing mid-keystroke. Requires `winget install junegunn.fzf`.

### Git, prompt, packages

`gs` / `gd` / `ga` / `gcommit` / `gpush` / `gpull` / `glog`; posh-git for a branch-aware prompt; `pkg <name>` to find which package manager installed something.

## Setup on a new machine

1. Install PowerShell 7+: `winget install Microsoft.PowerShell`
2. Clone to `~/dotfiles`: `git clone https://github.com/HoneySpoons/dotfiles.git "$HOME\dotfiles"`
3. `Install-Module posh-git -Scope CurrentUser`
4. `winget install junegunn.fzf` (optional — only DirPick needs it)
5. Wire up `$PROFILE`:
   ```powershell
   New-Item -ItemType File -Path $PROFILE -Force
   Set-Content -Path $PROFILE -Value '. "$HOME\dotfiles\PowerShell_profile.ps1"'
   ```

## Naming

PowerShell resolves commands **Alias → Function → Cmdlet → Application**. Two consequences this profile respects:

- **A function can't override a built-in alias.** `cli` ships as an alias for `Clear-Item`, so `function cli { ... }` is dead code that never runs. Use `cdcode`. (This profile carried such a function from 2026-05 to 2026-08 without it ever executing once.)
- **A function *does* override a cmdlet.** `function find-package` silently shadowed the real `Find-Package` cmdlet; it's now `pkg`.

The git shortcuts avoid the built-in `g`-prefixed aliases (`gc` = Get-Content, `gl` = Get-Location, `gp` = Get-ItemProperty) by spelling out `gcommit` / `gpull` / `glog`. Long term, git's own alias config is a cleaner home for these.

## Known issues / history

- **fzf + Defender.** In 2026-05, Defender quarantined `fzf.exe` on first execution — a recurring generic false-positive against unsigned Go TUI binaries, not specific to this machine. Commit `b76e675` attributed it to a BIOS update; that was wrong (Smart App Control reads `0`/off). **Resolved 2026-08-07:** fzf 0.74.2 installs, executes, and survives. If it recurs, the fix is `Add-MpPreference -ExclusionPath` on the winget package dir (needs elevation).
- **pwsh 7.6 native-redirect regression.** 7.6.1 broke piping into native commands, which would have broken DirPick's `$items | fzf` even with a working binary. Gone as of 7.6.4 — verified with a round-trip. The `cmd /c` workaround once spec'd for this is no longer needed.
- **posh-git costs ~600ms** of the ~825ms profile load. Lazy-loading it is the fix if startup ever becomes annoying.

---

## Layout

This repo now covers both halves of a dual-boot life:

- **`PowerShell_profile.ps1`** (repo root) — the Windows side: path roots, navigation verbs, shell hardening for the four-agent setup.
- **[`linux/`](linux/)** — the Omarchy side: Hyprland config, the bar, packages, and a one-command restore. See [`linux/README.md`](linux/README.md).
