#!/bin/bash
# Applications for work

flatpak install flathub com.slack.Slack -y

brew install go@1.22
brew install python@3.11
brew install awscli

brew tap hashicorp/tap
brew install hashicorp/tap/terraform
