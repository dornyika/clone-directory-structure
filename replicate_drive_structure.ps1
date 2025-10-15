$Source = "D:\"
$Dest = "C:\DriveCatalogs\D_Drive"

# Copy directory structure
Get-ChildItem -Path $Source -Recurse -Directory | ForEach-Object {
    $NewDir = $_.FullName.Replace($Source, $Dest)
    New-Item -ItemType Directory -Path $NewDir -Force
}

# Create empty files
Get-ChildItem -Path $Source -Recurse -File | ForEach-Object {
    $NewFile = $_.FullName.Replace($Source, $Dest)
    $null = New-Item -ItemType File -Path $NewFile -Force
}