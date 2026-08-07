# ~/dotfiles/PowerShell_profile.ps1
#
# Sourced from $PROFILE on every PowerShell startup.
# Keep this file portable — anything machine-specific belongs in $PROFILE itself,
# not here.
#
# Repo: https://github.com/HoneySpoons/dotfiles

# -------------------------------------------------------------------
# Roots — the one place paths are written down
# -------------------------------------------------------------------
# Every navigation function and csync flow below derives from this table.
# Moving the vaults (C:\Vaults -> C:\agents, a different drive, whatever)
# is a one-line change here instead of a 20-site find-and-replace.
#
# $Agents keys are the four agents in the ecosystem. Hashtable lookup is
# case-insensitive, so $Agents.eva and $Agents['EVA'] are the same thing.

$Vaults = 'C:\Vaults'

$Agents = @{
    EVA = "$Vaults\EVA"   # Evolving Vault Archivist — wiki, concepts, handoff authoring
    CLI = "$Vaults\CLI"   # Claude Code — the running codebase
    AUD = "$Vaults\AUD"   # read-only auditor
    DES = "$Vaults\DES"   # design studio — comps, decks, prototypes
}

# -------------------------------------------------------------------
# Restart PowerShell
# -------------------------------------------------------------------
# Actually restarts: launches a fresh pwsh in this window's place, then exits.
# (The old `$host.SetShouldExit(1)` only exited — in Windows Terminal that
# just closes the tab.)

function restart {
    Start-Process pwsh -ArgumentList '-NoLogo' -WorkingDirectory (Get-Location).Path
    exit
}

# -------------------------------------------------------------------
# PSReadLine — better history + inline predictions
# -------------------------------------------------------------------
# As you type, PSReadLine shows a gray ghosted suggestion based on
# your history. Right-arrow (or End) accepts it. F2 toggles between
# inline view and ListView (a dropdown of matching history items).
#
# Guarded: prediction throws when there's no real console attached — a
# redirected `pwsh -Command`, a script host, CI. That noise was firing on
# every non-interactive shell before 2026-08-07. Note $Host.UI.Supports-
# VirtualTerminal is NOT the right test (it still reports true when output
# is piped); [Console]::IsOutputRedirected is.

if (-not [Console]::IsOutputRedirected) {
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle ListView
}
Set-PSReadLineOption -EditMode Windows

# -------------------------------------------------------------------
# DirPick — Alt+Shift+F — fuzzy-pick from cwd, insert at cursor
# -------------------------------------------------------------------
# Requires fzf (winget install junegunn.fzf).
#
# History, so it doesn't get misdiagnosed a third time:
#   2026-05-11  Defender quarantined fzf.exe on first execution (generic
#               false-positive on unsigned Go TUI binaries). Commit b76e675
#               blamed a BIOS update — it wasn't; Smart App Control reads 0.
#   2026-08-07  fzf 0.74.2 installs, executes, and survives on disk. The
#               pwsh 7.6 native-redirect regression that would have broken
#               the pipe below is also gone as of 7.6.4 — verified with a
#               real `@(...) | fzf --filter=...` round-trip. Handler restored.
#
# If Defender eats it again the handler no-ops with a message rather than
# throwing mid-keystroke.

