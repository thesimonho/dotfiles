local ui = require("utils.ui")
local paths = vim.fn.globpath(vim.o.rtp, "doc/options.txt", false, true)
local help = vim.fn.readfile(paths[1])

local function get_help_text(tag)
  local tag_pattern = "%*'" .. tag .. "'%*"

  local start_index
  for i, line in ipairs(help) do
    if line:match(tag_pattern) then
      start_index = i
      break
    end
  end
  if not start_index then
    return nil
  end

  local heading_pattern = "%*'[^']*'%*"
  local end_index = #help
  for i = start_index + 1, #help do
    if help[i]:match(heading_pattern) then
      end_index = i - 1
      break
    end
  end

  local output = {}
  for i = start_index, end_index do
    output[#output + 1] = help[i]
  end

  return table.concat(output, "\n")
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
      { "<leader>fi", LazyVim.pick("icons", { matcher = { fuzzy = false } }), desc = "Icons" },
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
            supports_live = true,
            finder = function()
              local items = {}
              for _, o in pairs(vim.api.nvim_get_all_options_info()) do
                local ok, v = pcall(vim.api.nvim_get_option_value, o.name, {})
                if ok then
                  items[#items + 1] = {
                    text = o.name,
                    value = tostring(v),
                    preview = {
                      ft = "help",
                      text = get_help_text(o.name) or "No help available for this option.",
                    },
                  }
                end
              end
              return items
            end,
            format = function(item, _)
              local ret = {}
              local a = Snacks.picker.util.align
              ret[#ret + 1] = { a(item.text, 20), "Statement" }
              ret[#ret + 1] = { "▏", "SnacksIndent" }
              ret[#ret + 1] = { a(item.value, 20) }
              return ret
            end,
            sort = { fields = { "text" } },
            confirm = function(picker, item)
              -- TODO: https://github.com/ibhagwan/fzf-lua/blob/main/lua/fzf-lua/actions.lua#L599
              print(item.text .. " = " .. item.value)
            end,
          },
        },
      },
    },
  },
}
