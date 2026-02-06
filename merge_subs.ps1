# 1. Ask for Method ONCE at the start
Write-Host "--- Subtitle Session Started ---" -ForegroundColor Cyan
Write-Host "1. MUX (Instant, high quality, supports fancy styles)"
Write-Host "2. BURN (Slow, permanent, text is part of video)"
$method = Read-Host "Choose your method (1 or 2)"

do {
    # 2. Select the Video File
    Add-Type -AssemblyName System.Windows.Forms
    $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog
    $FileBrowser.Title = "Select Movie/Video file"
    $FileBrowser.Filter = "Video Files (*.mp4;*.mkv;*.avi)|*.mp4;*.mkv;*.avi"
    if ($FileBrowser.ShowDialog() -ne "OK") { break }
    $videoPath = $FileBrowser.FileName

    # 3. Select the Subtitle File
    $SubBrowser = New-Object System.Windows.Forms.OpenFileDialog
    $SubBrowser.Title = "Select Subtitle file"
    $SubBrowser.Filter = "Subtitle Files (*.srt;*.vtt;*.ass;*.ssa)|*.srt;*.vtt;*.ass;*.ssa"
    if ($SubBrowser.ShowDialog() -ne "OK") { break }
    $subPath = $SubBrowser.FileName

    # 4. Setup Paths
    $dir = Split-Path -Parent $videoPath
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($videoPath)
    $escapedSubPath = $subPath -replace '\\', '/' -replace ':', '\:'

    if ($method -eq "1") {
        # MUXING: Using .mkv to fix the formatting tag error (\{\}=6)
        $outputPath = Join-Path $dir "$($baseName)_muxed.mkv"
        Write-Host "Muxing into MKV container to preserve subtitle styles..." -ForegroundColor Green
        $ffmpegArgs = "-i `"$videoPath`" -i `"$subPath`" -c copy `"$outputPath`" -y"
    } else {
        # BURNING: Still uses .mp4 for universal compatibility
        $outputPath = Join-Path $dir "$($baseName)_burned.mp4"
        Write-Host "Burning subtitles into frames... please wait." -ForegroundColor Yellow
        $ffmpegArgs = "-i `"$videoPath`" -vf `"subtitles='$escapedSubPath'`" -c:v libx264 -crf 20 -c:a copy `"$outputPath`" -y"
    }

    # 5. Run FFmpeg
    Write-Host "`nProcessing: $baseName..." -ForegroundColor Yellow
    Start-Process ffmpeg -ArgumentList $ffmpegArgs -Wait -NoNewWindow
    
    if (Test-Path $outputPath) {
        Write-Host "SUCCESS: Saved as $(Split-Path $outputPath -Leaf)" -ForegroundColor Green
    } else {
        Write-Host "ERROR: File was not created. Check terminal for errors." -ForegroundColor Red
    }
    Write-Host "------------------------------------------------"

    # 6. Loop Logic
    Write-Host "Press ENTER to select the next file, or close this window to exit." -ForegroundColor Cyan
    $null = Read-Host 
} while ($true)