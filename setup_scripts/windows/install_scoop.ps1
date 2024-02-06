######################################################
# Install scoop packages
######################################################
if (!(Test-Path $env:USERPROFILE\scoop)) {
    Write-Host "Installing scoop..."
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
    Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
}

Write-Host "Installing scoop packages..."
scoop install main/ripgrep
scoop install main/ffmpeg