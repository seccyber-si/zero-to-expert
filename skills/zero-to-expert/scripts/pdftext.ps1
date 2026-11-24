<#
.SYNOPSIS
  Reads the text of PDF pages with the OCR engine built into Windows 10/11 (Windows.Media.Ocr), so you can
  find the exact sentence and page of a fact in a source PDF. Nothing to install. Windows PowerShell 5.1 only.
  Each page is rendered as an image and then read: it also works on scanned PDFs. About 1 second per page.
  -Find ignores case, accents and line breaks, and prints each match with its page and some context.
  On macOS/Linux use instead:  pdftotext -layout source.pdf - | grep -n -i "words"

.EXAMPLE
  .\pdftext.ps1 -Pdf .\build\dl\guide.pdf -Find "ne vaut pas attestation"     # p. 9: ...ne vaut pas attestation de...
  .\pdftext.ps1 -Pdf .\build\dl\guide.pdf -Pages 1,2                          # full text of pages 1 and 2
  .\pdftext.ps1 -Pdf .\build\dl\guide.pdf -Find "backup" -Lang en -Pages (1..20)
#>
param(
    [Parameter(Mandatory = $true)][string]$Pdf,
    [string]$Find,
    [int[]]$Pages,
    [string]$Lang,          # OCR language such as fr or en; default: the languages of the Windows user profile
    [int]$Width = 1800,     # render width in pixels; larger reads small print better but is slower
    [int]$Context = 200     # characters of context shown around each match
)
$ErrorActionPreference = 'Stop'
$Pdf = (Resolve-Path -LiteralPath $Pdf).Path

Add-Type -AssemblyName System.Runtime.WindowsRuntime
[void][Windows.Data.Pdf.PdfDocument, Windows.Data.Pdf, ContentType = WindowsRuntime]
[void][Windows.Storage.StorageFile, Windows.Storage, ContentType = WindowsRuntime]
[void][Windows.Storage.Streams.InMemoryRandomAccessStream, Windows.Storage.Streams, ContentType = WindowsRuntime]
[void][Windows.Media.Ocr.OcrEngine, Windows.Foundation, ContentType = WindowsRuntime]
[void][Windows.Graphics.Imaging.BitmapDecoder, Windows.Graphics, ContentType = WindowsRuntime]
[void][Windows.Graphics.Imaging.SoftwareBitmap, Windows.Graphics, ContentType = WindowsRuntime]
[void][Windows.Globalization.Language, Windows.Globalization, ContentType = WindowsRuntime]
$asTask = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' } | Select-Object -First 1
$asTaskAction = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncAction' } | Select-Object -First 1
function Await($op, [Type]$t) { $task = $asTask.MakeGenericMethod($t).Invoke($null, @($op)); $task.Wait(); return $task.Result }

$installed = ([Windows.Media.Ocr.OcrEngine]::AvailableRecognizerLanguages | ForEach-Object { $_.LanguageTag }) -join ', '
if ($Lang) {
    $l = New-Object Windows.Globalization.Language $Lang
    if (-not [Windows.Media.Ocr.OcrEngine]::IsLanguageSupported($l)) { throw "OCR language '$Lang' is not installed on this PC. Installed: $installed" }
    $ocr = [Windows.Media.Ocr.OcrEngine]::TryCreateFromLanguage($l)
} else {
    $ocr = [Windows.Media.Ocr.OcrEngine]::TryCreateFromUserProfileLanguages()
}
if (-not $ocr) { throw 'No OCR language is installed (Windows Settings > Time & language > Language: add one with "Optical character recognition").' }

# Text of one page: rendered to an image in memory, then read by OCR, one string per line.
function Read-Page([int]$n) {
    $page = $doc.GetPage($n - 1)
    $stream = New-Object Windows.Storage.Streams.InMemoryRandomAccessStream
    $opt = New-Object Windows.Data.Pdf.PdfPageRenderOptions
    $opt.DestinationWidth = [Math]::Min($Width, [Windows.Media.Ocr.OcrEngine]::MaxImageDimension)
    $t = $asTaskAction.Invoke($null, @($page.RenderToStreamAsync($stream, $opt))); $t.Wait()
    $dec = Await ([Windows.Graphics.Imaging.BitmapDecoder]::CreateAsync($stream)) ([Windows.Graphics.Imaging.BitmapDecoder])
    $bmp = Await ($dec.GetSoftwareBitmapAsync()) ([Windows.Graphics.Imaging.SoftwareBitmap])
    $res = Await ($ocr.RecognizeAsync($bmp)) ([Windows.Media.Ocr.OcrResult])
    $bmp.Dispose(); $stream.Dispose(); $page.Dispose()
    return @($res.Lines | ForEach-Object { $_.Text })
}
# Same length in, same length out: curly quotes and dashes become plain ones, so positions still match.
# The classes are built from code points so that this file stays pure ASCII: Windows PowerShell 5.1 reads
# a UTF-8 file without BOM as ANSI, which would turn literal curly quotes into other characters.
$reApos = '[' + (-join [char[]](0x2018, 0x2019, 0x02BC, 0x00B4, 0x0060)) + ']'
$reQuot = '[' + (-join [char[]](0x201C, 0x201D, 0x00AB, 0x00BB)) + ']'
$reDash = '[' + [char]0x2010 + '-' + [char]0x2015 + ']'
function Plain([string]$s) { $s -replace $reApos, "'" -replace $reQuot, '"' -replace $reDash, '-' }

$file = Await ([Windows.Storage.StorageFile]::GetFileFromPathAsync($Pdf)) ([Windows.Storage.StorageFile])
$doc = Await ([Windows.Data.Pdf.PdfDocument]::LoadFromFileAsync($file)) ([Windows.Data.Pdf.PdfDocument])
if (-not $Pages) { $Pages = 1..$doc.PageCount }
$list = @($Pages | Where-Object { $_ -ge 1 -and $_ -le $doc.PageCount })
$cmp = [Globalization.CultureInfo]::InvariantCulture.CompareInfo
$how = [Globalization.CompareOptions]::IgnoreCase -bor [Globalization.CompareOptions]::IgnoreNonSpace
$needle = if ($Find) { Plain (($Find -replace '\s+', ' ').Trim()) } else { '' }
$hits = 0

foreach ($n in $list) {
    $lines = Read-Page $n
    if (-not $needle) { "=== page $n"; $lines; continue }
    # One string per page: words cut by a line-end hyphen are joined again, so a sentence can be found across lines.
    $text = Plain ((($lines -join ' ') -replace '(\p{Ll})- (\p{Ll})', '$1$2' -replace '\s+', ' ').Trim())
    $i = $cmp.IndexOf($text, $needle, $how)
    while ($i -ge 0) {
        $a = [Math]::Max(0, $i - [int]($Context / 2)); $b = [Math]::Min($text.Length, $i + $needle.Length + [int]($Context / 2))
        'p. {0}: ...{1}...' -f $n, $text.Substring($a, $b - $a)
        $hits++
        $i = if ($i + 1 -lt $text.Length) { $cmp.IndexOf($text, $needle, $i + 1, $how) } else { -1 }
    }
}
if ($needle) { 'found: {0} match(es) in {1} page(s) read by OCR ({2})' -f $hits, $list.Count, $ocr.RecognizerLanguage.LanguageTag }
