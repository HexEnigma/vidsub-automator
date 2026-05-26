Add-Type -AssemblyName System.Windows.Forms

# 1. Select Multiple Video Files
$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog
$FileBrowser.Title = "Select muxed episodes to merge (Hold Ctrl)"
$FileBrowser.Filter = "Video Files (*.mp4;*.mkv)|*.mp4;*.mkv"
$FileBrowser.Multiselect = $true

$null = $FileBrowser.ShowDialog()

$selectedFiles = $FileBrowser.FileNames

if ($selectedFiles.Count -lt 2) {
    Write-Host "ERROR: Select at least 2 files!" -ForegroundColor Red
    pause
    exit
}

# 2. Smart Episode Sorting (UNCHANGED CORE LOGIC)
Write-Host "`nSorting episodes automatically..." -ForegroundColor Cyan

$sortedFiles = $selectedFiles | Sort-Object {

    $name = [System.IO.Path]::GetFileNameWithoutExtension($_)

    if ($name -match '(?i)(?:ep|episode|e)[\s\-_]?(\d{1,4})') {
        [int]$matches[1]
    }
    elseif ($name -match '(?i)s\d+e(\d{1,4})') {
        [int]$matches[1]
    }
    elseif ($name -match '(\d{1,4})') {
        [int]$matches[1]
    }
    else {
        999999
    }
}

# 3. Show Detected Order (UNCHANGED STYLE)
Write-Host "`nDetected Episode Order:" -ForegroundColor Yellow

$counter = 1
foreach ($file in $sortedFiles) {
    $fileName = [System.IO.Path]::GetFileName($file)
    Write-Host "$counter. $fileName"
    $counter++
}

# 4. Ask for intro/outro trimming
Write-Host "`nEnter intro duration (seconds to remove from START of each episode except EP1):"
[int]$introSec = Read-Host

Write-Host "Enter outro duration (seconds to remove from END of each episode except LAST EP):"
[int]$outroSec = Read-Host

# 5. Create temp folder for trimmed files
$tempDir = Join-Path (Split-Path $sortedFiles[0]) "temp_trim"
if (!(Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir | Out-Null
}

Write-Host "`nTrimming episodes..." -ForegroundColor Cyan

$trimmedFiles = @()

for ($i = 0; $i -lt $sortedFiles.Count; $i++) {

    $file = $sortedFiles[$i]
    $fileName = [System.IO.Path]::GetFileNameWithoutExtension($file)
    $ext = [System.IO.Path]::GetExtension($file)

    $outputFile = Join-Path $tempDir ("trim_" + $i + $ext)

    # Get duration
    $durationCmd = "ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 `"$file`""
    $duration = [double](Invoke-Expression $durationCmd)

    $start = 0
    $end = $duration

    # Skip intro for all except first episode
    if ($i -ne 0) {
        $start = $introSec
    }

    # Skip outro for all except last episode
    if ($i -ne ($sortedFiles.Count - 1)) {
        $end = $duration - $outroSec
    }

    $length = $end - $start

    if ($length -le 0) {
        Write-Host "ERROR: Invalid trim length for $fileName" -ForegroundColor Red
        pause
        exit
    }

    Write-Host "Trimming: $fileName"

    $ffmpegTrim = "ffmpeg -y -ss $start -i `"$file`" -t $length -c:v libx264 -c:a aac `"$outputFile`""
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c $ffmpegTrim" -Wait -NoNewWindow

    $trimmedFiles += $outputFile
}

# 6. Create concat list
$listPath = Join-Path $tempDir "mylist.txt"

$trimmedFiles | ForEach-Object {
    $escaped = $_ -replace "'", "''"
    "file '$escaped'"
} | Out-File -FilePath $listPath -Encoding ascii

# 7. Merge final output (lossless concat of trimmed parts)
Write-Host "`nMerging final video..." -ForegroundColor Green

$outputName = Join-Path (Split-Path $sortedFiles[0]) "Full_Series_Combined.mkv"

$ffmpegArgs = "-f concat -safe 0 -i `"$listPath`" -map 0 -c copy `"$outputName`" -y"
Start-Process ffmpeg -ArgumentList $ffmpegArgs -Wait -NoNewWindow

# 8. Cleanup
Remove-Item $tempDir -Recurse -Force

# 9. Final status
if (Test-Path $outputName) {
    Write-Host "`nSUCCESS: Full series created successfully!" -ForegroundColor Green
    Write-Host "Saved at: $outputName" -ForegroundColor Yellow
} else {
    Write-Host "`nERROR: FFmpeg failed." -ForegroundColor Red
}

Write-Host "`nPress Enter to exit..."
$null = Read-Host