function Move-StuckWindowToMain {
    param (
        [string]$windowTitle
    )

    # Check if AutoHotKey is installed
    $autoHotKeyPath = Get-Command "AutoHotKey.exe" -ErrorAction SilentlyContinue

    if (-not $autoHotKeyPath) {
        # AutoHotKey is not found, download and install it
        $autoHotKeyInstallerUrl = "https://www.autohotkey.com/download/ahk-install.exe"
        $installerPath = Join-Path $env:TEMP 'AutoHotKeyInstaller.exe'
        Invoke-WebRequest -Uri $autoHotKeyInstallerUrl -OutFile $installerPath
        Start-Process -FilePath $installerPath -Wait
        Remove-Item $installerPath -Force
    }

    # Create an AutoHotKey script
    $scriptPath = Join-Path $env:TEMP 'MoveWindow.ahk'
    @"
    SetTitleMatchMode, 2
    WinMove, $windowTitle,, 0, 0
"@
    | Out-File -FilePath $scriptPath -Force -Encoding ASCII

    # Run the AutoHotKey script
    Start-Process "AutoHotKey.exe" -ArgumentList $scriptPath -NoNewWindow -Wait

    # Remove the AutoHotKey script
    Remove-Item $scriptPath -Force
}

# Example usage:
# Replace 'Stuck Window Title' with the actual title of the stuck window
# Move-StuckWindowToMain -windowTitle 'Stuck Window Title'
