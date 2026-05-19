# ~/dotfiles/PowerShell_profile.ps1
#
# Sourced from $PROFILE on every PowerShell startup.
# Keep this file portable — anything machine-specific belongs in $PROFILE itself,
# not here.
#
# Repo: https://github.com/HoneySpoons/dotfiles  (update if/when this changes)

# -------------------------------------------------------------------
# Restart PowerShell
# -------------------------------------------------------------------

function restart {
    $host.SetShouldExit(1)
}

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
# DirPick — Alt+Shift+F — fuzzy-pick from cwd, insert at cursor
# -------------------------------------------------------------------
# Requires fzf (winget install junegunn.fzf)

# Set-PSReadLineKeyHandler -Key "Alt+Shift+F" `
#     -BriefDescription "DirPick" `
#     -LongDescription "Pick a file/folder from cwd and insert at cursor" `
#     -ScriptBlock {

#     $items = Get-ChildItem | ForEach-Object {
#         if ($_.PSIsContainer) { "$($_.Name)/" } else { $_.Name }
#     }

#     $selected = $items | fzf --prompt="ls> " --height=40% --layout=reverse

#     if ($selected) {
#         [Microsoft.PowerShell.PSConsoleReadLine]::Insert($selected.TrimEnd('/'))
#     }
# }

# -------------------------------------------------------------------
# General navigation
# -------------------------------------------------------------------

function docs  { Set-Location 'C:\Users\andre\Documents' }
function andre { Set-Location 'C:\Users\andre' }
function root  { Set-Location 'C:\' }
function dot   { Set-Location 'C:\Users\andre\dotfiles' }


# -------------------------------------------------------------------
# Vault navigation
# -------------------------------------------------------------------

function eva  { Set-Location 'C:\Vaults\EVA' }
function wiki { Set-Location 'C:\Vaults\EVA\wiki' }
function vlog { code 'C:\Vaults\EVA\wiki\log.md' }


# -------------------------------------------------------------------
# Vault search and navigation
# -------------------------------------------------------------------
# vsearch "term"     — full-text search across all vault markdown files
# vopen "wiki/log"   — open a specific note in Obsidian by path
# vrecent            — list the 10 most recently modified wiki notes

function vsearch {
    param([string]$query)
    Select-String -Path "C:\Vaults\EVA\**\*.md" -Pattern $query -CaseSensitive:$false |
    Select-Object Filename, LineNumber, Line
}

function vopen {
    param([string]$file)
    Start-Process "obsidian://open?vault=EVA&file=$([uri]::EscapeDataString($file))"
}

function vrecent {
    param([int]$n = 10)
    Get-ChildItem "C:\Vaults\EVA\wiki" -Recurse -Filter "*.md" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First $n Name, LastWriteTime
}

# -------------------------------------------------------------------
# Code workspace navigation and sync
# -------------------------------------------------------------------
# Note: `code` itself is the VS Code CLI (e.g. `code .` to open the
# current directory in VS Code). Don't shadow it with a function.

function cdcode    { Set-Location 'C:\Users\andre\code' }

function changelog { Set-Location 'C:\Users\andre\code\changelog-app' }

function prev { Set-Location 'C:\Users\andre\code\previous-coding-adventures' }

function handoff { Set-Location 'C:\Vaults\EVA\claude-sync' }

function returns { Set-Location 'C:\Users\andre\code\claude-sync' }

function csync {
    # Agent roots — single source of truth. Update if paths change (e.g. C:\Vaults → C:\agents).
    $EVA_ROOT = "C:\Vaults\EVA"
    $CLI_ROOT = "C:\Users\andre\code"
    $AUD_ROOT = "C:\Vaults\AUD"

    # Walk up from $PWD looking for a CLAUDE.md — that marks an agent root.
    $current = (Get-Location).Path
    $agentRoot = $null
    while ($current -and ($current -ne (Split-Path $current -Parent))) {
        if (Test-Path (Join-Path $current "CLAUDE.md")) {
            $agentRoot = $current
            break
        }
        $current = Split-Path $current -Parent
    }

    if (-not $agentRoot) {
        Write-Host "csync: not in a valid agent directory (no CLAUDE.md found walking up from $PWD)" -ForegroundColor Red
        return
    }

    # Normalize for comparison
    $agentRoot = $agentRoot.TrimEnd('\')

    switch ($agentRoot) {
        $EVA_ROOT {
            Write-Host "csync: EVA -> CLI" -ForegroundColor Cyan
            $src = Join-Path $EVA_ROOT "claude-sync\*"
            $dst = Join-Path $CLI_ROOT "claude-sync\"
            if (-not (Test-Path $dst)) { New-Item -ItemType Directory -Path $dst | Out-Null }
            Copy-Item -Path $src -Destination $dst -Recurse -Force
            Write-Host "  pushed $src to $dst" -ForegroundColor Green
        }
        $CLI_ROOT {
            Write-Host "csync: CLI -> EVA" -ForegroundColor Cyan
            $src = Join-Path $CLI_ROOT "claude-sync\*"
            $dst = Join-Path $EVA_ROOT "claude-sync\"
            if (-not (Test-Path $dst)) { New-Item -ItemType Directory -Path $dst | Out-Null }
            Copy-Item -Path $src -Destination $dst -Recurse -Force
            Write-Host "  pushed $src to $dst" -ForegroundColor Green
        }
        $AUD_ROOT {
            Write-Host "csync: AUD -> EVA + CLI" -ForegroundColor Cyan
            $src = Join-Path $AUD_ROOT "claude-sync\audit-returns\*"
            $dstEva = Join-Path $EVA_ROOT "aud\findings\"
            $dstCli = Join-Path $CLI_ROOT "aud\findings\"
            if (-not (Test-Path $dstEva)) { New-Item -ItemType Directory -Path $dstEva -Force | Out-Null }
            if (-not (Test-Path $dstCli)) { New-Item -ItemType Directory -Path $dstCli -Force | Out-Null }
            Copy-Item -Path $src -Destination $dstEva -Recurse -Force
            Copy-Item -Path $src -Destination $dstCli -Recurse -Force
            Write-Host "  pushed $src to $dstEva" -ForegroundColor Green
            Write-Host "  pushed $src to $dstCli" -ForegroundColor Green
        }
        default {
            Write-Host "csync: not in a valid agent directory (resolved root: $agentRoot)" -ForegroundColor Red
            Write-Host "  expected one of: $EVA_ROOT, $CLI_ROOT, $AUD_ROOT" -ForegroundColor Yellow
        }
    }
}


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

# -------------------------------------------------------------------
# Package Management
# -------------------------------------------------------------------
# Finds packages in the current environment.

function find-package {
    param([string]$name)
    Write-Host "--- winget ---"
    winget list | findstr -i $name
    Write-Host "--- python (pip) ---"
    pip show $name 2>$null
    Write-Host "--- uv ---"
    uv pip show $name 2>$null
    Write-Host "--- npm global ---"
    npm list -g --depth=0 2>$null | findstr -i $name
    Write-Host "--- command path ---"
    where.exe $name 2>$null
}


