#!/bin/bash
if [ -f /etc/arch-release ]; then
  sudo pacman -S --needed dolphin-plugins kio-gdrive extra/kde-graphics-meta extra/kde-system-meta docker shelly
fi
