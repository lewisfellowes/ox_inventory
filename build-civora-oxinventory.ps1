$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "CivoraRP ox_inventory release builder" -ForegroundColor Cyan
Write-Host ""

$repo = Split-Path -Parent $MyInvocation.MyCommand.Path
$web = Join-Path $repo "web"
$destRoot = "C:\Dev\ox\ox_inventory-release"
$dest = Join-Path $destRoot "ox_inventory"

Set-Location $repo

Write-Host "Source      : $repo"
Write-Host "Destination : $dest"
Write-Host ""

# ------------------------------------------------------------------
# Safety checks
# ------------------------------------------------------------------

if (-not (Test-Path (Join-Path $repo "fxmanifest.lua"))) {
    throw "fxmanifest.lua not found. Run this script from the ox_inventory repository root."
}

if (-not (Test-Path (Join-Path $web "package.json"))) {
    throw "web\package.json not found."
}

$status = git status --porcelain

if ($status) {
    Write-Host "WARNING: Working tree contains uncommitted changes." -ForegroundColor Yellow
    git status
    Write-Host ""

    $continue = Read-Host "Continue building this working tree? (y/n)"

    if ($continue -notin @("y", "Y")) {
        Write-Host "Build cancelled."
        exit 0
    }
}

# ------------------------------------------------------------------
# Build UI
# ------------------------------------------------------------------

Write-Host "Building web UI..." -ForegroundColor Cyan
Write-Host ""

Push-Location $web

bun run build

$buildExit = $LASTEXITCODE

Pop-Location

if ($buildExit -ne 0) {
    throw "Web build failed."
}

$builtIndex = Join-Path $web "build\index.html"

if (-not (Test-Path $builtIndex)) {
    throw "Build completed but web\build\index.html was not found."
}

Write-Host ""
Write-Host "Web build passed." -ForegroundColor Green
Write-Host ""

# ------------------------------------------------------------------
# Recreate release directory
# ------------------------------------------------------------------

if (Test-Path $destRoot) {
    Write-Host "Removing existing release directory..." -ForegroundColor DarkGray
    Remove-Item $destRoot -Recurse -Force
}

New-Item -ItemType Directory -Path $dest | Out-Null

# ------------------------------------------------------------------
# Copy runtime root files
# ------------------------------------------------------------------

Write-Host "Copying runtime files..." -ForegroundColor Cyan

$rootFiles = @(
    "fxmanifest.lua",
    "init.lua",
    "client.lua",
    "server.lua",
    "LICENSE",
    "README.md"
)

foreach ($file in $rootFiles) {
    $source = Join-Path $repo $file

    if (Test-Path $source) {
        Copy-Item $source $dest
        Write-Host "  + $file"
    }
}

# ------------------------------------------------------------------
# Copy runtime directories
# ------------------------------------------------------------------

$runtimeDirectories = @(
    "data",
    "locales",
    "modules"
)

foreach ($directory in $runtimeDirectories) {
    $source = Join-Path $repo $directory

    if (Test-Path $source) {
        Copy-Item $source (Join-Path $dest $directory) -Recurse
        Write-Host "  + $directory\"
    }
}

# ------------------------------------------------------------------
# Copy only runtime web content
# ------------------------------------------------------------------

$destWeb = Join-Path $dest "web"

New-Item -ItemType Directory -Path $destWeb | Out-Null

Copy-Item `
    (Join-Path $web "build") `
    (Join-Path $destWeb "build") `
    -Recurse

Write-Host "  + web\build\"

Copy-Item `
    (Join-Path $web "images") `
    (Join-Path $destWeb "images") `
    -Recurse

Write-Host "  + web\images\"

# ------------------------------------------------------------------
# Validate package
# ------------------------------------------------------------------

Write-Host ""
Write-Host "Validating release..." -ForegroundColor Cyan

$required = @(
    "fxmanifest.lua",
    "init.lua",
    "client.lua",
    "server.lua",
    "data",
    "modules",
    "web\build\index.html",
    "web\images"
)

$missing = @()

foreach ($path in $required) {
    $fullPath = Join-Path $dest $path

    if (-not (Test-Path $fullPath)) {
        $missing += $path
    }
}

if ($missing.Count -gt 0) {
    Write-Host ""
    Write-Host "Release validation failed." -ForegroundColor Red

    foreach ($item in $missing) {
        Write-Host "Missing: $item" -ForegroundColor Red
    }

    exit 1
}

# ------------------------------------------------------------------
# Report
# ------------------------------------------------------------------

$fileCount = (
    Get-ChildItem $dest -Recurse -File |
    Measure-Object
).Count

$sizeBytes = (
    Get-ChildItem $dest -Recurse -File |
    Measure-Object Length -Sum
).Sum

$sizeMb = [Math]::Round($sizeBytes / 1MB, 2)

Write-Host ""
Write-Host "Release built successfully." -ForegroundColor Green
Write-Host ""
Write-Host "Output:"
Write-Host "  $dest"
Write-Host ""
Write-Host "Files : $fileCount"
Write-Host "Size  : $sizeMb MB"
Write-Host ""

Write-Host "Not included:" -ForegroundColor DarkGray
Write-Host "  .git"
Write-Host "  .github"
Write-Host "  node_modules"
Write-Host "  web\src"
Write-Host "  web development config"
Write-Host "  updater/build scripts"
Write-Host ""

Write-Host "This ox_inventory folder is the runtime resource to upload to FiveM." -ForegroundColor Cyan
Write-Host ""