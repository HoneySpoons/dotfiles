# dotfiles

Personal terminal/editor configuration, version-controlled for portability across machines.

## Files

- `PowerShell_profile.ps1` — the real PowerShell profile, sourced from `$PROFILE` on every PowerShell 7+ startup.

## What's in the profile (v1)

- **PSReadLine** — inline history-based predictions (gray ghost text, right-arrow to accept) plus ListView dropdown for matching history.
- **Vault navigation** — `eva` cd's to `C:\Vaults\EVA`, `wiki` to `C:\Vaults\EVA\wiki`, `vlog` opens `wiki/log.md` in VS Code.
- **Code workspace navigation** — `cdcode` cd's to `C:\Users\andre\code`. (Note: `code` itself is the VS Code launcher and isn't shadowed.)
- **Git shortcuts** — `gs` (status), `gd` (diff), `ga` (add), `gcommit`, `gpush`, `gpull`, `glog` (last 20 commits, oneline graph).
- **posh-git** — git-aware prompt: shows current branch + dirty/staged/ahead-behind indicators when inside a git repo.

## Setup on a new machine

1. Install PowerShell 7+:
   ```powershell
   winget install Microsoft.PowerShell
   ```
2. Clone this repo to `~/dotfiles` (`C:\Users\<you>\dotfiles` on Windows):
   ```powershell
   git clone https://github.com/HoneySpoons/dotfiles.git "$HOME\dotfiles"
   ```
3. Install posh-git:
   ```powershell
   Install-Module posh-git -Scope CurrentUser
   ```
4. Wire up `$PROFILE` to dot-source the real profile:
   ```powershell
   New-Item -ItemType File -Path $PROFILE -Force
   Set-Content -Path $PROFILE -Value '. "$HOME\dotfiles\PowerShell_profile.ps1"'
   ```
5. Open a new PowerShell session — aliases and prompt should be active.

## Naming choices

PowerShell ships with a lot of two-letter `g`-prefixed aliases for `Get-*` cmdlets (`gc` = Get-Content, `gl` = Get-Location, `gp` = Get-ItemProperty, etc.). The git shortcuts in this profile deliberately avoid those collisions:

- `gs` / `gd` / `ga` — safe, no defaults to override
- `gcommit` / `gpush` / `gpull` / `glog` — spelled out instead of the short `gc` / `gp` / `gl` to keep the built-ins working

Long term, the cleaner home for these is git's own subcommand alias config (`git config --global alias.st status` etc.) — likely a future refactor.
