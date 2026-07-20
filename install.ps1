#!/usr/bin/env pwsh
# Pingram CLI installer for Windows
#
# Usage (PowerShell):
# irm https://raw.githubusercontent.com/pingram-io/cli/main/install.ps1 | iex
#
# Pin a version:
# $env:PINGRAM_VERSION = '0.1.0'; irm .../install.ps1 | iex
#
# Environment variables:
# PINGRAM_INSTALL  - Custom install directory (default: $HOME\.pingram)
# PINGRAM_VERSION  - Version to install (default: latest CLI release)

param(
  [string]$Version = $env:PINGRAM_VERSION
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Info { param($msg) Write-Host " $msg" -ForegroundColor DarkGray }
function Write-Ok { param($msg) Write-Host " $msg" -ForegroundColor Green }

function Write-Fail {
  param($msg)
  Write-Host " error: $msg" -ForegroundColor Red
}

if ($env:PROCESSOR_ARCHITECTURE -notin @('AMD64', 'EM64T')) {
  Write-Fail "Unsupported architecture: $env:PROCESSOR_ARCHITECTURE`n`n Pingram CLI currently supports Windows x64 only."
  throw "Installation failed."
}

$repo = 'https://github.com/pingram-io/cli'
$tagPrefix = 'pingram-cli-v'
$target = 'windows-x64'

if ($Version) {
  $Version = $Version.TrimStart('v')
  if ($Version -notmatch '^\d+\.\d+\.\d+(-[a-zA-Z0-9.]+)?$') {
    Write-Fail "Invalid version format: $Version`n`n Expected: semantic version like 0.1.0`n Usage: `$env:PINGRAM_VERSION = '0.1.0'; irm .../install.ps1 | iex"
    throw "Installation failed."
  }
  $tag = "$tagPrefix$Version"
} else {
  $releases = Invoke-RestMethod -Uri 'https://api.github.com/repos/pingram-io/cli/releases?per_page=100'
  $tag = ($releases | Where-Object { $_.tag_name -like 'pingram-cli-v*' } | Select-Object -First 1).tag_name
  if (-not $tag) {
    Write-Fail "No Pingram CLI release found. Install via npm instead: npm install -g pingram-cli"
    throw "Installation failed."
  }
}

$url = "$repo/releases/download/$tag/pingram-$target.zip"

if ($env:PINGRAM_INSTALL) { $installDir = $env:PINGRAM_INSTALL } else { $installDir = Join-Path $HOME '.pingram' }
$binDir = Join-Path $installDir 'bin'
$exe = Join-Path $binDir 'pingram.exe'

if (-not (Test-Path $binDir)) {
  New-Item -ItemType Directory -Path $binDir -Force | Out-Null
}

Write-Host ""
Write-Host " Installing Pingram CLI..." -ForegroundColor White
Write-Host ""
Write-Info "Downloading from $url"
Write-Host ""

$tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) "pingram-$([System.Guid]::NewGuid())"
New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null
$tmpZip = Join-Path $tmpDir 'pingram.zip'

try {
  try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $url -OutFile $tmpZip -UseBasicParsing
  } catch {
    Write-Fail "Download failed.`n`n URL: $url"
    throw "Installation failed."
  }

  try {
    Expand-Archive -Path $tmpZip -DestinationPath $binDir -Force
  } catch {
    Write-Fail "Failed to extract archive: $_"
    throw "Installation failed."
  }
} finally {
  Remove-Item -Recurse -Force $tmpDir -ErrorAction SilentlyContinue
}

if (-not (Test-Path $exe)) {
  Write-Fail "Binary not found after extraction. The download may be corrupted — try again."
  throw "Installation failed."
}

try {
  $installedVersion = (& $exe --version 2>$null).Trim()
} catch {
  $installedVersion = 'unknown'
}

Write-Host ""
Write-Ok "Pingram CLI $installedVersion installed successfully!"
Write-Host ""
Write-Info "Binary: $exe"

$userPath = [Environment]::GetEnvironmentVariable('PATH', 'User')
if (-not $userPath) { $userPath = '' }
$pathEntries = $userPath -split ';' | Where-Object { $_ -ne '' }

if ($pathEntries -contains $binDir) {
  Write-Host ""
  Write-Host " Run " -NoNewline
  Write-Host "pingram login" -ForegroundColor Cyan -NoNewline
  Write-Host " to get started"
  Write-Host ""
  return
}

$newPath = ($pathEntries + $binDir) -join ';'
[Environment]::SetEnvironmentVariable('PATH', $newPath, 'User')
$env:PATH = "$env:PATH;$binDir"

Write-Info "Added $binDir to PATH (User scope)"
Write-Host ""
Write-Info "Restart your terminal, then run:"
Write-Host ""
Write-Host " pingram login" -ForegroundColor Cyan
Write-Host " pingram --help" -ForegroundColor Cyan
Write-Host ""
