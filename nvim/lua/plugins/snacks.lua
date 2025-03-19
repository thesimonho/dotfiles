return {
  {
    "folke/snacks.nvim",
    keys = {
      {
        "<leader>fp",
        function()
          Snacks.picker.projects({
            dev = { "~/Projects" },
            confirm = function(picker)
              picker:close()
              vim.cmd("tabnew")
              vim.fn.chdir(picker:dir())
              local session_loaded = false
              vim.api.nvim_create_autocmd("SessionLoadPost", {
                once = true,
                callback = function()
                  session_loaded = true
                end,
              })

              -- fallback to picker
              vim.defer_fn(function()
                if not session_loaded then
                  Snacks.picker.files({ dirs = { vim.fn.getcwd() } })
                end
              end, 100)
              vim.cmd("lua require('persistence').load()")
            end,
            patterns = { ".git", "package.json", "Makefile" },
            recent = true,
            matcher = {
              frecency = true, -- use frecency boosting
              sort_empty = true, -- sort even when the filter is empty
              cwd_bonus = false,
            },
            sort = { fields = { "score:desc", "idx" } },
          })
        end,
        desc = "Projects",
      },
      { "<leader>dpt", "<cmd>lua Snacks.profiler.pick()<cr>", desc = "Toggle" },
      {
        "<leader>qp",
        function()
          local flag_file = vim.fn.stdpath("state") .. "/startup_profiler"
          vim.fn.writefile({}, flag_file)
          vim.notify("Profiler will run on next startup")
        end,
        desc = "Profile Next Startup",
      },
    },
    init = function()
      _G.dd = function(...)
        Snacks.debug.inspect(...)
      end
      _G.bt = function()
        Snacks.debug.backtrace()
      end
      vim.print = _G.dd
    end,
    opts = {
      gitbrowse = {
        notify = true,
        remote_patterns = {
          { "^(https?://.*)%.git$", "%1" },
          { "^git@personal%-github%.com:(.+)%.git$", "https://github.com/%1" },
          { "^git@(.+):(.+)%.git$", "https://%1/%2" },
          { "^git@(.+):(.+)$", "https://%1/%2" },
          { "^git@(.+)/(.+)$", "https://%1/%2" },
          { "^ssh://git@(.*)$", "https://%1" },
          { "^ssh://([^:/]+)(:%d+)/(.*)$", "https://%1/%3" },
          { "^ssh://([^/]+)/(.*)$", "https://%1/%2" },
          { "ssh%.dev%.azure%.com/v3/(.*)/(.*)$", "dev.azure.com/%1/_git/%2" },
          { "^https://%w*@(.*)", "https://%1" },
          { "^git@(.*)", "https://%1" },
          { ":%d+", "" },
          { "%.git$", "" },
        },
      },
      notifier = {
        margin = { top = 1, right = 1, bottom = 1 },
        style = "compact",
      },
      bigfile = { enabled = true },
      quickfile = { enabled = true },
      indent = {
        indent = {
          enabled = true, -- enable indent guides
          char = "│",
          only_scope = true, -- only show indent guides of the scope
          only_current = true, -- only show indent guides in the current window
          hl = "SnacksIndent",
        },
        scope = {
          enabled = false, -- enable highlighting the current scope
          hl = "SnacksIndentScope",
        },
        chunk = {
          enabled = true,
          only_current = true,
          hl = "SnacksIndentChunk",
          char = {
            corner_top = "╭",
            corner_bottom = "╰",
            horizontal = "─",
            vertical = "│",
            arrow = "›",
          },
        },
        filter = function(buf)
          return vim.g.snacks_indent ~= false and vim.b[buf].snacks_indent ~= false and vim.bo[buf].buftype ~= "bigfile"
        end,
        priority = 200,
      },
      scroll = {
        filter = function(buf)
          return vim.g.snacks_scroll ~= false
            and vim.b[buf].snacks_scroll ~= false
            and vim.bo[buf].buftype ~= "terminal"
            and vim.bo[buf].filetype ~= "bigfile"
        end,
      },
      lazygit = {
        configure = true,
        theme = {
          activeBorderColor = { fg = "lualine_b_normal", bold = true },
          inactiveBorderColor = { fg = "Comment" },
          cherryPickedCommitBgColor = { fg = "lualine_b_normal" },
          cherryPickedCommitFgColor = { fg = "Function" },
          defaultFgColor = { fg = "Normal" },
          optionsTextColor = { fg = "Statement" },
          searchingActiveBorderColor = { fg = "Search", bold = true },
          selectedLineBgColor = { bg = "CursorLineAlt" },
          unstagedChangesColor = { fg = "DiagnosticError" },
        },
      },
      picker = {
        enabled = true,
        matcher = {
          fuzzy = true, -- use fuzzy matching
          smartcase = true, -- use smartcase
          ignorecase = true, -- use ignorecase
          sort_empty = true, -- sort results when the search string is empty
          filename_bonus = true, -- give bonus for matching file names (last part of the path)
          file_pos = true, -- support patterns like `file:line:col` and `file:line`
          cwd_bonus = true, -- give bonus for matching files in the cwd
          frecency = true, -- frecency bonus
          history_bonus = true, -- give more weight to chronological order
        },
        formatters = {
          file = {
            filename_first = false, -- display filename before the file path
            filename_only = false, -- only show the filename
            truncate = 40, -- truncate the file path to (roughly) this length
            icon_width = 2, -- width of the icon (in characters)
            git_status_hl = true, -- use the git status highlight group for the filename
          },
          selected = {
            show_always = false, -- only show the selected column when there are multiple selections
            unselected = true, -- use the unselected icon for unselected items
          },
          severity = {
            icons = false, -- show severity icons
          },
        },
        win = {
          preview = {
            wo = {
              number = false,
              relativenumber = false,
              wrap = true,
              foldenable = false,
              foldcolumn = "0",
              signcolumn = "no",
            },
          },
        },
      },
    },
  },
}
