#!/bin/bash
source $(dirname "$0")/helpers.sh

advanced_packages=(
  'drivers'
  'code'
  'chrome'
  'docker'
  'lutris'
  'R'
  'zsh'
)

install_drivers(){
  sudo add-apt-repository ppa:graphics-drivers/ppa -y
  sudo dpkg --add-architecture i386
  sudo apt-get update
  sudo apt-get install libvulkan1 libvulkan1:i386 -y
  sudo ubuntu-drivers install
  success "$(show_progress $1 $2) drivers installed"
}

install_code(){
  if ! command_exists "code"
  then
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
    sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
    rm -f packages.microsoft.gpg

    sudo apt-get install apt-transport-https -y
    sudo apt-get update
    sudo apt-get install code -y
    success "$(show_progress $1 $2) vscode installed"
  else
    fail "$(show_progress $1 $2) vscode is already installed"
  fi
}

install_chrome(){
  if ! command_exists "google-chrome"
  then
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -P /home/$(whoami)/Downloads
    sudo dpkg -i /home/$(whoami)/Downloads/google-chrome-stable_current_amd64.deb
    success "$(show_progress $1 $2) google-chrome installed"
  else
    fail "$(show_progress $1 $2) google-chrome is already installed"
  fi
}

install_docker(){
  # https://docs.docker.com/engine/install/ubuntu/#install-using-the-convenience-script
  if ! command_exists "docker"
  then
    curl -fsSL https://get.docker.com -o /home/$(whoami)/Downloads/get-docker.sh
    sudo sh /home/$(whoami)/Downloads/get-docker.sh
    success "$(show_progress $1 $2) docker installed"
  else
    fail "$(show_progress $1 $2) docker is already installed"
  fi
}

install_lutris(){
  if ! command_exists "lutris"
  then
    sudo add-apt-repository ppa:lutris-team/lutris -y
    sudo apt-get update
    sudo apt-get install lutris -y
    success "$(show_progress $1 $2) lutris installed"
  else
    fail "$(show_progress $1 $2) lutris is already installed"
  fi
}

install_R(){
  if ! command_exists "R"
  then
    sudo apt-get update
    sudo apt-get install --no-install-recommends software-properties-common dirmngr -y
    wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | sudo tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
    sudo add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/" -y
    sudo apt-get install r-base r-base-dev -y
    sudo add-apt-repository -r "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/" -y  # no release file, so remove
    success "$(show_progress $1 $2) R installed"
  else
    fail "$(show_progress $1 $2) R is already installed"
  fi
}

install_zsh(){
  if ! command_exists "zsh"
  then
    sudo apt-get install zsh -y
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    chsh -s $(which zsh)

    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

    git clone https://github.com/rupa/z.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/z

    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k

    success "$(show_progress $1 $2) zsh installed"
  else
    fail "$(show_progress $1 $2) zsh is already installed"
  fi
}

info "Installing advanced packages..."

counter=1
total=${#advanced_packages[@]}
for package in "${advanced_packages[@]}"
do
  install_$package $counter $total
  counter=$((counter+1))
done
