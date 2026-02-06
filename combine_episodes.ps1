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
    pause; exit
}

# 2. Resolution Check
Write-Host "Checking compatibility..." -ForegroundColor Cyan
$firstFile = $selectedFiles[0]
$resCmd = "ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 `"$firstFile`""
$targetRes = Invoke-Expression $resCmd

foreach ($file in $selectedFiles) {
    $currentRes = Invoke-Expression "ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 `"$file`""
    if ($currentRes -ne $targetRes) {
        Write-Host "ERROR: Resolution Mismatch! ($currentRes vs $targetRes)" -ForegroundColor Red
        pause; exit
    }
}

# 3. Create mylist.txt (FIXED: ASCII encoding for FFmpeg compatibility)
$listPath = Join-Path (Split-Path $firstFile) "mylist.txt"
$selectedFiles | ForEach-Object { "file '$($_)'" } | Out-File -FilePath $listPath -Encoding ascii

# 4. Perform Merge (Outputting as .mkv)
Write-Host "Merging episodes into one master file..." -ForegroundColor Green
$outputName = Join-Path (Split-Path $firstFile) "Full_Series_Combined.mkv"

$ffmpegArgs = "-f concat -safe 0 -i `"$listPath`" -map 0 -c copy `"$outputName`" -y"
Start-Process ffmpeg -ArgumentList $ffmpegArgs -Wait -NoNewWindow

# 5. Verification & Cleanup
if (Test-Path $listPath) { Remove-Item $listPath }

if (Test-Path $outputName) {
    Write-Host "`nSUCCESS: Full series created at: $outputName" -ForegroundColor Green
} else {
    Write-Host "`nERROR: FFmpeg failed." -ForegroundColor Red
}

Write-Host "Press Enter to exit..."
$null = Read-Host