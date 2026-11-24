<#
.SYNOPSIS
  Installs the zero-to-expert skill and its three agents into Claude Code, by copying files.
  Personal folder ~/.claude by default, or a project's .claude folder with -Project. Nothing else is changed.
  Nothing is ever deleted: an existing copy is moved to <.claude>\zero-to-expert-backups\ (with -Force or -Uninstall).

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\install.ps1
  powershell -ExecutionPolicy Bypass -File .\install.ps1 -Project C:\code\my-repo
  powershell -ExecutionPolicy Bypass -File .\install.ps1 -Force        # replace an existing install
  powershell -ExecutionPolicy Bypass -File .\install.ps1 -Uninstall
#>
param([string]$Project, [switch]$Force, [switch]$Uninstall)
$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
$root = if ($Project) { Join-Path (Resolve-Path -LiteralPath $Project).Path '.claude' } else { Join-Path $HOME '.claude' }
$skillDst = Join-Path $root 'skills\zero-to-expert'
$agentDst = Join-Path $root 'agents'
$agents = @(Get-ChildItem -LiteralPath (Join-Path $here 'agents') -Filter 'zero-to-expert-*.md')
$backup = Join-Path $root ('zero-to-expert-backups\' + (Get-Date -Format 'yyyyMMdd-HHmmss'))

function Move-Old {
    $moved = $false
    if (Test-Path -LiteralPath $skillDst) {
        New-Item -ItemType Directory -Force -Path $backup | Out-Null
        Move-Item -LiteralPath $skillDst -Destination (Join-Path $backup 'skill')
        $moved = $true
    }
    foreach ($a in $agents) {
        $t = Join-Path $agentDst $a.Name
        if (Test-Path -LiteralPath $t) {
            New-Item -ItemType Directory -Force -Path (Join-Path $backup 'agents') | Out-Null
            Move-Item -LiteralPath $t -Destination (Join-Path $backup 'agents')
            $moved = $true
        }
    }
    if ($moved) { "Previous copy moved to $backup" }
}

$exists = (Test-Path -LiteralPath $skillDst) -or (@($agents | Where-Object { Test-Path -LiteralPath (Join-Path $agentDst $_.Name) }).Count -gt 0)

if ($Uninstall) {
    if (-not $exists) { "zero-to-expert is not installed in $root."; return }
    Move-Old
    "Uninstalled from $root. The files were moved to the backup folder above, not deleted."
    return
}
if ($exists -and -not $Force) { throw "zero-to-expert is already installed in $root. Run again with -Force to replace it (the old copy goes to $root\zero-to-expert-backups)." }
if ($exists) { Move-Old }

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $skillDst) | Out-Null
New-Item -ItemType Directory -Force -Path $agentDst | Out-Null
Copy-Item -LiteralPath (Join-Path $here 'skills\zero-to-expert') -Destination $skillDst -Recurse
foreach ($a in $agents) { Copy-Item -LiteralPath $a.FullName -Destination (Join-Path $agentDst $a.Name) }
'Installed:'
"  skill -> $skillDst"
foreach ($a in $agents) { '  agent -> ' + (Join-Path $agentDst $a.Name) }
'Claude Code picks up the skill within seconds. If the skill or the agents do not appear, open a new Claude Code session.'
"Try: /zero-to-expert <subject>   or ask: 'use the zero-to-expert-teacher agent to build a course on <subject>'"
