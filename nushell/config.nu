# External completers
let carapace_completer = {|spans|
    carapace $spans.0 nushell ...$spans | from json
}

let zoxide_completer = {|spans|
    $spans | skip 1 | zoxide query -l ...$in | lines | where {|x| $x != $env.PWD}
}

let multiple_completer = {|spans|
    match $spans.0 {
        z | zi => $zoxide_completer
        _ => $carapace_completer
    } | do $in $spans
}

$env.config.buffer_editor = "nvim"
$env.config.bracketed_paste = true
$env.config.completions.algorithm = "prefix"
$env.config.completions.quick = false
$env.config.completions.external.completer = $multiple_completer
$env.config.history.file_format = "sqlite"
$env.config.rm.always_trash = true
$env.config.show_banner = false
$env.config.use_kitty_protocol = true

$env.ENV_CONVERSIONS = {
    __zoxide_hooked: {
        from_string: { |s| $s | into bool }
    }
}

# completions
source $"($nu.default-config-dir)/completions/docker.nu"
source $"($nu.default-config-dir)/completions/git.nu"
source $"($nu.default-config-dir)/completions/github.nu"
source $"($nu.default-config-dir)/completions/npm.nu"
source $"($nu.default-config-dir)/completions/poetry.nu"
source $"($nu.default-config-dir)/completions/rg.nu"
source $"($nu.default-config-dir)/completions/tar.nu"

source $"($nu.default-config-dir)/alias.nu"
source ~/.zoxide.nu
use ~/.cache/starship/init.nu
