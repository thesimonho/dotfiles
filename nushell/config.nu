# External completers
let carapace_completer = {|spans|
  carapace $spans.0 nushell ...$spans | from json
}

let zoxide_completer = {|spans|
  $spans | skip 1 | zoxide query -l ...$in | lines | where {|x| $x != $env.PWD}
}

let multiple_completer = {|spans|
  let expanded_alias = scope aliases
  | where name == $spans.0
  | get -i 0.expansion

  let spans = if $expanded_alias != null {
    $spans
    | skip 1
    | prepend ($expanded_alias | split row ' ' | take 1)
  } else {
    $spans
  }

  match $spans.0 {
    z | zi => $zoxide_completer
    __zoxide_z | __zoxide_zi => $zoxide_completer
    _ => $carapace_completer
  } | do $in $spans
}

$env.config.buffer_editor = "nvim"
$env.config.edit_mode = 'emacs'
$env.config.bracketed_paste = true
$env.config.completions.algorithm = "prefix"
$env.config.completions.quick = true
$env.config.completions.partial = true
$env.config.completions.external = {
    enable: true
    max_results: 100
    completer: $multiple_completer
}
$env.config.history.file_format = "sqlite"
$env.config.history.isolation = false
$env.config.hooks = {
    pre_prompt: []
    pre_execution: []
    env_change: {
        PWD: [(source $"($nu.default-config-dir)/hooks/direnv.nu")]
    }
}
$env.config.rm.always_trash = true
$env.config.show_banner = false
$env.config.use_kitty_protocol = true
$env.config.menus = [
  {
    name: "completion_menu"
    only_buffer_difference: false
    marker: "󰞖 "
    type: {
      layout: columnar
      columns: 4
      col_width: 20
      col_padding: 2
    }
    style: {}
  }
]
$env.config.keybindings = [
  {
    name: "trigger-completion-menu"
    modifier: none
    keycode: tab
    mode: [emacs, vi_normal, vi_insert]
    event: {
      until: [
        { send: menu name: "completion_menu" }
        { send: menunext }
        { edit: complete }
      ]
    }
  },
  {
    name: "inline-complete"
    modifier: ALT
    keycode: char_l
    mode: [emacs, vi_insert]
    event: {
      until: [
        { send: HistoryHintComplete }
      ]
    }
  },
  {
    name: "backwards-word"
    modifier: CONTROL
    keycode: char_H
    mode: [emacs, vi_insert]
    event: {
      edit: BackspaceWord
    }
  },
]

# completion sources
source $"($nu.default-config-dir)/completions/curl.nu"
source $"($nu.default-config-dir)/completions/less.nu"
source $"($nu.default-config-dir)/completions/poetry.nu"
source $"($nu.default-config-dir)/completions/rg.nu"
source $"($nu.default-config-dir)/completions/tar.nu"

source $"($nu.default-config-dir)/external.nu"
source $"($nu.default-config-dir)/alias.nu"

source ~/.zoxide.nu
source ~/.cache/carapace/init.nu
use ~/.cache/starship/init.nu
