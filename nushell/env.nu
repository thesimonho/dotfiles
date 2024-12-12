$env.PATH = ($env.PATH | split row (char esep) | prepend '/opt/homebrew/bin')

zoxide init nushell | save -f ~/.zoxide.nu

mkdir ~/.cache/starship
starship init nu | save -f ~/.cache/starship/init.nu
