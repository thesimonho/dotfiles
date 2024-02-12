#-----------------------------------------------------
# Set ENVs
#-----------------------------------------------------

$HOMEPATH = "C:\Users\" + $env:USERNAME
[Environment]::SetEnvironmentVariable("HOME", $HOMEPATH, "User")

#-----------------------------------------------------
# Clone config and symlink them
#-----------------------------------------------------

$DOTFILES = "D:\dotfiles"

if (!(Test-Path $DOTFILES)) {
    Write-Host "Cloning dotfiles repo..."
    git clone https://github.com/sho-87/dotfiles.git $DOTFILES
}

if (!(Test-Path $env:USERPROFILE\AppData\Local\nvim)) {
    Write-Host "Symlinking nvim config..."
    New-Item -ItemType SymbolicLink -Path $env:USERPROFILE\AppData\Local\nvim -Target $DOTFILES\nvim
}

if (!(Test-Path $env:USERPROFILE\.config)) {
    Write-Host "Creating .config directory..."
    New-Item -ItemType Directory -Path $env:USERPROFILE\.config
}

if (!(Test-Path $env:USERPROFILE\.config\wezterm)) {
    Write-Host "Symlinking wezterm config..."
    New-Item -ItemType SymbolicLink -Path $env:USERPROFILE\.config\wezterm -Target $DOTFILES\.config\wezterm
}

if (!(Test-Path $env:USERPROFILE\.config\starship.toml)) {
    Write-Host "Symlinking starship config..."
    New-Item -ItemType SymbolicLink -Path $env:USERPROFILE\.config\starship.toml -Target $DOTFILES\.config\starship.toml
}

Write-Host "Symlinking nushell config..."
New-Item -ItemType SymbolicLink -Path $env:USERPROFILE\AppData\Roaming\nushell\config.nu -Target $DOTFILES\nushell\config.nu -Force
New-Item -ItemType SymbolicLink -Path $env:USERPROFILE\AppData\Roaming\nushell\alias.nu -Target $DOTFILES\nushell\alias.nu -Force

if (!(Test-Path $env:USERPROFILE\.emacs.d)) {
    Write-Host "Creating .emacs.d directory..."
    New-Item -ItemType Directory -Path $env:USERPROFILE\.emacs.d
}

Write-Host "Symlinking emacs config..."
New-Item -ItemType SymbolicLink -Path $env:USERPROFILE\.emacs.d\init.el -Target $DOTFILES\emacs\init.el -Force
New-Item -ItemType SymbolicLink -Path $env:USERPROFILE\.emacs.d\early-init.el -Target $DOTFILES\emacs\early-init.el -Force
New-Item -ItemType SymbolicLink -Path $env:USERPROFILE\.emacs.d\themes -Target $DOTFILES\emacs\themes -Force
New-Item -ItemType SymbolicLink -Path $env:USERPROFILE\.emacs.d\images -Target $DOTFILES\emacs\images -Force

#-----------------------------------------------------
# Set default shell
#-----------------------------------------------------

[Environment]::SetEnvironmentVariable("ComSpec", "C:\WINDOWS\system32\cmd.exe", "Machine")

#-----------------------------------------------------
# Configure Git globals
#-----------------------------------------------------

Write-Host "Configuring Git global configs..."

git config --global user.name "Simon Ho"
git config --global user.email simonho.ubc@gmail.com
git config --global rerere.enabled true
git config --global column.ui auto
git config --global branch.sort -committerdate
git config --global fetch.writeCommitGraph true