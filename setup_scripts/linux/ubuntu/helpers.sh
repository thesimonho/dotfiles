#!/bin/bash
info () {
	printf "\n\r  [ \033[00;34m....\033[0m ] $1\n\n"
}

warning () {
	printf "\r  [ \033[00;36m !! \033[0m ] $1\n"
}

success () {
	printf "\r\033[2K  [ \033[00;32m OK \033[0m ] $1\n"
}

fail () {
	printf "\r\033[2K  [\033[0;31m FAIL \033[0m] $1\n"
}

update_distro() {
  sudo apt-get update && time sudo apt-get upgrade -y
}

command_exists() {
	command -v "$1" >/dev/null 2>&1
}

show_progress() {
  echo "($1/$2)"
}