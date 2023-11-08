#-----------------------------------------------------
# Set ENVs
#-----------------------------------------------------

$HOMEPATH = "C:\Users\" + $env:USERNAME
[Environment]::SetEnvironmentVariable("HOME", $HOMEPATH)

#-----------------------------------------------------
# Clone dotfiles repo and symlink them
#-----------------------------------------------------
if (!(Test-Path $env:USERPROFILE\dotfiles)) {
    Write-Host "Cloning dotfiles repo..."
    git clone https://github.com/sho-87/dotfiles.git $env:USERPROFILE\dotfiles
}

if (!(Test-Path $env:USERPROFILE\AppData\Local\nvim)) {
    Write-Host "Symlinking nvim config..."
    New-Item -ItemType SymbolicLink -Path $env:USERPROFILE\AppData\Local\nvim -Target $env:USERPROFILE\dotfiles\nvim
}

if (!(Test-Path $env:USERPROFILE\.config\wezterm)) {
    Write-Host "Symlinking wezterm config..."
    New-Item -ItemType Directory -Path $env:USERPROFILE\.config
    New-Item -ItemType SymbolicLink -Path $env:USERPROFILE\.config\wezterm -Target $env:USERPROFILE\dotfiles\wezterm
}

#-----------------------------------------------------
# Set default shell
#-----------------------------------------------------
[Environment]::SetEnvironmentVariable("ComSpec", "C:\WINDOWS\system32\cmd.exe", "Machine")

#-----------------------------------------------------
# Configure Git globals
#-----------------------------------------------------

# Write-Host "Configuring Git globals..."
#
# $userName = Read-Host 'Enter your name for git configuration'
# $userEmail = Read-Host 'Enter your email for git configuration'
#
# git config --global user.email $userEmail
# git config --global user.name $userName
