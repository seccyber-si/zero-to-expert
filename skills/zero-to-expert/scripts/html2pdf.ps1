<#
.SYNOPSIS
  Prints an HTML course to PDF with a headless Chromium browser (Edge, Chrome, Brave or Chromium).

.DESCRIPTION
  - Uses a throw-away browser profile, so the user's normal browser and its session are never touched.
  - The wait is bounded (-TimeoutSec); on timeout the headless browser is stopped.
  - At the end the temporary profile and log files are deleted and leftover browser processes are checked.
  - Prints one summary line (pages, external links, size) plus the page console messages, so a
    diagram error ("[diagrams] ... failed") is visible without opening the PDF.
  Works with Windows PowerShell 5.1 and PowerShell 7 (Windows, macOS, Linux).

.EXAMPLE
  .\html2pdf.ps1 -Html .\course.html -Pdf "$HOME\Desktop\My course.pdf"
#>
param(
    [Parameter(Mandatory = $true)][string]$Html,
    [Parameter(Mandatory = $true)][string]$Pdf,
    [string]$Browser,
    [int]$TimeoutSec = 180
)
$ErrorActionPreference = 'Stop'
$onWindows = ($env:OS -eq 'Windows_NT')

function Find-Browser {
    $c = New-Object System.Collections.Generic.List[string]
    if ($onWindows) {
        foreach ($base in @(${env:ProgramFiles(x86)}, $env:ProgramFiles, $env:LOCALAPPDATA)) {
            if (-not $base) { continue }
            $c.Add((Join-Path $base 'Microsoft\Edge\Application\msedge.exe'))
            $c.Add((Join-Path $base 'Google\Chrome\Application\chrome.exe'))
            $c.Add((Join-Path $base 'BraveSoftware\Brave-Browser\Application\brave.exe'))
            $c.Add((Join-Path $base 'Chromium\Application\chrome.exe'))
        }
    } else {
        $c.Add('/Applications/Google Chrome.app/Contents/MacOS/Google Chrome')
        $c.Add('/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge')
        $c.Add('/Applications/Chromium.app/Contents/MacOS/Chromium')
        $c.Add('/Applications/Brave Browser.app/Contents/MacOS/Brave Browser')
        foreach ($n in 'google-chrome', 'google-chrome-stable', 'chromium', 'chromium-browser', 'microsoft-edge', 'microsoft-edge-stable', 'brave-browser') {
            $cmd = Get-Command $n -ErrorAction SilentlyContinue
            if ($cmd) { $c.Add($cmd.Source) }
        }
    }
    foreach ($p in $c) { if ($p -and (Test-Path -LiteralPath $p)) { return $p } }
    return $null
}

# Every process of this run carries the unique profile path on its command line.
function Stop-Leftovers([string]$marker) {
    if ($onWindows) {
        $left = @(Get-CimInstance Win32_Process -Filter "Name='msedge.exe' OR Name='chrome.exe' OR Name='brave.exe'" -ErrorAction SilentlyContinue |
            Where-Object { $_.CommandLine -and $_.CommandLine.Contains($marker) })
        foreach ($proc in $left) { Stop-Process -Id $proc.ProcessId -Force -ErrorAction SilentlyContinue }
        return $left.Count
    }
    & pkill -f $marker
    return 0
}

function Quote([string]$s) { if ($s -match '[\s"]') { '"' + $s.Replace('"', '\"') + '"' } else { $s } }

$htmlPath = (Resolve-Path -LiteralPath $Html).Path
$pdfPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Pdf)   # relative to the current location (GetFullPath ignores cd)
$outDir = Split-Path -Parent $pdfPath
if (-not (Test-Path -LiteralPath $outDir)) { throw "Output folder does not exist: $outDir" }
if (-not $Browser) { $Browser = Find-Browser }
if (-not $Browser) { throw 'No Chromium-based browser found (Edge, Chrome, Brave, Chromium). Install one, or open the HTML in a browser and use Print > Save as PDF.' }

