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
          cursorline = false,
          cursorcolumn = false,
          signcolumn = "no",
          list = false,
          foldenable = false,
        },
      },
    },
    keymap = {
      builtin = {
        ["<C-p>"] = "preview-page-up",
        ["<C-n>"] = "preview-page-down",
      },
    },
    actions = {
      files = {
        -- `file_edit_or_qf` opens a single selection or sends multiple selection to quickfix
        ["enter"] = actions.file_edit_or_qf,
        ["ctrl-s"] = actions.file_split,
        ["ctrl-v"] = actions.file_vsplit,
        ["ctrl-t"] = actions.file_tabedit,
        ["ctrl-q"] = actions.file_sel_to_qf,
        ["ctrl-l"] = actions.file_sel_to_ll,
      },
    },
    fzf_opts = {
      -- options are sent as `<left>=<right>`
      -- set to `false` to remove a flag
      -- set to `true` for a no-value flag
      -- for raw args use `fzf_args` instead
      ["--ansi"] = true,
      ["--info"] = "inline-right",
      ["--height"] = "100%",
      ["--layout"] = "reverse",
      ["--border"] = "none",
      ["--highlight-line"] = true,
    },
    defaults = {
      formatter = "path.filename_first",
      file_icons = "mini",
      copen = "topleft copen",
      header = false,
    },
    files = {
      git_icons = true,
      find_opts = [[-type f -not -path '*/\.git/*' -printf '%P\n']],
      rg_opts = [[--color=never --files --hidden --follow -g "!.git"]],
      fd_opts = [[--color=never --type f --hidden --follow --exclude .git]],
    },
    oldfiles = {
      include_current_session = true,
    },
    buffers = {
      show_unloaded = true,
    },
    grep = {
      grep_opts = "--binary-files=without-match --line-number --recursive --color=auto --perl-regexp -e",
      rg_opts = "--column --line-number --no-heading --color=always --smart-case --max-columns=4096 -e",
      rg_glob = true, -- enable glob parsing
      glob_flag = "--iglob",
      glob_separator = "%s%-%-", -- query separator pattern (lua): ' --'
      actions = {
        ["ctrl-g"] = { actions.grep_lgrep },
      },
    },
    lsp = {
      includeDeclaration = false,
    },
  },
}
