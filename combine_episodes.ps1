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

# 2. Smart Episode Sorting
Write-Host "`nSorting episodes automatically..." -ForegroundColor Cyan

$sortedFiles = $selectedFiles | Sort-Object {

    $name = [System.IO.Path]::GetFileNameWithoutExtension($_)

    # Detect patterns like:
    # ep01, ep1, episode02, e03, S01E02 etc.
    if ($name -match '(?i)(?:ep|episode|e)[\s\-_]?(\d{1,4})') {
        [int]$matches[1]
    }

    # Detect S01E02 style
    elseif ($name -match '(?i)s\d+e(\d{1,4})') {
        [int]$matches[1]
    }

    # Fallback: detect any number
    elseif ($name -match '(\d{1,4})') {
        [int]$matches[1]
    }

    # No number found
    else {
        999999
    }
}

# 3. Show Detected Order
Write-Host "`nDetected Episode Order:" -ForegroundColor Yellow

$counter = 1

foreach ($file in $sortedFiles) {

    $fileName = [System.IO.Path]::GetFileName($file)

    Write-Host "$counter. $fileName"

    $counter++
}

# 4. Resolution Check
Write-Host "`nChecking compatibility..." -ForegroundColor Cyan

$firstFile = $sortedFiles[0]

$resCmd = "ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 `"$firstFile`""

$targetRes = Invoke-Expression $resCmd

foreach ($file in $sortedFiles) {

    $currentRes = Invoke-Expression "ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 `"$file`""

    if ($currentRes -ne $targetRes) {

        Write-Host "`nERROR: Resolution Mismatch!" -ForegroundColor Red
        Write-Host "$([System.IO.Path]::GetFileName($file)) = $currentRes"
        Write-Host "Expected = $targetRes"

        pause
        exit
    }
}

# 5. Create mylist.txt
$listPath = Join-Path (Split-Path $firstFile) "mylist.txt"

$sortedFiles | ForEach-Object {

    # Escape single quotes
    $escapedPath = $_ -replace "'", "''"

    "file '$escapedPath'"

} | Out-File -FilePath $listPath -Encoding ascii

# 6. Merge Videos
Write-Host "`nMerging episodes into one master file..." -ForegroundColor Green

$outputName = Join-Path (Split-Path $firstFile) "Full_Series_Combined.mkv"

$ffmpegArgs = "-f concat -safe 0 -i `"$listPath`" -map 0 -c copy `"$outputName`" -y"

Start-Process ffmpeg -ArgumentList $ffmpegArgs -Wait -NoNewWindow

# 7. Cleanup
if (Test-Path $listPath) {
    Remove-Item $listPath
}

# 8. Final Status
if (Test-Path $outputName) {

    Write-Host "`nSUCCESS: Full series created successfully!" -ForegroundColor Green
    Write-Host "Saved at:"
    Write-Host $outputName -ForegroundColor Yellow

} else {

    Write-Host "`nERROR: FFmpeg failed." -ForegroundColor Red
}

Write-Host "`nPress Enter to exit..."
$null = Read-Host