$tag = 'html2pdf-' + [guid]::NewGuid().ToString('N').Substring(0, 12)
$tmpProfile = Join-Path ([IO.Path]::GetTempPath()) $tag
$errLog = $tmpProfile + '.err.txt'
$outLog = $tmpProfile + '.out.txt'
if (Test-Path -LiteralPath $pdfPath) { Remove-Item -LiteralPath $pdfPath -Force }

$browserArgs = @(
    '--headless=new', '--disable-gpu', '--no-first-run', '--no-default-browser-check', '--disable-extensions',
    '--disable-sync', '--no-pdf-header-footer', '--generate-pdf-document-outline', '--virtual-time-budget=8000',
    '--enable-logging=stderr', '--log-level=0',
    (Quote "--user-data-dir=$tmpProfile"), (Quote "--print-to-pdf=$pdfPath"), (Quote ([Uri]$htmlPath).AbsoluteUri)
)
if (-not $onWindows -and (& id -u) -eq '0') { $browserArgs = @('--no-sandbox') + $browserArgs }

$sw = [Diagnostics.Stopwatch]::StartNew()
$left = 0
try {
    $sp = @{ FilePath = $Browser; ArgumentList = ($browserArgs -join ' '); PassThru = $true; RedirectStandardError = $errLog; RedirectStandardOutput = $outLog }
    if ($onWindows) { $sp.WindowStyle = 'Hidden' }
    $proc = Start-Process @sp
    if (-not $proc.WaitForExit($TimeoutSec * 1000)) {
        try { $proc.Kill() } catch { }
        throw "Timed out after $TimeoutSec s: the browser was stopped and no PDF is guaranteed."
    }
} finally {
    Start-Sleep -Milliseconds 600
    $left = Stop-Leftovers $tag
    for ($i = 0; $i -lt 10 -and (Test-Path -LiteralPath $tmpProfile); $i++) {
        try { Remove-Item -LiteralPath $tmpProfile -Recurse -Force -ErrorAction Stop } catch { Start-Sleep -Milliseconds 400 }
    }
    $console = @()
    if (Test-Path -LiteralPath $errLog) {
        # Keep only messages from the course page itself (its scripts live in file:// URLs).
        $console = @(Get-Content -LiteralPath $errLog -Encoding UTF8 | Where-Object { ($_ -match 'CONSOLE' -and $_ -match 'source: file:') -or $_ -match 'Uncaught' } |
            ForEach-Object { ($_ -replace '^\[[^\]]*\]\s*', '') -replace ', source: .*$', '' })
    }
    Remove-Item -LiteralPath $errLog, $outLog -Force -ErrorAction SilentlyContinue
}

if (-not (Test-Path -LiteralPath $pdfPath) -or (Get-Item -LiteralPath $pdfPath).Length -eq 0) {
    throw "The browser exited but no PDF was written: $pdfPath"
}
$bytes = [IO.File]::ReadAllBytes($pdfPath)
$raw = [Text.Encoding]::GetEncoding(28591).GetString($bytes)
$links = @([regex]::Matches($raw, '/URI\s*\(([^)]*)\)') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique).Count
$pages = @([regex]::Matches($raw, '/Type\s*/Page(?![a-zA-Z])')).Count
if ($pages -eq 0) {
    $counts = @([regex]::Matches($raw, '/Type\s*/Pages\b[^>]*?/Count\s+(\d+)') | ForEach-Object { [int]$_.Groups[1].Value })
    if ($counts.Count) { $pages = ($counts | Measure-Object -Maximum).Maximum } else { $pages = '?' }
}
$name = [IO.Path]::GetFileNameWithoutExtension($Browser)
'OK  {0} | pages: {1} | external links: {2} | size: {3} KB | {4} {5:N1} s' -f $pdfPath, $pages, $links, [Math]::Round($bytes.Length / 1KB), $name, $sw.Elapsed.TotalSeconds
foreach ($line in $console) { 'console: ' + $line }
if ($left -gt 0) { "cleanup: stopped $left leftover browser process(es)" }
if (Test-Path -LiteralPath $tmpProfile) { "cleanup: could not delete the temporary profile $tmpProfile (delete it by hand)" }
