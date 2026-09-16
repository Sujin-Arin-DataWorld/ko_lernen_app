<#
Q-S2: Windows built-in OCR (Windows.Media.Ocr, ko-KR recognizer) batch worker.

Reads a JSON manifest of {"page": <int>, "png": "<absolute path>"} entries,
runs the WinRT Windows.Media.Ocr engine (language "ko") on each PNG, and
writes one raw result JSON per page to -OutDir as "<page>.raw.json".

This script does NOT compute confidence: Windows.Media.Ocr's OcrWord/OcrLine
types expose only Text + BoundingRect, no per-word confidence score (verified
by reflection against Windows.Media.Ocr.OcrWord / OcrLine / OcrResult on this
machine -- there is no confidence property in this API surface at all). The
Python driver (ocr_sejong_pages.py) computes a documented *proxy* quality
score from the recognized character distribution; it is explicitly labeled
as a proxy, never presented as an engine-native confidence value.

Usage:
    powershell -NoProfile -ExecutionPolicy Bypass -File ocr_batch.ps1 `
        -ManifestPath <path to manifest.json> -OutDir <dir>
#>
param(
    [Parameter(Mandatory=$true)][string]$ManifestPath,
    [Parameter(Mandatory=$true)][string]$OutDir
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Runtime.WindowsRuntime | Out-Null

[Windows.Media.Ocr.OcrEngine,Windows.Foundation,ContentType=WindowsRuntime] | Out-Null
[Windows.Storage.StorageFile,Windows.Storage,ContentType=WindowsRuntime] | Out-Null
[Windows.Graphics.Imaging.BitmapDecoder,Windows.Graphics,ContentType=WindowsRuntime] | Out-Null
[Windows.Graphics.Imaging.SoftwareBitmap,Windows.Graphics,ContentType=WindowsRuntime] | Out-Null
[Windows.Globalization.Language,Windows.Globalization,ContentType=WindowsRuntime] | Out-Null

Function Await($WinRtTask, $ResultType) {
    $asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
        $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1'
    })[0].MakeGenericMethod($ResultType)
    $netTask = $asTaskGeneric.Invoke($null, @($WinRtTask))
    $netTask.Wait(-1) | Out-Null
    return $netTask.Result
}

$koLang = New-Object Windows.Globalization.Language -ArgumentList "ko"
$ocrEngine = [Windows.Media.Ocr.OcrEngine]::TryCreateFromLanguage($koLang)
if ($null -eq $ocrEngine) {
    Write-Error "Korean OCR engine not available on this machine"
    exit 1
}

if (!(Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }

$manifest = Get-Content -Raw -Path $ManifestPath -Encoding UTF8 | ConvertFrom-Json
$total = $manifest.Count
$ok = 0
$failed = 0

foreach ($entry in $manifest) {
    $page = $entry.page
    $png = $entry.png
    $outPath = Join-Path $OutDir "$page.raw.json"
    try {
        $file = Await ([Windows.Storage.StorageFile]::GetFileFromPathAsync($png)) ([Windows.Storage.StorageFile])
        $stream = Await ($file.OpenAsync([Windows.Storage.FileAccessMode]::Read)) ([Windows.Storage.Streams.IRandomAccessStream])
        $decoder = Await ([Windows.Graphics.Imaging.BitmapDecoder]::CreateAsync($stream)) ([Windows.Graphics.Imaging.BitmapDecoder])
        $bitmap = Await ($decoder.GetSoftwareBitmapAsync()) ([Windows.Graphics.Imaging.SoftwareBitmap])
        $bitmap2 = [Windows.Graphics.Imaging.SoftwareBitmap]::Convert($bitmap, [Windows.Graphics.Imaging.BitmapPixelFormat]::Bgra8, [Windows.Graphics.Imaging.BitmapAlphaMode]::Premultiplied)

        $result = Await ($ocrEngine.RecognizeAsync($bitmap2)) ([Windows.Media.Ocr.OcrResult])

        $lines = @()
        foreach ($line in $result.Lines) {
            $words = @()
            foreach ($w in $line.Words) {
                $words += [PSCustomObject]@{
                    text = $w.Text
                    x = [math]::Round($w.BoundingRect.X, 1)
                    y = [math]::Round($w.BoundingRect.Y, 1)
                    w = [math]::Round($w.BoundingRect.Width, 1)
                    h = [math]::Round($w.BoundingRect.Height, 1)
                }
            }
            $lines += [PSCustomObject]@{
                text = $line.Text
                words = $words
            }
        }
        $out = [PSCustomObject]@{
            page = $page
            png = $png
            engine = "windows_media_ocr_ko"
            text_angle = $result.TextAngle
            image_width = $bitmap2.PixelWidth
            image_height = $bitmap2.PixelHeight
            text = $result.Text
            lines = $lines
        }
        ($out | ConvertTo-Json -Depth 10 -Compress) | Out-File -FilePath $outPath -Encoding UTF8
        $ok++

        $bitmap.Dispose()
        $bitmap2.Dispose()
        $stream.Dispose()
    } catch {
        $failed++
        $errOut = [PSCustomObject]@{
            page = $page
            png = $png
            engine = "windows_media_ocr_ko"
            error = $_.Exception.Message
            text = ""
            lines = @()
        }
        ($errOut | ConvertTo-Json -Depth 5 -Compress) | Out-File -FilePath $outPath -Encoding UTF8
    }
}

Write-Output "OCR_BATCH_DONE total=$total ok=$ok failed=$failed"
