<#
.SYNOPSIS
  Renders PDF pages to PNG with the PDF engine built into Windows 10/11 (Windows.Data.Pdf), so you can
  look at the real pages before delivering. Nothing to install. Windows PowerShell 5.1 only.
  -Sheet draws the pages as thumbnails on contact sheets (12 per image): the quickest way to spot nearly
  empty pages, boxes cut by a page break and misplaced figures. Then open single pages at full size.
  The file names are printed once everything is rendered, so piping into Select-Object is safe.
  On macOS/Linux use instead:  pdftoppm -png -r 80 -f 3 -l 3 course.pdf build/page
  (contact sheet, if ImageMagick is installed: pdftoppm -png -r 20 course.pdf build/t; montage build/t-*.png -tile 4x -geometry +8+8 build/sheet.png)

.EXAMPLE
  .\pdf2png.ps1 -Pdf .\course.pdf -OutPrefix .\build\p- -Sheet            # build\p-sheet-1.png, p-sheet-2.png...
  .\pdf2png.ps1 -Pdf .\course.pdf -OutPrefix .\build\page- -Pages 1,2,7   # build\page-01.png, page-02.png, page-07.png
  .\pdf2png.ps1 -Pdf .\course.pdf -OutPrefix .\build\page-                # every page
#>
param(
    [Parameter(Mandatory = $true)][string]$Pdf,
    [Parameter(Mandatory = $true)][string]$OutPrefix,
    [int[]]$Pages,
    [int]$Width = 1300,
    [switch]$Sheet
)
$ErrorActionPreference = 'Stop'
$Pdf = (Resolve-Path -LiteralPath $Pdf).Path
$OutPrefix = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutPrefix)   # relative to the current location (GetFullPath ignores cd)
$dir = Split-Path -Parent $OutPrefix
if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }

Add-Type -AssemblyName System.Runtime.WindowsRuntime
[void][Windows.Data.Pdf.PdfDocument, Windows.Data.Pdf, ContentType = WindowsRuntime]
[void][Windows.Storage.StorageFile, Windows.Storage, ContentType = WindowsRuntime]
[void][Windows.Storage.Streams.InMemoryRandomAccessStream, Windows.Storage.Streams, ContentType = WindowsRuntime]
$asTask = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' } | Select-Object -First 1
$asTaskAction = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncAction' } | Select-Object -First 1
function Await($op, [Type]$t) { $task = $asTask.MakeGenericMethod($t).Invoke($null, @($op)); $task.Wait(); return $task.Result }

# One page as PNG bytes in a MemoryStream (position 0), $w pixels wide.
function Render-Page([int]$n, [int]$w) {
    $page = $doc.GetPage($n - 1)
    $stream = New-Object Windows.Storage.Streams.InMemoryRandomAccessStream
    $opt = New-Object Windows.Data.Pdf.PdfPageRenderOptions
    $opt.DestinationWidth = $w
    $t = $asTaskAction.Invoke($null, @($page.RenderToStreamAsync($stream, $opt))); $t.Wait()
    $net = [System.IO.WindowsRuntimeStreamExtensions]::AsStreamForRead($stream.GetInputStreamAt(0))
    $ms = New-Object System.IO.MemoryStream
    $net.CopyTo($ms); $net.Dispose(); $stream.Dispose(); $page.Dispose()
    $ms.Position = 0
    return $ms
}

$file = Await ([Windows.Storage.StorageFile]::GetFileFromPathAsync($Pdf)) ([Windows.Storage.StorageFile])
$doc = Await ([Windows.Data.Pdf.PdfDocument]::LoadFromFileAsync($file)) ([Windows.Data.Pdf.PdfDocument])
if (-not $Pages) { $Pages = 1..$doc.PageCount }
$list = @($Pages | Where-Object { $_ -ge 1 -and $_ -le $doc.PageCount })
$made = New-Object System.Collections.Generic.List[string]

if ($Sheet) {
    Add-Type -AssemblyName System.Drawing
    $cw = 300; $ch = 424; $gap = 14; $lab = 20; $cols = 4; $per = 12
    $font = New-Object System.Drawing.Font('Segoe UI', 13, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(51, 65, 85))
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(148, 163, 184))
    $fmt = New-Object System.Drawing.StringFormat
    $fmt.Alignment = [System.Drawing.StringAlignment]::Center
    for ($s = 0; $s * $per -lt $list.Count; $s++) {
        $chunk = @($list[($s * $per)..([Math]::Min($list.Count, ($s + 1) * $per) - 1)])
        $nr = [int][Math]::Ceiling($chunk.Count / $cols)
        $bmp = New-Object System.Drawing.Bitmap -ArgumentList ([int]($cols * $cw + ($cols + 1) * $gap)), ([int]($nr * ($ch + $lab) + ($nr + 1) * $gap))
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.Clear([System.Drawing.Color]::FromArgb(226, 232, 240))
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        for ($i = 0; $i -lt $chunk.Count; $i++) {
            $n = $chunk[$i]
            $x = $gap + ($i % $cols) * ($cw + $gap)
            $y = $gap + [Math]::Floor($i / $cols) * ($ch + $lab + $gap)
            $ms = Render-Page $n $cw
            $img = [System.Drawing.Image]::FromStream($ms)
            $k = [Math]::Min(1.0, [Math]::Min($cw / $img.Width, $ch / $img.Height))
            $w = [int]($img.Width * $k); $h = [int]($img.Height * $k)
            $g.DrawImage($img, [int]$x, [int]$y, $w, $h)
            $g.DrawRectangle($pen, [int]$x, [int]$y, $w - 1, $h - 1)
            $g.DrawString("$n", $font, $brush, (New-Object System.Drawing.RectangleF([single]$x, [single]($y + $h + 2), [single]$cw, [single]$lab)), $fmt)
            $img.Dispose(); $ms.Dispose()
        }
        $out = '{0}sheet-{1}.png' -f $OutPrefix, ($s + 1)
        $bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
        $g.Dispose(); $bmp.Dispose()
        $made.Add($out)
    }
    $font.Dispose(); $brush.Dispose(); $pen.Dispose(); $fmt.Dispose()
} else {
    foreach ($n in $list) {
        $ms = Render-Page $n $Width
        $out = '{0}{1:D2}.png' -f $OutPrefix, $n
        [System.IO.File]::WriteAllBytes($out, $ms.ToArray()); $ms.Dispose()
        $made.Add($out)
    }
}
"pages: $($doc.PageCount)"
$made
