local ui = require("utils.ui")
local utils = require("utils.general")

-- Resolve local options against the source window, never the picker/input.
local function option_context(picker, info)
  -- Capture before the picker takes focus. Snacks can choose a new main
  -- window when the original closes; option edits must not follow that change.
  picker.option_source = picker.option_source
    or {
      win = picker.main,
      buf = vim.api.nvim_win_get_buf(picker.main),
    }
  if picker.opts.global or info.scope == "global" then
    return { scope = "global" }
  end
  local source = picker.option_source
  if not vim.api.nvim_win_is_valid(source.win) or not vim.api.nvim_buf_is_valid(source.buf) then
    error("The source window has closed")
  end
  if info.scope == "win" then
    return { scope = "local", win = source.win }
  end
  return { scope = "local", buf = source.buf }
end

local function nvim_set_option(picker, opt, val, item)
  local ok, err = pcall(function()
    vim.api.nvim_set_option_value(opt, val, option_context(picker, item.info))
  end)
  if not ok then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end

  picker:find({
    on_done = function()
      picker.list:view(item.idx)
    end,
  })
end

local function show_option_value_input(picker, item, old)
  pcall(vim.ui.input, { prompt = item.text, default = item.value }, function(input)
    if not input or input == old then
      return
    end

    local updated = item.info.type == "number" and tonumber(input) or input
    if item.info.type == "number" and (type(updated) ~= "number" or updated % 1 ~= 0) then
      vim.notify("Enter a whole number", vim.log.levels.ERROR)
      return
    end
    if updated == old then
      return
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
          ignored = true,
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
      {
        "<leader>ff",
        LazyVim.pick("files", { root = false, hidden = true, ignored = true }),
        desc = "Find Files (cwd)",
      },
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
    },
    opts = {
      bigfile = { enabled = true },
      quickfile = { enabled = true },
      scope = {
        enabled = true,
        keys = {
          textobject = {
            is = {
              min_size = 2, -- minimum size of the scope
              edge = false, -- inner scope
              cursor = false,
              treesitter = { blocks = { enabled = false } },
              desc = "inner scope",
            },
            as = {
              cursor = false,
              min_size = 2, -- minimum size of the scope
              treesitter = { blocks = { enabled = false } },
              desc = "full scope",
            },
          },
          jump = {
            ["[s"] = {
              min_size = 1, -- allow single line scopes
              bottom = false,
              cursor = false,
              edge = true,
              treesitter = { blocks = { enabled = false } },
              desc = "top edge of scope",
            },
            ["]s"] = {
              min_size = 1, -- allow single line scopes
              bottom = true,
              cursor = false,
              edge = true,
              treesitter = { blocks = { enabled = false } },
              desc = "bottom edge of scope",
            },
          },
        },
      },
      picker = {
        enabled = true,
        exclude = {
          ".git",
          "node_modules",
        },
        matcher = {
          fuzzy = true, -- use fuzzy matching
          smartcase = true, -- use smartcase
          ignorecase = true, -- use ignorecase
          sort_empty = false, -- sort results when the search string is empty
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
            git_status_hl = false, -- use the git status highlight group for the filename
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
          input = {},
          list = {
            wo = {
              winblend = 0,
            },
          },
          preview = {
            wo = {
              number = false,
              relativenumber = false,
              wrap = true,
              foldenable = false,
              foldcolumn = "0",
              signcolumn = "no",
              winblend = 0,
            },
          },
        },
        sources = {
          options = {
            title = "Options",
            main = { current = true },
            preview = "preview",
            global = false,
            toggles = {
              global = "g",
            },
            finder = function(_, ctx)
              local items = {}
              for i, o in ipairs(vim.tbl_values(vim.api.nvim_get_all_options_info())) do
                local ok, v = pcall(function()
                  return vim.api.nvim_get_option_value(o.name, option_context(ctx.picker, o))
                end)
                if ok then
                  items[#items + 1] = {
                    idx = i,
                    text = o.name,
                    value = tostring(v),
                    info = o,
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
                if not item then
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
