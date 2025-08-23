<#
.SYNOPSIS
    Synchronizes Git submodules, checks for updates, dirty states, and optionally commits pointer changes.

.DESCRIPTION
    - Validates script location inside dev-lab repo
    - Navigates to repo root safely
    - Fetches latest commits from submodule remotes
    - Updates submodules to match remote 'main' branches
    - Detects uncommitted changes or untracked files
    - Prompts to commit updated submodule pointers in parent repo

.NOTES
    Author: Vincent (vvillatte)
    Location: \dev-lab\utils\powershell\src\GitSubmodulesSync.ps1
#>

# --- Helper: Safe Git Execution ---
function Invoke-Git {
    param ([string]$Command)
    try {
        & git $Command 2>&1 | ForEach-Object { $_ }
    } catch {
        Write-Host "❌ Git command failed: git $Command" -ForegroundColor Red
        throw
    }
}

# --- Step 1: Validate Script Location ---
$scriptPath = $MyInvocation.MyCommand.Path
$expectedRoot = Resolve-Path (Join-Path $scriptPath "..\..\..") | Select-Object -ExpandProperty Path

if (-not (Test-Path "$expectedRoot\.git")) {
    Write-Host "`n🚫 Script must be run from within the dev-lab repo structure." -ForegroundColor Red
    Write-Host "Expected .git directory at: $expectedRoot" -ForegroundColor Yellow
    exit 1
}

Set-Location $expectedRoot
Write-Host "`n📁 Working from repo root: $expectedRoot" -ForegroundColor Cyan

# --- Step 2: Check Submodule Status ---
Write-Host "`n🔍 Checking submodule status..." -ForegroundColor Cyan
Invoke-Git "submodule foreach --quiet 'echo \"📁 \$name\"; git fetch origin; git status'"

# --- Step 3: Update Submodules ---
Write-Host "`n🔄 Updating submodules to latest remote commits..." -ForegroundColor Yellow
Invoke-Git "submodule update --remote --merge"

# --- Step 4: Detect Dirty Submodules ---
Write-Host "`n📌 Checking for dirty submodules..." -ForegroundColor Cyan
$dirtyModules = git submodule foreach {
    git diff --quiet
    if (-not $?) {
        Write-Output "$name is dirty"
    }
}

if ($dirtyModules -and $dirtyModules.Count -gt 0) {
    Write-Host "`n⚠️ Dirty submodules detected:" -ForegroundColor Red
    $dirtyModules | ForEach-Object { Write-Host $_ }
} else {
    Write-Host "`n✅ All submodules are clean." -ForegroundColor Green
}

# --- Step 5: Detect Pointer Changes ---
Write-Host "`n📎 Checking for updated submodule pointers..." -ForegroundColor Cyan
$pointerChanges = Invoke-Git "status --porcelain" | Select-String '^ M '

if ($pointerChanges) {
    Write-Host "`n📝 Submodule pointers have changed:" -ForegroundColor Yellow
    $pointerChanges | ForEach-Object { Write-Host $_ }

    $confirm = Read-Host "`nDo you want to commit updated submodule pointers to parent repo? (y/n)"
    if ($confirm -eq 'y') {
        try {
            Invoke-Git "add ."
            Invoke-Git "commit -m 'Update submodule pointers via GitSubmodulesSync.ps1'"
            Invoke-Git "push origin main"
            Write-Host "`n🚀 Pointers committed and pushed." -ForegroundColor Green
        } catch {
            Write-Host "`n❌ Failed to commit or push changes." -ForegroundColor Red
        }
    } else {
        Write-Host "`n🛑 Skipped committing pointers." -ForegroundColor DarkYellow
    }
} else {
    Write-Host "`n✅ No pointer changes detected." -ForegroundColor Green
}

Write-Host "`n🎯 Sync complete." -ForegroundColor Cyan