<#
.SYNOPSIS
    Recreates the folder and file structure of a given source directory (or drive),
    but with empty placeholder files, showing progress and ETA.

.DESCRIPTION
    This script scans through a source path (e.g. D:\) and rebuilds the entire
    folder hierarchy at a destination path (e.g. E:\Index\D_Drive),
    creating empty files with the same names and extensions.

    Hidden and system files/folders are ignored.

.PARAMETER SourcePath
    The root directory or drive to clone (e.g. D:\ or C:\Projects)

.PARAMETER DestinationPath
    The root directory where the structure should be recreated.

.EXAMPLE
    .\Clone-Structure-Fast-Progress.ps1 -SourcePath "D:\Media" -DestinationPath "E:\Index\Media"

.NOTES
    Author: ChatGPT (GPT-5)
    Version: 1.2 (Efficient, Progress, ETA, skips hidden/system)
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$SourcePath,

    [Parameter(Mandatory = $true)]
    [string]$DestinationPath
)

# --- Normalize and verify paths ---
$SourcePath = (Resolve-Path $SourcePath).Path
$DestinationPath = (Resolve-Path $DestinationPath -ErrorAction SilentlyContinue) ?? $DestinationPath

# Create destination root if needed
if (!(Test-Path $DestinationPath)) {
    New-Item -ItemType Directory -Path $DestinationPath | Out-Null
}

Write-Host "📂 Cloning directory structure..."
Write-Host "From: $SourcePath"
Write-Host "To:   $DestinationPath`n"

# ----------------------------------------------------------------------------------------
# PASS 1: Create directory structure
# ----------------------------------------------------------------------------------------

# Collect all non-hidden, non-system directories
$dirs = Get-ChildItem -Path $SourcePath -Recurse -Directory |
    Where-Object { -not ($_.Attributes -band [IO.FileAttributes]::Hidden) -and -not ($_.Attributes -band [IO.FileAttributes]::System) }

$totalDirs = $dirs.Count
$dirCount = 0
$startTime = Get-Date

foreach ($d in $dirs) {
    $dirCount++
    $relative = $d.FullName.Substring($SourcePath.Length).TrimStart('\')
    $dest = Join-Path $DestinationPath $relative

    # Create directory
    New-Item -ItemType Directory -Path $dest -Force | Out-Null

    # Show progress every 100 folders (to avoid console spam)
    if ($dirCount % 100 -eq 0 -or $dirCount -eq $totalDirs) {
        $elapsed = (Get-Date) - $startTime
        $rate = if ($dirCount -gt 0) { $elapsed.TotalSeconds / $dirCount } else { 0 }
        $remaining = ($totalDirs - $dirCount) * $rate
        Write-Progress -Activity "Creating folders..." -Status "$dirCount of $totalDirs" `
            -PercentComplete (($dirCount / $totalDirs) * 100) `
            -SecondsRemaining $remaining
    }
}

Write-Progress -Activity "Creating folders..." -Completed

# ----------------------------------------------------------------------------------------
# PASS 2: Create empty files
# ----------------------------------------------------------------------------------------

# Collect all non-hidden, non-system files
$files = Get-ChildItem -Path $SourcePath -Recurse -File |
    Where-Object { -not ($_.Attributes -band [IO.FileAttributes]::Hidden) -and -not ($_.Attributes -band [IO.FileAttributes]::System) }

$totalFiles = $files.Count
$fileCount = 0
$startTime = Get-Date

foreach ($f in $files) {
    $fileCount++
    $relative = $f.FullName.Substring($SourcePath.Length).TrimStart('\')
    $dest = Join-Path $DestinationPath $relative

    # Ensure parent folder exists
    $folder = Split-Path $dest -Parent
    if (!(Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
    }

    # Create empty placeholder file
    New-Item -ItemType File -Path $dest -Force | Out-Null

    # Update progress every 200 files
    if ($fileCount % 200 -eq 0 -or $fileCount -eq $totalFiles) {
        $elapsed = (Get-Date) - $startTime
        $rate = if ($fileCount -gt 0) { $elapsed.TotalSeconds / $fileCount } else { 0 }
        $remaining = ($totalFiles - $fileCount) * $rate
        Write-Progress -Activity "Creating files..." -Status "$fileCount of $totalFiles" `
            -PercentComplete (($fileCount / $totalFiles) * 100) `
            -SecondsRemaining $remaining
    }
}

Write-Progress -Activity "Creating files..." -Completed

# ----------------------------------------------------------------------------------------
Write-Host "`n✅ Done!"
Write-Host "Created $totalDirs folders and $totalFiles files."
Write-Host "Source: $SourcePath"
Write-Host "Clone : $DestinationPath"
