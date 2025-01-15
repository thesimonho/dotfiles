let OS = sys host | get long_os_version

if ($OS | str contains 'Linux') {
  $env.PATH = ($env.PATH | split row (char esep) | prepend '/home/linuxbrew/.linuxbrew/bin')

  # https://forums.opensuse.org/t/guide-ssh-agent-kwallet-to-store-ssh-private-key-passphrases/173401
  # https://kcore.org/2022/05/18/ssh-passphrases-kde/
  $env.SSH_ASKPASS = '/usr/bin/ksshaskpass'
  $env.SSH_ASKPASS_REQUIRE = 'prefer'
}

if ($OS | str contains 'MacOS') {
  $env.PATH = ($env.PATH | split row (char esep) | prepend '/opt/homebrew/bin')
}

zoxide init nushell | save -f ~/.zoxide.nu

mkdir ~/.cache/starship
starship init nu | save -f ~/.cache/starship/init.nu
