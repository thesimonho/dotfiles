let OS = sys host | get long_os_version

if ($OS | str contains 'Linux') {
  # https://forums.opensuse.org/t/guide-ssh-agent-kwallet-to-store-ssh-private-key-passphrases/173401
  # https://kcore.org/2022/05/18/ssh-passphrases-kde/
  $env.SSH_ASKPASS = '/usr/bin/ksshaskpass'
  $env.SSH_ASKPASS_REQUIRE = 'prefer'
  $env.SSH_AUTH_SOCK = '/run/user/1000/ssh-agent.socket'
  $env.PATH = ($env.PATH | split row (char esep) | append '/home/linuxbrew/.linuxbrew/bin')
} else if ($OS | str contains 'macOS') {
  $env.PATH = ($env.PATH | split row (char esep) | append '/usr/local/bin')
  $env.PATH = ($env.PATH | split row (char esep) | append '/usr/local/go/bin')
  $env.PATH = ($env.PATH | split row (char esep) | append '/opt/homebrew/bin')
  $env.PATH = ($env.PATH | split row (char esep) | append '~/.local/pipx/venvs/poetry/bin')
}

# add SSH keys to ssh-agent
if (ssh-add -l | str contains 'The agent has no identities') {
  ls ~/.ssh/id_*[!.pub] | each {|e| ssh-add -q $e.name }
}

# environment variables
$env.VIRTUAL_ENV_DISABLE_PROMPT = '1'

$env.ENV_CONVERSIONS = {
    __zoxide_hooked: {
        from_string: { |s| $s | into bool }
    }
}

# remove duplicate paths
$env.PATH = ($env.PATH | uniq)

# init shell apps
mkdir ~/.cache/starship
starship init nu | save -f ~/.cache/starship/init.nu
zoxide init nushell | save -f ~/.zoxide.nu
