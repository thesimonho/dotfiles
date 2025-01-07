let OS = sys host | get long_os_version

if ($OS | str contains 'Linux') {
  $env.PATH = ($env.PATH | split row (char esep) | prepend '/home/linuxbrew/.linuxbrew/bin')
}

if ($OS | str contains 'MacOS') {
  $env.PATH = ($env.PATH | split row (char esep) | prepend '/opt/homebrew/bin')
}

zoxide init nushell | save -f ~/.zoxide.nu

mkdir ~/.cache/starship
starship init nu | save -f ~/.cache/starship/init.nu
