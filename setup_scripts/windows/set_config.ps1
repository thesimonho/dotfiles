######################################################
# Clone dotfiles repo and symlink them
######################################################
Write-Host "Cloning dotfiles repo..."
git clone https://github.com/sho-87/dotfiles.git $env:USERPROFILE\dotfiles

Write-Host "Symlinking nvim config..."
New-Item -ItemType SymbolicLink -Path $env:USERPROFILE\AppData\Local\nvim -Target $env:USERPROFILE\dotfiles\nvim

Write-Host "Symlinking wezterm config..."
New-Item -ItemType Directory -Path $env:USERPROFILE\.config
New-Item -ItemType SymbolicLink -Path $env:USERPROFILE\.config\wezterm -Target $env:USERPROFILE\dotfiles\wezterm

######################################################
# Configure Git globals
######################################################
#Write-Host "Configuring Git globals"

#$userName = Read-Host 'Enter your name for git configuration'
#$userEmail = Read-Host 'Enter your email for git configuration'

#git config --global user.email $userEmail
#git config --global user.name $userName
