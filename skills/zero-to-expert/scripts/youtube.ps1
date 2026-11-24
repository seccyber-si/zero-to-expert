<#
.SYNOPSIS
  Finds and checks YouTube videos for a course, without a browser and without an API key. Read-only.

.DESCRIPTION
  -Search "words"  : top results, one line each:  id | title | channel | published | duration | views
                     (titles can be machine-translated by YouTube into -Lang: confirm them with -Details)
  -Details id,id   : exact title, channel, publish date, duration, views and the start of the description
  Reads the public pages the way a browser does (consent cookie included). If YouTube changes its
  page format the parsing can break: then use a browser tool, or open the pages.
  Video IDs that start with "-" must be quoted:  -Details '-AbC123xyz0'
  -TempDir <folder> keeps the short-lived page files in your work folder instead of the system TEMP.
  Works with Windows PowerShell 5.1 and PowerShell 7.

.EXAMPLE
  .\youtube.ps1 -Search "proxmox backup server tutorial" -Max 8
  .\youtube.ps1 -Search "sauvegarde 3-2-1 explication" -Lang fr
  .\youtube.ps1 -Details 'dQw4w9WgXcQ','-AbC123xyz0'
#>
param([string]$Search, [string[]]$Details, [int]$Max = 10, [string]$Lang = 'en', [int]$DescMax = 400,
      [string]$TempDir = [IO.Path]::GetTempPath())   # each page is saved there for a moment, then deleted
$ErrorActionPreference = 'Stop'
$TempDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($TempDir)   # .NET file calls ignore cd
if (-not $Search -and -not $Details) { throw 'Give -Search "words" or -Details id1,id2' }
$onWindows = ($env:OS -eq 'Windows_NT')
$curl = if ($onWindows) { 'curl.exe' } else { 'curl' }
$ua = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0 Safari/537.36'
$JS = '"((?:[^"\\]|\\.)*)"'   # a JSON string

function Get-Page([string]$url) {
    $tmp = Join-Path $TempDir ('yt-' + [guid]::NewGuid().ToString('N') + '.html')
    try {
        & $curl -s -L --max-time 25 -A $ua -H "Accept-Language: $Lang" -b 'SOCS=CAI; CONSENT=YES+cb' -o $tmp $url
        if (Test-Path -LiteralPath $tmp) { return [IO.File]::ReadAllText($tmp, [Text.Encoding]::UTF8) }
        return ''
    } finally { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }
}
function U([string]$s) { try { [regex]::Unescape($s) } catch { $s } }
function Clean([string]$s) { ((U $s) -replace '[\r\n]+', ' ' -replace '\|', '/').Trim() }

if ($Search) {
    $html = Get-Page ('https://www.youtube.com/results?hl=' + $Lang + '&search_query=' + [Uri]::EscapeDataString($Search))
    $hits = @([regex]::Matches($html, '"videoRenderer":\{"videoId":"([\w-]{11})"'))
    $seen = @{}; $n = 0
    for ($k = 0; $k -lt $hits.Count -and $n -lt $Max; $k++) {
        $id = $hits[$k].Groups[1].Value
        if ($seen.ContainsKey($id)) { continue }
        $seen[$id] = 1
        $end = if ($k + 1 -lt $hits.Count) { $hits[$k + 1].Index } else { [Math]::Min($html.Length, $hits[$k].Index + 12000) }
        $seg = $html.Substring($hits[$k].Index, [Math]::Min($end - $hits[$k].Index, 12000))
        $title = Clean ([regex]::Match($seg, '"title":\{"runs":\[\{"text":' + $JS).Groups[1].Value)
        $chan = Clean ([regex]::Match($seg, '"(?:ownerText|longBylineText)":\{"runs":\[\{"text":' + $JS).Groups[1].Value)
        $len = [regex]::Match($seg, '(?s)"lengthText":\{.{0,300}?"simpleText":"([^"]+)"').Groups[1].Value
        $pub = Clean ([regex]::Match($seg, '"publishedTimeText":\{"simpleText":' + $JS).Groups[1].Value)
        $views = Clean ([regex]::Match($seg, '"viewCountText":\{"simpleText":' + $JS).Groups[1].Value)
        '{0} | {1} | {2} | {3} | {4} | {5}' -f $id, $title, $chan, $pub, $len, $views
        $n++
    }
    if ($n -eq 0) { 'No result parsed (consent page, network, or a new YouTube page format). Use a browser tool or open the results page.' }
    else { "note: YouTube can show titles machine-translated into '$Lang'. Take the exact title and the video's language from -Details." }
}

foreach ($id in $Details) {
    $id = $id.Trim()
    if ($id -notmatch '^[\w-]{11}$') { "=== $id | not a YouTube video id (11 characters)"; continue }
    $html = Get-Page "https://www.youtube.com/watch?v=$id&hl=$Lang"
    $title = Clean ([regex]::Match($html, '"videoDetails":\{"videoId":"[^"]+","title":' + $JS).Groups[1].Value)
    if (-not $title) { "=== $id | NOT FOUND (deleted, private, or page not parsed)"; continue }
    $sec = [regex]::Match($html, '"lengthSeconds":"(\d+)"').Groups[1].Value
    $auth = Clean ([regex]::Match($html, '"author":' + $JS).Groups[1].Value)
    $views = [regex]::Match($html, '"viewCount":"(\d+)"').Groups[1].Value
    $pub = [regex]::Match($html, '"publishDate":"([^"]+)"').Groups[1].Value
    if ($pub.Length -ge 10) { $pub = $pub.Substring(0, 10) }
    $desc = U ([regex]::Match($html, '"shortDescription":' + $JS).Groups[1].Value)
    $dur = if ($sec) { '{0}:{1:D2}' -f [int][Math]::Floor([int]$sec / 60), ([int]$sec % 60) } else { '?' }
    '=== {0} | {1} | {2} | {3} | {4} | {5} views' -f $id, $title, $auth, $pub, $dur, $views
    if ($desc) {
        $d = ($desc -replace '\s+', ' ').Trim()
        if ($d.Length -gt $DescMax) { $d = $d.Substring(0, $DescMax) + '...' }
        '    ' + $d
    }
}
