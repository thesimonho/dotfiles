local actions = require("fzf-lua.actions")
return {
  require("fzf-lua").setup({
    winopts = {
      height = 0.85, -- window height
      width = 0.80, -- window width
      row = 0.35, -- window row position (0=top, 1=bottom)
      col = 0.50, -- window col position (0=left, 1=right)
      backdrop = 60,
      fullscreen = false, -- start fullscreen?
      preview = {
        default = "bat", -- override the default previewer?
        wrap = "wrap", -- wrap|nowrap
        hidden = "hidden", -- hidden|nohidden
        vertical = "down:45%", -- up|down:size
        horizontal = "right:60%", -- right|left:size
        layout = "flex", -- horizontal|vertical|flex
        flip_columns = 100, -- #cols to switch to horizontal on flex
        title = true, -- preview border title (file/buf)?
        title_pos = "center", -- left|center|right, title alignment
        scrollbar = "border", -- `false` or string:'float|border'
        scrolloff = "-2", -- float scrollbar offset from right
        delay = 100, -- delay(ms) displaying the preview
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
      on_create = function()
        -- called once upon creation of the fzf main window
        -- can be used to add custom fzf-lua mappings, e.g:
        --   vim.keymap.set("t", "<C-j>", "<Down>", { silent = true, buffer = true })
      end,
      -- called once _after_ the fzf interface is closed
      on_close = function() end,
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
    previewers = {
      cat = {
        cmd = "cat",
        args = "-n",
      },
      bat = {
        cmd = "bat",
        args = "--color=always --style=numbers,changes",
      },
      head = {
        cmd = "head",
        args = nil,
      },
      git_diff = {
        cmd_deleted = "git diff --color HEAD --",
        cmd_modified = "git diff --color HEAD",
        cmd_untracked = "git diff --color --no-index /dev/null",
      },
      man = {
        -- replace with `man -P cat %s | col -bx` on OSX
        cmd = "man -c %s | col -bx",
      },
    },
    defaults = {
      file_icons = "mini",
      copen = "topleft copen",
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
  }),
}
