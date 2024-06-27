######################################################
# Install scoop packages
######################################################
if (!(Test-Path $env:USERPROFILE\scoop)) {
    Write-Host "Installing scoop..."
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
    Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
}

scoop bucket add extras
scoop bucket add nerd-fonts

Write-Host "Installing scoop packages..."
scoop install main/ripgrep
scoop install main/ffmpeg
scoop install main/mingw-winlibs
scoop install main/pandoc
scoop install extras/lazygit
scoop install fzf
scoop install sed
scoop install fd 
scoop install pipx
scoop install VictorMono-NF
scoop install VictorMono-NF-Mono
scoop install FiraCode-NF
scoop install FiraCode-NF-Mono
