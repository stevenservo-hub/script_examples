$sourcePath = "/"

$oldFiles = Get-ChildItem -Path $sourcePath -Recurse | Where-Object {
    $_.LastWriteTime -lt (Get-Date).AddYears(-3)
}

$backupFolder = "sspring/backup"
if (!(Test-Path $backupFolder)) {
    New-Item -Path $backupFolder -ItemType Directory
}

try {
    Copy-Item -Path $oldFiles -Destination $backupFolder -Force -Recurse
} catch {
    Write-Host "Error copying files: $_"
    exit 1
}

$currentDate = Get-Date | Format-Date -yyyyMMdd
$zipFileName = "filearchive_$currentDate.zip"
try {
    Add-Type -Assembly "System.IO.Compression.FileSystem"
    [io.compression.zipfile]::CreateFromDirectory($backupFolder, $zipFileName)
} catch {
    Write-Host "Error creating ZIP file: $_"
    exit 1
}

try {
    Remove-Item -Path $oldFiles -Recurse -Force -Confirm:$false
} catch {
    Write-Host "Error deleting files: $_"
    exit 1
}

$scpCommand = "scp $backupFolder/$zipFileName sspring@192.168.88.2:/nas/backups"
$sshKeyPath = "$HOME/.ssh/id_rsa"

try {
    Invoke-Expression -Command $scpCommand -PassThru
} catch {
    Write-Host "Error copying ZIP file to remote server: $_"
    exit 1
}

Remove-Item -Path $backupFolder/$zipFileName -Force

Write-Host "Backup completed successfully."
