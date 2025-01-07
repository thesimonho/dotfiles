#!/bin/bash
source $(dirname "$0")/helpers.sh

# APT
info "Installing apt packages..."

apt_packages=(
  'barrier'
  'curl'
  'ffmpeg'
  'fonts-firacode'
  'fzf'
  'git'
  'git-lfs'
  'hardinfo'
  'hddtemp'
  'htop'
  'libavcodec-extra'
  'libreoffice'
  'lm-sensors'
  'neofetch'
  'neovim'
  'psensor'
  'stacer'
  'steam'
  'wget'
  'yakuake'
)

counter=1
total=${#apt_packages[@]}
for package in "${apt_packages[@]}"
do
  if ! command_exists $package
  then
    sudo apt-get install $package -y 2>&1 > /dev/null && success "$(show_progress $counter $total) $package installed"
  else
    fail "$(show_progress $counter $total) $package is already installed"
  fi
  counter=$((counter+1))
done

# Flatpak
info "Installing flatpak packages..."

flatpak_packages=(
  'com.axosoft.GitKraken'
  'com.bitwarden.desktop'
  'com.calibre_ebook.calibre'
  'com.discordapp.Discord'
  'com.dropbox.Client'
  'org.gimp.GIMP'
  'com.github.tchx84.Flatseal'
  'org.inkscape.Inkscape'
  'org.kde.kdenlive'
  'org.mozilla.Thunderbird'
  'com.obsproject.Studio'
  'com.parsecgaming.parsec'
  'com.slack.Slack'
  'com.ulduzsoft.Birdtray'
  'us.zoom.Zoom'
  'org.zotero.Zotero'
)

counter=1
total=${#flatpak_packages[@]}
for package in "${flatpak_packages[@]}"
do
  if ! flatpak list --app | grep -q $package
  then
    flatpak install flathub $package -y 2>&1 > /dev/null && success "$(show_progress $counter $total) $package installed"
  else
    fail "$(show_progress $counter $total) $package is already installed"
  fi
  counter=$((counter+1))
done

# Packages that are DE specific
if [[ $XDG_CURRENT_DESKTOP == *"GNOME"* ]]
then
  info "Installing GNOME packages..."
  sudo apt-get install gnome-tweaks -y && success "Gnome tweaks installed"
  sudo apt-get install chrome-gnome-shell -y && success "Chrome Gnome shell installed"
elif [[ $XDG_CURRENT_DESKTOP == *"KDE"* ]]
then
  info "Installing KDE packages..."
  sudo add-apt-repository ppa:papirus/papirus -y  # used for kvantum
  sudo apt-get update

  sudo apt-get install qt5-style-kvantum qt5-style-kvantum-themes -y && success "Kvantum installed"
  sudo apt-get install plasma-discover-backend-flatpak -y && success "KDE Discover flatpak backend installed"
  sudo apt-get install kio-gdrive -y && success "kio-gdrive installed"
  sudo apt-get install dolphin-plugins -y && success "dolphin-plugins installed"
fi
