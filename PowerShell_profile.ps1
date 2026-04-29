# ~/dotfiles/PowerShell_profile.ps1
#
# Sourced from $PROFILE on every PowerShell startup.
# Keep this file portable — anything machine-specific belongs in $PROFILE itself,
# not here.
#
# Repo: https://github.com/HoneySpoons/dotfiles  (update if/when this changes)

# -------------------------------------------------------------------
# PSReadLine — better history + inline predictions
# -------------------------------------------------------------------
# As you type, PSReadLine shows a gray ghosted suggestion based on
# your history. Right-arrow (or End) accepts it. F2 toggles between
# inline view and ListView (a dropdown of matching history items).

Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows


# -------------------------------------------------------------------
# Vault navigation
# -------------------------------------------------------------------

function eva  { Set-Location 'C:\Vaults\EVA' }
function wiki { Set-Location 'C:\Vaults\EVA\wiki' }
function vlog { code 'C:\Vaults\EVA\wiki\log.md' }


# -------------------------------------------------------------------
# Code workspace navigation
# -------------------------------------------------------------------
# Note: `code` itself is the VS Code CLI (e.g. `code .` to open the
# current directory in VS Code). Don't shadow it with a function.

function cdcode { Set-Location 'C:\Users\andre\code' }


# -------------------------------------------------------------------
# Git shortcuts
# -------------------------------------------------------------------
# Notes on naming:
#   gs / gd / ga       — safe, no default PowerShell aliases collide
#   gcommit / gpush /
#   gpull / glog       — spelled out to avoid colliding with PowerShell
#                        defaults (gc=Get-Content, gp=Get-ItemProperty,
#                        gl=Get-Location). Long-term, git's own alias
#                        config (`git config --global alias.st status`)
#                        is a cleaner home for these — we can move them
#                        out of here later.

function gs       { git status @args }
function gd       { git diff @args }
function ga       { git add @args }
function gcommit  { git commit @args }
function gpush    { git push @args }
function gpull    { git pull @args }
function glog     { git log --oneline --graph --decorate -20 @args }


# -------------------------------------------------------------------
# posh-git — git-aware prompt
# -------------------------------------------------------------------
# Adds current branch + dirty/staged/ahead-behind indicators to the
# prompt automatically when you cd into a git repo.

Import-Module posh-git -ErrorAction SilentlyContinue 

