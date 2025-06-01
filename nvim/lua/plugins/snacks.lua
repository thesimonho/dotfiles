local ui = require("utils.ui")
local utils = require("utils.general")

local function show_scope_error(opt_global, info)
  local current_scope = opt_global and "global" or "local"
  vim.notify(
    "Cannot set " .. info.scope .. " option (" .. info.name .. ") in " .. current_scope .. " scope",
    vim.log.levels.ERROR,
    { title = "Option Scope Error" }
  )
end

local function is_settable(opt_global, info)
  if opt_global then
    if (info.scope == "win" or info.scope == "buf") and info.global_local ~= true then
      show_scope_error(opt_global, info)
      return false
    end
  else
    if info.scope == "global" then
      show_scope_error(opt_global, info)
      return false
    end
  end
  return true
end

local function nvim_set_option(picker, opt, val, item)
  local set_opts = {}
  if item.info.scope == "win" then
    set_opts.win = picker:current_win().id
  elseif item.info.scope == "buf" then
    set_opts.buf = vim.api.nvim_get_current_buf()
  end

  local ok, err = pcall(vim.api.nvim_set_option_value, opt, val, set_opts)
  if not ok and err then
    vim.notify(err, vim.log.levels.ERROR)
  end

  picker:find({
    on_done = function()
      -- BUG: jumps to the wrong item index
      -- picker.list:view(item.idx)
      picker.list:view(1)
    end,
  })
end

local function show_option_value_input(picker, item, old)
  pcall(vim.ui.input, { prompt = item.text, default = item.value }, function(input)
    if not input or input == old then
      return
    end

    local updated
    if item.info.type == "number" then
      updated = tonumber(input)
    else
      updated = input
    end

    nvim_set_option(picker, item.text, updated, item)
  end)
end

return {
  {
    "folke/snacks.nvim",
    keys = {
      {
        "<leader><space>",
        LazyVim.pick("smart", {
          root = false,
          hidden = true,
          multi = { "buffers", "files" },
          matcher = {
            cwd_bonus = true,
            frecency = true,
            sort_empty = true,
          },
          transform = "unique_file",
        }),
        desc = "Smart Picker",
      },
      { "<leader>sg", LazyVim.pick("live_grep", { root = false, hidden = true }), desc = "Grep (cwd)" },
      {
        "<leader>sw",
        LazyVim.pick("grep_word", { root = false }),
        desc = "Visual selection or word (cwd)",
        mode = { "n", "x" },
      },
      { "<leader>so", LazyVim.pick("options"), desc = "Options" },
      { "<leader>ff", LazyVim.pick("files", { root = false, hidden = true }), desc = "Find Files (cwd)" },
      {
        "<leader>fp",
        function()
          Snacks.picker.projects({
            dev = { "~/Projects" },
            confirm = function(picker)
              picker:close()
              vim.cmd("tabnew")
              ui.load_project_session(picker:dir())
            end,
            patterns = { ".git", "package.json" },
            recent = true,
            matcher = {
              frecency = true, -- use frecency boosting
              sort_empty = true, -- sort even when the filter is empty
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
        sources = {
          options = {
            title = "Options",
            preview = "preview",
            global = false,
            toggles = {
              global = "g",
            },
            finder = function()
              local items = {}
              for _, o in ipairs(vim.tbl_values(vim.api.nvim_get_all_options_info())) do
                local ok, v = pcall(vim.api.nvim_get_option_value, o.name, {})
                local info = vim.api.nvim_get_option_info2(o.name, {})
                if ok and info then
                  items[#items + 1] = {
                    text = o.name,
                    value = tostring(v),
                    info = info,
                    preview = {
                      ft = "help",
                      text = utils.get_help_text(o.name) or "No help available for this option.",
                    },
                  }
                end
              end
              return items
            end,
            format = function(item, _)
              local hl = ""
              if item.value == "true" then
                hl = "Added"
              elseif item.value == "false" then
                hl = "Removed"
              end

              local hl_scope
              if item.info.scope == "global" then
                hl_scope = "Identifier"
              else
                hl_scope = "Float"
              end

              local ret = {}
              local a = Snacks.picker.util.align
              ret[#ret + 1] = { a(item.text, 20), "Keyword" }
              ret[#ret + 1] = { "▏", "SnacksIndent" }
              ret[#ret + 1] = { a(item.info.scope, 8), hl_scope }
              ret[#ret + 1] = { "▏", "SnacksIndent" }
              ret[#ret + 1] = { item.value, hl }
              return ret
            end,
            sort = { fields = { "text" } },
            actions = {
              toggle_global = function(picker)
                picker.opts.global = not picker.opts.global
                picker:find()
              end,
              confirm = function(picker, item)
                if not is_settable(picker.opts.global, item.info) then
                  return
                end

                if item.info.type == "boolean" then
                  local str2bool = { ["true"] = true, ["false"] = false }
                  nvim_set_option(picker, item.text, not str2bool[item.value], item)
                elseif item.info.type == "number" then
                  show_option_value_input(picker, item, tonumber(item.value))
                else
                  show_option_value_input(picker, item, item.value)
                end
              end,
            },
            win = {
              input = {
                keys = {
                  ["<M-g>"] = { "toggle_global", mode = { "i", "n" } },
                },
              },
            },
          },
        },
      },
    },
  },
}
