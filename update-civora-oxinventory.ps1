$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "CivoraRP ox_inventory updater" -ForegroundColor Cyan
Write-Host ""

$repo = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $repo

Write-Host "Repository: $repo"
Write-Host ""

$origin = git remote get-url origin
$upstream = git remote get-url upstream

Write-Host "origin   : $origin"
Write-Host "upstream : $upstream"
Write-Host ""

if ($origin -notlike "*lewisfellowes/ox_inventory.git") {
    throw "origin does not point to the CivoraRP fork."
}

if ($upstream -notlike "*overextended/ox_inventory.git") {
    throw "upstream does not point to official ox_inventory."
}

$status = git status --porcelain

if ($status) {
    Write-Host "Working tree is not clean:" -ForegroundColor Red
    git status
    throw "Commit or stash your changes before updating."
}

$currentBranch = git branch --show-current

if ($currentBranch -ne "civorarp-ui") {
    throw "Expected to be on civorarp-ui, but current branch is '$currentBranch'."
}

Write-Host "Fetching upstream..." -ForegroundColor Cyan
git fetch upstream --tags

Write-Host ""
Write-Host "Incoming upstream commits:" -ForegroundColor Cyan
Write-Host ""

$incoming = git log --oneline HEAD..upstream/main

if (-not $incoming) {
    Write-Host "No upstream updates available." -ForegroundColor Green
    exit 0
}

$incoming

Write-Host ""
$answer = Read-Host "Merge upstream/main into civorarp-ui now? (y/n)"

if ($answer -notin @("y", "Y")) {
    Write-Host "Update cancelled."
    exit 0
}

Write-Host ""
Write-Host "Creating safety branch..." -ForegroundColor Cyan

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupBranch = "backup/civorarp-ui-$stamp"

git branch $backupBranch

Write-Host "Created $backupBranch" -ForegroundColor Green

Write-Host ""
Write-Host "Merging upstream/main..." -ForegroundColor Cyan

git merge upstream/main

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "Merge conflict detected." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Resolve the conflicts, then run:"
    Write-Host ""
    Write-Host "    git add ."
    Write-Host "    git commit"
    Write-Host "    bun --cwd web run build"
    Write-Host ""
    Write-Host "If you need to abort:"
    Write-Host ""
    Write-Host "    git merge --abort"
    Write-Host ""
    Write-Host "Safety branch: $backupBranch"
    exit 1
}

Write-Host ""
Write-Host "Running production build..." -ForegroundColor Cyan

Push-Location .\web
bun run build
$buildExit = $LASTEXITCODE
Pop-Location

if ($buildExit -ne 0) {
    Write-Host ""
    Write-Host "Build failed after merge." -ForegroundColor Red
    Write-Host "Safety branch: $backupBranch"
    exit $buildExit
}

Write-Host ""
Write-Host "Build passed." -ForegroundColor Green
Write-Host ""

$push = Read-Host "Push updated civorarp-ui to your fork? (y/n)"

if ($push -in @("y", "Y")) {
    git push origin civorarp-ui
    Write-Host ""
    Write-Host "Updated branch pushed successfully." -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "Update complete locally. Nothing was pushed."
}

Write-Host ""
Write-Host "Safety branch: $backupBranch"
Write-Host ""