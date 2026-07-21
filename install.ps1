# One-step install for Windows: registers the native messaging host with
# Firefox (registry key + manifest + .bat shim) and, if a signed .xpi is
# present in dist/, opens it in Firefox to install the extension.
#
# The native host is launched by Firefox on demand — nothing runs at login or
# in the background. Registration is a one-time registry key.
#
# Run from PowerShell:  .\install.ps1
# (If scripts are blocked:  powershell -ExecutionPolicy Bypass -File install.ps1)
# Pass -Local to prefer a locally built .xpi in dist/ over the latest release.
param([switch]$Local)
$ErrorActionPreference = "Stop"

$Dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$HostScript = Join-Path $Dir "native\open_in_chrome.py"

# Find Python
$Python = (Get-Command python -ErrorAction SilentlyContinue).Source
if (-not $Python) {
    $Py = (Get-Command py -ErrorAction SilentlyContinue).Source
    if ($Py) { $Python = (& $Py -3 -c "import sys; print(sys.executable)").Trim() }
}
if (-not $Python) {
    Write-Error "Python 3 is required — install it from https://www.python.org or the Microsoft Store"
}

# Warn if Chrome is missing
$ChromePaths = @(
    "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
    "$env:LocalAppData\Google\Chrome\Application\chrome.exe"
)
if (-not ($ChromePaths | Where-Object { Test-Path $_ })) {
    Write-Warning "Google Chrome not found — install it first"
}

# 1. .bat shim (Windows can't execute a .py directly as a native host)
$Bat = Join-Path $Dir "native\open_in_chrome.bat"
Set-Content -Path $Bat -Encoding ASCII -Value @"
@echo off
"$Python" "%~dp0open_in_chrome.py" %*
"@

# 2. Native host manifest pointing at the shim
$Manifest = Join-Path $Dir "native\com.meltzg.chrome_redirector.json"
@{
    name               = "com.meltzg.chrome_redirector"
    description        = "Opens URLs in Google Chrome for the chrome-redirector extension"
    path               = $Bat
    type               = "stdio"
    allowed_extensions = @("chrome-redirector@meltzg")
} | ConvertTo-Json | Set-Content -Path $Manifest -Encoding UTF8

# 3. Registry key so Firefox can find the manifest
$Key = "HKCU:\Software\Mozilla\NativeMessagingHosts\com.meltzg.chrome_redirector"
New-Item -Path $Key -Force | Out-Null
Set-ItemProperty -Path $Key -Name "(Default)" -Value $Manifest
Write-Host "✓ Native host registered: $Key"
Write-Host "  (points at $Bat — don't move or delete this clone)"

# 4. Extension: download the latest GitHub release so re-running the
# installer always updates. A local .xpi in dist/ is only a fallback —
# pass -Local to prefer it (e.g. to test a locally signed build).
$Xpi = $null
if (-not $Local) {
    try {
        Write-Host "Fetching latest release from GitHub..."
        $Release = Invoke-RestMethod "https://api.github.com/repos/meltzg/chrome-redirector/releases/latest"
        $Asset = $Release.assets | Where-Object { $_.name -like "*.xpi" } | Select-Object -First 1
        if ($Asset) {
            $DistDir = Join-Path $Dir "dist"
            New-Item -ItemType Directory -Force -Path $DistDir | Out-Null
            $XpiPath = Join-Path $DistDir $Asset.name
            Invoke-WebRequest $Asset.browser_download_url -OutFile $XpiPath
            $Xpi = Get-Item $XpiPath
        }
    } catch {
        Write-Warning "Could not download a release: $_"
    }
}
if (-not $Xpi) {
    $Xpi = Get-ChildItem -Path (Join-Path $Dir "dist") -Filter *.xpi -ErrorAction SilentlyContinue |
        Sort-Object Name | Select-Object -Last 1
    if ($Xpi) { Write-Host "Using local .xpi: $($Xpi.FullName)" }
}
if ($Xpi) {
    $Firefox = @(
        "$env:ProgramFiles\Mozilla Firefox\firefox.exe",
        "${env:ProgramFiles(x86)}\Mozilla Firefox\firefox.exe"
    ) | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $Firefox) { $Firefox = (Get-Command firefox -ErrorAction SilentlyContinue).Source }
    if ($Firefox) {
        Write-Host "✓ Opening signed extension in Firefox: $($Xpi.FullName)"
        Write-Host "  Click 'Add' in the Firefox prompt to finish."
        Start-Process $Firefox -ArgumentList "`"$($Xpi.FullName)`""
    } else {
        Write-Host "Firefox not found — drag $($Xpi.FullName) into a Firefox window to install."
    }
} else {
    Write-Host ""
    Write-Host "No signed .xpi found in dist/. To load the extension for testing:"
    Write-Host "  Firefox -> about:debugging#/runtime/this-firefox -> Load Temporary Add-on..."
    Write-Host "  -> select $Dir\extension\manifest.json"
}
