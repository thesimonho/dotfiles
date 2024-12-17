local actions = require("fzf-lua.actions")

return {
  "ibhagwan/fzf-lua",
  opts = {
    winopts = {
      height = 0.85, -- window height
      width = 0.80, -- window width
      row = 0.35, -- window row position (0=top, 1=bottom)
      col = 0.50, -- window col position (0=left, 1=right)
      backdrop = 60,
      preview = {
        wrap = "wrap", -- wrap|nowrap
        hidden = "nohidden", -- hidden|nohidden
        vertical = "down:45%", -- up|down:size
        horizontal = "right:45%", -- right|left:size
        layout = "flex", -- horizontal|vertical|flex
        title = true, -- preview border title (file/buf)?
        scrollbar = "border", -- `false` or string:'float|border'
        winopts = { -- builtin previewer window options
          number = false,
          relativenumber = false,
          cursorline = true,
          cursorlineopt = "both",
          cursorcolumn = false,
          signcolumn = "no",
          list = false,
          foldenable = false,
        },
      },
    },
    keymap = {
      builtin = {
        ["<S-down>"] = "preview-page-down",
        ["<S-up>"] = "preview-page-up",
      },
    },
    actions = {
      files = {
        -- `file_edit_or_qf` opens a single selection or sends multiple selection to quickfix
        ["enter"] = actions.file_edit_or_qf,
        ["ctrl-s"] = actions.file_split,
        ["ctrl-v"] = actions.file_vsplit,
        ["ctrl-t"] = actions.file_tabedit,
        ["alt-q"] = actions.file_sel_to_qf,
        ["alt-Q"] = actions.file_sel_to_ll,
      },
    },
    fzf_opts = {
      -- options are sent as `<left>=<right>`
      -- set to `false` to remove a flag
      -- set to `true` for a no-value flag
      -- for raw args use `fzf_args` instead
      ["--ansi"] = true,
      ["--info"] = "inline-right", -- fzf < v0.42 = "inline"
      ["--height"] = "100%",
      ["--layout"] = "reverse",
      ["--border"] = "none",
      ["--highlight-line"] = true, -- fzf >= v0.53
    },
    defaults = {
      file_icons = "mini",
      copen = "topleft copen",
      header = false,
    },
    files = {
      formatter = "path.filename_first",
      find_opts = [[-type f -not -path '*/\.git/*' -printf '%P\n']],
      rg_opts = [[--color=never --files --hidden --follow -g "!.git"]],
      fd_opts = [[--color=never --type f --hidden --follow --exclude .git]],
    },
    grep = {
      grep_opts = "--binary-files=without-match --line-number --recursive --color=auto --perl-regexp -e",
      rg_opts = "--column --line-number --no-heading --color=always --smart-case --max-columns=4096 -e",
      rg_glob = false, -- default to glob parsing?
      glob_separator = "%s%-%-", -- query separator pattern (lua): ' --'
      actions = {
        ["ctrl-g"] = { actions.grep_lgrep },
        ["ctrl-r"] = { actions.toggle_ignore },
      },
    },
    lsp = {
      includeDeclaration = false,
      ignore_current_line = true,
    },
  },
}
