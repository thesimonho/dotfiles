if (sys | get host | get name) != 'Windows' {
  $env.PATH = ($env.PATH | split row (char esep) | prepend '/opt/homebrew/bin')
  $env.PATH = ($env.PATH | split row (char esep) | prepend '/home/linuxbrew/.linuxbrew/bin')
}

zoxide init nushell | save -f ~/.zoxide.nu

mkdir ~/.cache/starship
starship init nu | save -f ~/.cache/starship/init.nu
