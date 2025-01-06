#!/bin/bash
source $(dirname "$0")/helpers.sh

# Update OS
PS3="Select your distribution: "
select distro in Ubuntu Kubuntu "KDE Neon" pop_os Quit; do
  case $distro in
  Ubuntu)
    update_distro
    sudo apt-get install ubuntu-restricted-extras && success "Ubuntu restricted extras installed"
    break
    ;;
  Kubuntu)
    # sudo add-apt-repository ppa:kubuntu-ppa/backports -y && success "Kubuntu backports added"
    update_distro
    sudo apt-get install kubuntu-restricted-extras && success "Kubuntu restricted extras installed"
    break
    ;;
  "KDE Neon")
    update_distro
    break
    ;;
  pop_os)
    update_distro
    break
    ;;
  Quit)
    exit 0
    ;;
  *)
    echo "Invalid choice: $REPLY"
    exit 0
    ;;
  esac
done

if command_exists flatpak; then
  sudo flatpak update >/dev/null && success "Flatpaks updated"
else
  warning "Flatpak not installed on this system"
  sudo apt-get install flatpak -y && success "Flatpak installed"
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

if command_exists snap; then
  sudo rm -rf /var/cache/snapd/
  sudo apt autoremove --purge snapd -y
  rm -rf ~/snap
fi

# Install software
source $(dirname "$0")/install_basic.sh
source $(dirname "$0")/install_advanced.sh

sudo apt autoremove -y

# Setup OS
sudo hostnamectl set-hostname Simon-Linux

sudo ufw enable
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow from 192.168.1.0/24

git-lfs install

## Fix inverted function keys (fn lock) when using Varmillo keyboard ---------
## 0 = disabled : Disable the 'fn' key. Pressing 'fn'+'F8' will behave like you only press 'F8'
## 1 = fkeyslast : Function keys are used as last key. Pressing 'F8' key will act as a special key. Pressing 'fn'+'F8' will behave like a F8.
## 2 = fkeysfirst : Function keys are used as first key. Pressing 'F8' key will behave like a F8. Pressing 'fn'+'F8' will act as special key (play/pause)
echo 'options hid_apple fnmode=2' | sudo tee /etc/modprobe.d/hid_apple.conf
sudo update-initramfs -u

# Symlinks and mounts

## Internal drives
sudo mkdir -p -v /media/$(whoami)/Storage
if ! grep -q 'Storage' /etc/fstab; then
  echo "UUID=\"d157d1cb-e941-4055-9236-631ac1197524\" /media/$(whoami)/Storage ext4 defaults 0 0" | sudo tee -a /etc/fstab
fi

sudo mkdir -p -v /media/$(whoami)/Games
if ! grep -q 'Games' /etc/fstab; then
  echo "UUID=\"1f35539f-7a8e-4144-9f79-644d7b112d48\" /media/$(whoami)/Games ext4 defaults 0 0" | sudo tee -a /etc/fstab
fi

sudo mount -a

## Home directories
# ln -s /media/$(whoami)/Storage ~/Storage
# ln -s /media/$(whoami)/Games ~/Games

rm -rf ~/Downloads
ln -s /media/$(whoami)/Storage/Downloads ~/Downloads

rm -rf ~/Documents
ln -s /media/$(whoami)/Storage/Documents ~/Documents

rm -rf ~/Music
ln -s /media/$(whoami)/Storage/Music ~/Music

rm -rf ~/Pictures
ln -s /media/$(whoami)/Storage/Pictures ~/Pictures

rm -rf ~/Videos
ln -s /media/$(whoami)/Storage/Videos ~/Videos

# dotfiles
rm -f ~/.zshrc
ln -s $(
  builtin cd $PWD/../..
  pwd
)/.zshrc ~/.zshrc

rm -f ~/.config/nvim/init.vim
mkdir -p ~/.config/nvim
ln -s $(
  builtin cd $PWD/../..
  pwd
)/init.vim ~/.config/nvim/init.vim

printf "\n"
warning "All Done!"
