######################################################
# Install packages
######################################################
Write-Host "Installing packages"

winget install -e --id 7zip.7zip
winget install -e --id Adobe.Acrobat.Reader.64-bit
winget install -e --id Twilio.Authy
winget install -e --id Bitwarden.Bitwarden
winget install -e --id Google.Chrome
winget install -e --id Discord.Discord
winget install -e --id Docker.DockerDesktop
winget install -e --id Google.Drive
winget install -e --id Dropbox.Dropbox
winget install -e --id Mozilla.Firefox
winget install -e --id GIMP.GIMP
winget install -e --id Git.Git
winget install -e --id Axosoft.GitKraken
winget install -e --id TheDocumentFoundation.LibreOffice
winget install -e --id Neovim.Neovim
winget install -e --id OBSProject.OBSStudio
winget install JanDeDobbeleer.OhMyPosh -s winget
winget install -e --id Parsec.Parsec
winget install -e --id Microsoft.PowerToys
winget install -e --id Nvidia.GeForceExperience
winget install -e --id RProject.R
winget install wez.wezterm
winget install -e --id Valve.Steam
winget install -e --id Microsoft.VisualStudioCode
winget install -e --id VideoLAN.VLC
winget install -e --id DigitalScholar.Zotero

######################################################
# Get system tools
######################################################
& $PSScriptRoot\get_tools.ps1


######################################################
# Configure Git globals
######################################################
Write-Host "Configuring Git globals"

$userName = Read-Host 'Enter your name for git configuration'
$userEmail = Read-Host 'Enter your email for git configuration'

git config --global user.email $userEmail
git config --global user.name $userName

######################################################
# Clone dotfiles repo and symlink them
######################################################
Write-Host "Cloning dotfiles repo"

git clone https://github.com/sho-87/dotfiles.git $env:USERPROFILE\dotfiles

New-Item -ItemType SymbolicLink -Path $env:USERPROFILE\AppData\Local\nvim -Target $env:USERPROFILE\dotfiles\nvim
