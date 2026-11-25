<#
make-release.ps1 - builds the two zip files of a zero-to-expert release.

  zero-to-expert-skill.zip   the skill alone, for claude.ai and Claude Desktop (written next to README.md)
  zero-to-expert-pack.zip    the whole pack: plugin, agents, skill, install scripts, README (written to -OutDir)

Before building, it checks that:
  - the version is the same in plugin.json, marketplace.json and CITATION.cff;
  - every .ps1 file is pure ASCII (Windows PowerShell 5.1 reads files without a BOM as ANSI).

The file names never change, so the "latest release" download links stay valid:
  https://github.com/<account>/<repo>/releases/latest/download/zero-to-expert-skill.zip

Usage:
  powershell -ExecutionPolicy Bypass -File tools\make-release.ps1
  powershell -ExecutionPolicy Bypass -File tools\make-release.ps1 -OutDir "$env:USERPROFILE\Desktop"
#>
param([string]$OutDir)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
if (-not $OutDir) { $OutDir = Join-Path $root 'dist' }
$OutDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutDir)   # relative to the current location

# 1. Same version everywhere
$plugin = Get-Content -LiteralPath (Join-Path $root '.claude-plugin\plugin.json') -Raw | ConvertFrom-Json
$market = Get-Content -LiteralPath (Join-Path $root '.claude-plugin\marketplace.json') -Raw | ConvertFrom-Json
$version = [string]$plugin.version
$found = [ordered]@{ 'plugin.json' = $version; 'marketplace.json' = [string]@($market.plugins)[0].version }
$cff = Join-Path $root 'CITATION.cff'
if (Test-Path -LiteralPath $cff) {
    $m = Select-String -LiteralPath $cff -Pattern '^version:\s*"?([^"\s]+)"?' | Select-Object -First 1
    $found['CITATION.cff'] = if ($m) { $m.Matches[0].Groups[1].Value } else { '(none)' }
}
if (@($found.Values | Where-Object { $_ -ne $version }).Count) {
    throw ('Version mismatch: ' + (($found.Keys | ForEach-Object { "$_ = $($found[$_])" }) -join ', '))
}

# 2. PowerShell scripts must stay ASCII
foreach ($f in Get-ChildItem -LiteralPath $root -Recurse -File -Filter *.ps1) {
    $n = @([IO.File]::ReadAllBytes($f.FullName) | Where-Object { $_ -gt 127 }).Count
    if ($n) { throw "$($f.FullName) has $n non-ASCII bytes: Windows PowerShell 5.1 would misread it." }
}

# 3. Zip files with forward-slash entry names
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
function New-Zip([string]$from, [string]$prefix, [string]$zip, [string[]]$skip) {
    $tmp = $zip + '.tmp'
    if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force }
    $files = @(Get-ChildItem -LiteralPath $from -Recurse -File -Force | Sort-Object FullName)
    $fs = [IO.File]::Open($tmp, [IO.FileMode]::CreateNew)
    $za = New-Object IO.Compression.ZipArchive($fs, [IO.Compression.ZipArchiveMode]::Create)
    $count = 0
    try {
        foreach ($f in $files) {
            $rel = $f.FullName.Substring($from.Length).TrimStart('\').Replace('\', '/')
            if ($skip -contains $rel.Split('/')[0] -or $rel -like '*.tmp') { continue }
            [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($za, $f.FullName, "$prefix/$rel", [IO.Compression.CompressionLevel]::Optimal)
            $count++
        }
    } finally { $za.Dispose(); $fs.Dispose() }
    Move-Item -LiteralPath $tmp -Destination $zip -Force
    '{0}  ({1} files, {2:N0} KB)' -f $zip, $count, ((Get-Item -LiteralPath $zip).Length / 1KB)
}

New-Zip (Join-Path $root 'skills\zero-to-expert') 'zero-to-expert' (Join-Path $root 'zero-to-expert-skill.zip') @()
if (-not (Test-Path -LiteralPath $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }
New-Zip $root 'zero-to-expert-pack' (Join-Path $OutDir 'zero-to-expert-pack.zip') @('.git', '.github', 'dist', 'docs')
"Version $version is ready. Attach both zip files to the GitHub release v$version."
