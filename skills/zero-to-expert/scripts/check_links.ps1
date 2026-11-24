<#
.SYNOPSIS
  Checks every link of a course before it is shared. Read-only.

.DESCRIPTION
  Takes the course HTML (every href="http..." plus bare URLs in td.url cells) or a text file
  with one URL per line. For each URL: HTTP status, content type and a verdict.
  - A ".pdf" URL that answers text/html is reported as CHECK (probable soft 404: the file moved).
  - YouTube links are checked through the public oEmbed endpoint: a deleted or private video
    answers 404/401 there, while its watch page still answers 200.
  - 403/429 are reported as CHECK: some sites block scripts but work in a browser.
  Bounded: -MaxTime seconds per URL (default 20). Works with Windows PowerShell 5.1 and PowerShell 7.

.EXAMPLE
  .\check_links.ps1 -Html .\course.html
  .\check_links.ps1 -List .\urls.txt
#>
param([string]$Html, [string]$List, [int]$MaxTime = 20)
$ErrorActionPreference = 'Stop'
if (-not $Html -and -not $List) { throw 'Give -Html course.html or -List urls.txt' }
$onWindows = ($env:OS -eq 'Windows_NT')
$curl = if ($onWindows) { 'curl.exe' } else { 'curl' }
$sink = if ($onWindows) { 'NUL' } else { '/dev/null' }
$ua = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0 Safari/537.36'

$urls = New-Object System.Collections.Generic.List[string]
if ($Html) {
    $t = [IO.File]::ReadAllText((Resolve-Path -LiteralPath $Html).Path, [Text.Encoding]::UTF8)
    foreach ($m in [regex]::Matches($t, 'href\s*=\s*"(https?://[^"]+)"')) { $urls.Add([Net.WebUtility]::HtmlDecode($m.Groups[1].Value)) }
    foreach ($m in [regex]::Matches($t, '<td[^>]*class="[^"]*\burl\b[^"]*"[^>]*>\s*(https?://[^<\s]+)')) { $urls.Add([Net.WebUtility]::HtmlDecode($m.Groups[1].Value)) }
}
if ($List) {
    foreach ($line in Get-Content -LiteralPath $List -Encoding UTF8) { if ($line.Trim() -match '^https?://') { $urls.Add($line.Trim()) } }
}
$todo = @($urls | Where-Object { $_ -notmatch '\[|\]' } | Sort-Object -Unique)
if ($todo.Count -eq 0) { 'No http(s) link found.'; return }

$bad = 0; $i = 0
foreach ($u in $todo) {
    $i++
    $target = $u; $youtube = $false
    if ($u -match '^https?://(www\.|m\.)?(youtube\.com/(watch|shorts|live)|youtu\.be/)') {
        $youtube = $true
        $target = 'https://www.youtube.com/oembed?format=json&url=' + [Uri]::EscapeDataString($u)
    }
    $r = & $curl -s -o $sink -L --max-time $MaxTime --connect-timeout 10 -A $ua -H 'Accept-Language: fr-FR,fr;q=0.9,en;q=0.8' -w '%{http_code}|%{content_type}' $target
    $parts = "$r" -split '\|', 2
    $code = $parts[0]; $ctype = if ($parts.Count -gt 1) { ($parts[1] -replace ';.*$', '').Trim() } else { '' }
    $verdict = 'OK'
    if ($code -notmatch '^\d{3}$' -or $code -eq '000') { $verdict = 'FAIL (no answer)' }
    elseif ([int]$code -ge 400) {
        if ($youtube -and $code -eq '401') { $verdict = 'OK (video exists, embedding disabled)' }
        elseif ($code -eq '403' -or $code -eq '429') { $verdict = "CHECK ($code - the site may block scripts: open it in a browser)" }
        else { $verdict = "FAIL ($code)" }
    }
    elseif ($u -match '\.pdf($|[?#])' -and $ctype -match 'text/html') { $verdict = 'CHECK (pdf link answers html: moved file?)' }
    if ($verdict -notlike 'OK*') { $bad++ }
    '{0,3} {1} | {2} | {3} | {4}' -f $i, $code, $ctype, $verdict, $u
}
'--- {0} links: {1} OK, {2} to fix or check' -f $todo.Count, ($todo.Count - $bad), $bad
