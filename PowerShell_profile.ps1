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

# EVA 
function eva  { Set-Location 'C:\Vaults\EVA' }
function wiki { Set-Location 'C:\Vaults\EVA\wiki' }
function vlog { code 'C:\Vaults\EVA\wiki\log.md' }

# AUD
function aud { Set-Location 'C:\Vaults\AUD' }
function alog { code 'C:\Vaults\AUD\audit-log.md' }

# CLI
function cli { Set-Location 'C:\Users\andre\code' }


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
# current directory in VS Code). Don't shadow it with a function. 'cli' is pwsh clear-item, so avoid that too.

function cdcode    { Set-Location 'C:\Users\andre\code' }

function changelog { Set-Location 'C:\Users\andre\code\changelog-app' }

function prev { Set-Location 'C:\Users\andre\code\previous-coding-adventures' }

function handoff { Set-Location 'C:\Vaults\EVA\claude-sync' }

function returns { Set-Location 'C:\Users\andre\code\claude-sync' }

function csync {
    param([Parameter(Position=0)][string]$Mode = "")

    # Agent roots — single source of truth. Update if paths change (e.g. C:\Vaults -> C:\agents).
    $EVA_ROOT = "C:\Vaults\EVA"
    $CLI_ROOT = "C:\Users\andre\code"
    $AUD_ROOT = "C:\Vaults\AUD"

    # Flow definitions — the four directed copies in the ecosystem. Single source of truth.
    # Skip lets each destination keep its own README: audit-returns/ (AUD's write dir) and
    # aud/findings/ (the read-side mirror) document different things and must not clobber each other.
    $flows = @(
        [pscustomobject]@{ Name="EVA -> CLI"; Src="$EVA_ROOT\claude-sync";               Dst="$CLI_ROOT\claude-sync";  Skip=@() },
        [pscustomobject]@{ Name="CLI -> EVA"; Src="$CLI_ROOT\claude-sync";               Dst="$EVA_ROOT\claude-sync";  Skip=@() },
        [pscustomobject]@{ Name="AUD -> EVA"; Src="$AUD_ROOT\claude-sync\audit-returns"; Dst="$EVA_ROOT\aud\findings"; Skip=@('README.md') },
        [pscustomobject]@{ Name="AUD -> CLI"; Src="$AUD_ROOT\claude-sync\audit-returns"; Dst="$CLI_ROOT\aud\findings"; Skip=@('README.md') }
    )

    # Source files for a flow (recursive), minus skipped leaf names.
    function _srcFiles($flow) {
        if (-not (Test-Path $flow.Src)) { return @() }
        Get-ChildItem -LiteralPath $flow.Src -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object { $flow.Skip -notcontains $_.Name }
    }

    # True if the source file is missing at, or differs in content from, the destination.
    # Compare by length first (cheap), then by hash on a tie — mtime is deliberately ignored
    # so identical content with a newer timestamp does NOT register as drift.
    function _needsCopy($f, $target) {
        if (-not (Test-Path -LiteralPath $target)) { return $true }
        if ((Get-Item -LiteralPath $target).Length -ne $f.Length) { return $true }
        return (Get-FileHash -LiteralPath $f.FullName).Hash -ne (Get-FileHash -LiteralPath $target).Hash
    }

    # Count of source files that would be copied (drift). Read-only.
    function _drift($flow) {
        $base = (Resolve-Path $flow.Src).Path
        $n = 0
        foreach ($f in (_srcFiles $flow)) {
            $rel = $f.FullName.Substring($base.Length).TrimStart('\')
            if (_needsCopy $f (Join-Path $flow.Dst $rel)) { $n++ }
        }
        return $n
    }

    # Perform a flow's copy (new/changed files only). Returns count copied.
    function _run($flow) {
        if (-not (Test-Path $flow.Src)) {
            Write-Host ("  {0,-12}: source missing ({1}) - skipped" -f $flow.Name, $flow.Src) -ForegroundColor Yellow
            return 0
        }
        if (-not (Test-Path $flow.Dst)) { New-Item -ItemType Directory -Path $flow.Dst -Force | Out-Null }
        $base = (Resolve-Path $flow.Src).Path
        $copied = 0
        foreach ($f in (_srcFiles $flow)) {
            $rel = $f.FullName.Substring($base.Length).TrimStart('\')
            $target = Join-Path $flow.Dst $rel
            if (_needsCopy $f $target) {
                $tdir = Split-Path $target -Parent
                if (-not (Test-Path -LiteralPath $tdir)) { New-Item -ItemType Directory -Path $tdir -Force | Out-Null }
                Copy-Item -LiteralPath $f.FullName -Destination $target -Force
                $copied++
            }
        }
        $tag   = if ($copied -eq 0) { "up to date" } else { "+$copied file" + $(if ($copied -ne 1) { 's' }) }
        $color = if ($copied -eq 0) { 'DarkGray' } else { 'Green' }
        Write-Host ("  {0,-12}: {1}" -f $flow.Name, $tag) -ForegroundColor $color
        return $copied
    }

    # ---- status: read-only drift report across all flows, from anywhere ----
    if ($Mode -eq 'status') {
        Write-Host "csync status" -ForegroundColor Cyan
        $total = 0
        foreach ($flow in $flows) {
            if (-not (Test-Path $flow.Src)) {
                Write-Host ("  {0,-12}: source missing" -f $flow.Name) -ForegroundColor Yellow
                continue
            }
            $d = _drift $flow
            $total += $d
            $color = if ($d -eq 0) { 'DarkGray' } else { 'Yellow' }
            Write-Host ("  {0,-12}: {1} behind" -f $flow.Name, $d) -ForegroundColor $color
        }
        if ($total -eq 0) { Write-Host "  ALL CURRENT" -ForegroundColor Green }
        else { Write-Host ("  {0} file(s) behind - run 'csync all' to reconcile" -f $total) -ForegroundColor Yellow }
        return
    }

    # ---- all: run every flow regardless of cwd ----
    if ($Mode -eq 'all') {
        Write-Host "csync all" -ForegroundColor Cyan
        $total = 0
        foreach ($flow in $flows) { $total += (_run $flow) }
        if ($total -eq 0) { Write-Host "  already current - nothing copied" -ForegroundColor DarkGray }
        else { Write-Host ("  done - {0} file(s) copied" -f $total) -ForegroundColor Green }
        return
    }

    if ($Mode -ne '') {
        Write-Host "csync: unknown argument '$Mode'. Use: csync | csync status | csync all" -ForegroundColor Red
        return
    }

    # ---- default (no arg): route by which agent root you're standing in ----
    $current = (Get-Location).Path
    $agentRoot = $null
    while ($current -and ($current -ne (Split-Path $current -Parent))) {
        if (Test-Path (Join-Path $current "CLAUDE.md")) { $agentRoot = $current; break }
        $current = Split-Path $current -Parent
    }
    if (-not $agentRoot) {
        Write-Host "csync: not in a valid agent directory (no CLAUDE.md found walking up from $PWD)" -ForegroundColor Red
        Write-Host "  tip: 'csync all' syncs everything from anywhere; 'csync status' shows drift." -ForegroundColor Yellow
        return
    }
    $agentRoot = $agentRoot.TrimEnd('\')

    $route = switch ($agentRoot) {
        $EVA_ROOT { @("EVA -> CLI") }
        $CLI_ROOT { @("CLI -> EVA") }
        $AUD_ROOT { @("AUD -> EVA","AUD -> CLI") }
        default   { $null }
    }
    if (-not $route) {
        Write-Host "csync: not a recognized agent root: $agentRoot" -ForegroundColor Red
        Write-Host "  expected one of: $EVA_ROOT, $CLI_ROOT, $AUD_ROOT" -ForegroundColor Yellow
        return
    }
    Write-Host ("csync: {0}" -f ($route -join ' + ')) -ForegroundColor Cyan
    $total = 0
    foreach ($name in $route) { $total += (_run ($flows | Where-Object Name -eq $name)) }
    if ($total -eq 0) { Write-Host "  already current - nothing copied" -ForegroundColor DarkGray }
    else { Write-Host ("  done - {0} file(s) copied" -f $total) -ForegroundColor Green }
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