Set-PSReadLineKeyHandler -Key "Alt+Shift+F" `
    -BriefDescription "DirPick" `
    -LongDescription "Pick a file/folder from cwd and insert at cursor" `
    -ScriptBlock {

    if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
        [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
        Write-Host "DirPick: fzf not found (winget install junegunn.fzf)" -ForegroundColor Yellow
        return
    }

    $items = Get-ChildItem | ForEach-Object {
        if ($_.PSIsContainer) { "$($_.Name)/" } else { $_.Name }
    }
    if (-not $items) { return }

    $selected = $items | fzf --prompt="ls> " --height=40% --layout=reverse

    if ($selected) {
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert($selected.TrimEnd('/'))
    }
}

# -------------------------------------------------------------------
# General navigation
# -------------------------------------------------------------------

function docs  { Set-Location "$HOME\Documents" }
function andre { Set-Location $HOME }
function root  { Set-Location 'C:\' }
function dot   { Set-Location "$HOME\dotfiles" }

# -------------------------------------------------------------------
# Agent navigation
# -------------------------------------------------------------------
# Note: `code` is the VS Code CLI (`code .`) — don't shadow it.
# Note: `cli` is NOT defined here. PowerShell ships `cli` as a built-in
#       alias for Clear-Item, and aliases outrank functions in command
#       resolution — a `function cli` is dead on arrival, it never runs.
#       Use `cdcode` for C:\Vaults\CLI.

# EVA
function eva   { Set-Location $Agents.EVA }
function wiki  { Set-Location "$($Agents.EVA)\wiki" }
function vlog  { code "$($Agents.EVA)\wiki\log.md" }

# AUD
function aud   { Set-Location $Agents.AUD }
function alog  { code "$($Agents.AUD)\audit-log.md" }

# DES
function des   { Set-Location $Agents.DES }
function dlog  { code "$($Agents.DES)\log.md" }
function comps { Set-Location "$($Agents.DES)\comps" }

# DES comps are single-file .dc.html artifacts whose entire purpose is
# being looked at. `comp` opens the most recent one in the browser;
# `comp <substring>` opens the newest match.
function comp {
    param([string]$Match = "")
    $root = "$($Agents.DES)\comps"
    if (-not (Test-Path $root)) { Write-Host "comp: no comps dir at $root" -ForegroundColor Red; return }

    $found = Get-ChildItem -LiteralPath $root -Recurse -File -Filter "*.dc.html" -ErrorAction SilentlyContinue |
             Where-Object { $Match -eq "" -or $_.Name -like "*$Match*" } |
             Sort-Object LastWriteTime -Descending

    if (-not $found) {
        Write-Host "comp: no .dc.html matching '$Match' under $root" -ForegroundColor Yellow
        return
    }
    Write-Host ("opening {0}  ({1:yyyy-MM-dd})" -f $found[0].Name, $found[0].LastWriteTime) -ForegroundColor Cyan
    Start-Process $found[0].FullName
    if ($found.Count -gt 1) {
        Write-Host ("  {0} other match(es):" -f ($found.Count - 1)) -ForegroundColor DarkGray
        $found | Select-Object -Skip 1 -First 5 | ForEach-Object {
            Write-Host ("    {0}  ({1:yyyy-MM-dd})" -f $_.Name, $_.LastWriteTime) -ForegroundColor DarkGray
        }
    }
}

# CLI / code workspace
function cdcode    { Set-Location $Agents.CLI }
function changelog { Set-Location "$($Agents.CLI)\changelog-app" }
function kuramoto  { Set-Location "$($Agents.CLI)\kuramoto-dev" }
function prev      { Set-Location "$($Agents.CLI)\Previous-Coding-Adventures" }

# Sync layer
function handoff { Set-Location "$($Agents.EVA)\claude-sync" }   # EVA-side (canonical)
function returns { Set-Location "$($Agents.CLI)\claude-sync" }   # CLI-side (mirror)

# -------------------------------------------------------------------
# Vault search
# -------------------------------------------------------------------
# vsearch "term"            — full-text search EVA's markdown (recursive)
# vsearch "term" -Agent All — search every agent tree
# vopen "wiki/log"          — open a note in Obsidian by vault-relative path
# vrecent                   — 10 most recently modified notes
#
# ⚠ The old implementation used Select-String -Path "...\**\*.md". PowerShell
#   has NO recursive `**` glob — it parses as a single `*`, matching exactly
#   one directory level. That searched 12 of 696 files (~5%); the entire wiki
#   lives at depth 3-5 and was never once searched. Fixed 2026-08-07 by
#   enumerating with Get-ChildItem -Recurse and piping into Select-String.

function Get-VaultFiles {
    param([string[]]$Roots)
    foreach ($r in $Roots) {
        if (-not (Test-Path $r)) { continue }
        Get-ChildItem -LiteralPath $r -Recurse -File -Filter *.md -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -notmatch '\\(node_modules|\.git|dist|build|\.expo)\\' }
    }
}

function vsearch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)][string]$Query,
        [ValidateSet('EVA', 'CLI', 'AUD', 'DES', 'All')][string]$Agent = 'EVA',
        [switch]$Regex
    )

    $roots = if ($Agent -eq 'All') { $Agents.Values } else { @($Agents[$Agent]) }
    $files = @(Get-VaultFiles -Roots $roots)
    if (-not $files) { Write-Host "vsearch: no markdown found under $($roots -join ', ')" -ForegroundColor Yellow; return }

    $hits = @($files | Select-String -Pattern $Query -SimpleMatch:(-not $Regex) -CaseSensitive:$false -ErrorAction SilentlyContinue)

    Write-Host ("vsearch '{0}' in {1}: {2} match(es) in {3} file(s)  [{4} searched]" -f `
        $Query, $Agent, $hits.Count, ($hits.Path | Select-Object -Unique).Count, $files.Count) -ForegroundColor Cyan

    $hits | ForEach-Object {
        [pscustomobject]@{
            File = $_.Path.Replace("$Vaults\", '')
            Line = $_.LineNumber
            Text = $_.Line.Trim()
        }
    }
}

function vopen {
    param([Parameter(Mandatory)][string]$File, [string]$Vault = 'EVA')
    Start-Process "obsidian://open?vault=$Vault&file=$([uri]::EscapeDataString($File))"
}

function vrecent {
    param([int]$n = 10, [ValidateSet('EVA', 'CLI', 'AUD', 'DES', 'All')][string]$Agent = 'EVA')
    $roots = if ($Agent -eq 'All') { $Agents.Values } else { @($Agents[$Agent]) }
    Get-VaultFiles -Roots $roots |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First $n @{n = 'Note'; e = { $_.FullName.Replace("$Vaults\", '') } }, LastWriteTime
}

# -------------------------------------------------------------------
# csync — the handoff sync layer
# -------------------------------------------------------------------
#   csync          — sync based on which agent root you're standing in
#   csync status   — read-only drift report across all flows, from anywhere
#   csync all      — run every flow regardless of cwd
#
# Copies are content-addressed: a file is copied only when it's missing at
# the destination or differs by length/hash. mtime is deliberately ignored,
# so a touched-but-identical file does not register as drift.
#
# DES has no claude-sync of its own — per DES's CLAUDE.md it plugs into the
# existing shared layer, writing handoffs and returns directly into EVA's
# canonical claude-sync. So DES is a *route*, not a new flow: standing in
# the DES root runs EVA -> CLI, which is what carries DES's output across.

function csync {
    param([Parameter(Position = 0)][string]$Mode = "")

    $EVA_ROOT = $Agents.EVA
    $CLI_ROOT = $Agents.CLI
    $AUD_ROOT = $Agents.AUD
    $DES_ROOT = $Agents.DES

    # Flow definitions — the four directed copies in the ecosystem. Single source of truth.
    # Skip lets each destination keep its own README: audit-returns/ (AUD's write dir) and
    # aud/findings/ (the read-side mirror) document different things and must not clobber each other.
    $flows = @(
        [pscustomobject]@{ Name = "EVA -> CLI"; Src = "$EVA_ROOT\claude-sync";               Dst = "$CLI_ROOT\claude-sync";  Skip = @() },
        [pscustomobject]@{ Name = "CLI -> EVA"; Src = "$CLI_ROOT\claude-sync";               Dst = "$EVA_ROOT\claude-sync";  Skip = @() },
        [pscustomobject]@{ Name = "AUD -> EVA"; Src = "$AUD_ROOT\claude-sync\audit-returns"; Dst = "$EVA_ROOT\aud\findings"; Skip = @('README.md') },
        [pscustomobject]@{ Name = "AUD -> CLI"; Src = "$AUD_ROOT\claude-sync\audit-returns"; Dst = "$CLI_ROOT\aud\findings"; Skip = @('README.md') }
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
        $AUD_ROOT { @("AUD -> EVA", "AUD -> CLI") }
        $DES_ROOT { @("EVA -> CLI") }   # DES writes into EVA's canonical claude-sync
        default   { $null }
    }
    if (-not $route) {
        Write-Host "csync: not a recognized agent root: $agentRoot" -ForegroundColor Red
        Write-Host "  expected one of: $EVA_ROOT, $CLI_ROOT, $AUD_ROOT, $DES_ROOT" -ForegroundColor Yellow
        return
    }
    if ($agentRoot -eq $DES_ROOT) {
        Write-Host "csync: DES (via EVA canonical) -> CLI" -ForegroundColor Cyan
    } else {
        Write-Host ("csync: {0}" -f ($route -join ' + ')) -ForegroundColor Cyan
    }
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
#
# ⚠ This is ~600ms of the ~875ms profile load. If shell startup ever starts
#   to annoy you, this is the line to attack (lazy-load on first git dir).

Import-Module posh-git -ErrorAction SilentlyContinue

# -------------------------------------------------------------------
# Package Management
# -------------------------------------------------------------------
# Where is <name> installed? Checks every package manager on this box.
#
# Renamed from `find-package` 2026-08-07 — that name shadowed the real
# Find-Package cmdlet from PackageManagement (functions outrank cmdlets).

function pkg {
    param([Parameter(Mandatory)][string]$Name)
    Write-Host "--- winget ---"
    winget list | findstr -i $Name
    Write-Host "--- python (pip) ---"
    pip show $Name 2>$null
    Write-Host "--- uv ---"
    uv pip show $Name 2>$null
    Write-Host "--- npm global ---"
    npm list -g --depth=0 2>$null | findstr -i $Name
    Write-Host "--- command path ---"
    where.exe $Name 2>$null
}
