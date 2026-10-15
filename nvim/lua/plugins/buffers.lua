return {
  { "akinsho/bufferline.nvim", enabled = false },
  { "folke/persistence.nvim", enabled = false },
  {
    "olimorris/persisted.nvim",
    lazy = false,
    init = function()
      local group = vim.api.nvim_create_augroup("PersistedHooks", {})

      -- save barbar buffer order before saving session
      vim.api.nvim_create_autocmd({ "User" }, {
        pattern = "PersistedSavePre",
        group = group,
        callback = function()
          vim.api.nvim_exec_autocmds("User", { pattern = "SessionSavePre" })
        end,
      })

      -- persisted skips autostart when nvim is launched with args (e.g. `nvim .`),
      -- so first-time visits to a project never register the VimLeavePre save hook.
      -- force-start after VimEnter when cwd is an allowed dir.
      vim.api.nvim_create_autocmd("VimEnter", {
        group = group,
        callback = function()
          local persisted = require("persisted")
          if not vim.g.persisting and persisted.allowed_dir() then
            persisted.start()
          end
          local argc = vim.fn.argc(-1)
          local arg = argc == 1 and vim.fn.argv(0) or nil
          local directory = arg and vim.fn.isdirectory(arg) == 1 and vim.fn.fnamemodify(arg, ":p") or nil
          -- One directory opts into the project picker; plain startup uses the
          -- dashboard fallback. Files, multiple arguments and stdin stay native.
          if (argc == 0 or directory) and not vim.g.started_with_stdin then
            vim.schedule(function()
              if vim.bo.modified then
                return
              end
              if directory then
                local directory_buf = vim.api.nvim_get_current_buf()
                local current = vim.api.nvim_buf_get_name(directory_buf)
                local is_directory_buf = vim.fn.isdirectory(current) == 1
                -- Keep a file opened by a startup trust prompt visible for review.
                if vim.bo.buftype == "" and current ~= "" and not is_directory_buf then
                  return
                end
                vim.cmd("%argdelete")
                vim.cmd.enew()
                if is_directory_buf then
                  vim.api.nvim_buf_delete(directory_buf, {})
                end
              elseif vim.api.nvim_buf_get_name(0) ~= "" then
                return
              end
              require("utils.ui").load_project_session(directory or vim.fn.getcwd(), { dashboard = argc == 0 })
            end)
          end
        end,
      })
    end,
    opts = {
      -- The shared project loader owns startup and reports source errors.
      autoload = false,
      follow_cwd = true,
      use_git_branch = false,
      allowed_dirs = {
        "~/dotfiles",
        "~/Projects",
      },
      before_save = function()
        vim.cmd("%argdelete")
      end,
      should_save = function()
        if vim.g.project_session_load_failed or vim.bo.filetype == "snacks_dashboard" then
          return false
        end
        return true
      end,
    },
  },
  {
    "tiagovla/scope.nvim",
    event = "LazyFile",
    opts = {
      hooks = {
        -- save session on tab leave and close
        pre_tab_leave = function()
          vim.api.nvim_exec_autocmds("User", { pattern = "ScopeTabLeavePre" })
          pcall(require("persisted").save)
        end,
        pre_tab_close = function()
          vim.api.nvim_exec_autocmds("User", { pattern = "ScopeTabLeavePre" })
          pcall(require("persisted").save)
        end,
        post_tab_enter = function()
          vim.api.nvim_exec_autocmds("User", { pattern = "ScopeTabEnterPost" })
        end,
      },
    },
  },
  {
    "romgrk/barbar.nvim",
    event = "LazyFile",
    keys = {
      { "<leader>bp", "<cmd>BufferPin<cr>", desc = "Pin Buffer" },
      { "<leader>bD", "<Cmd>BufferCloseAllButCurrentOrPinned<CR>", desc = "Delete Other Buffers" },
      {
        "<leader>bx",
        function()
          local alt = vim.fn.bufnr("#")
          if alt > 0 and vim.api.nvim_buf_is_valid(alt) and vim.api.nvim_buf_is_loaded(alt) then
            vim.api.nvim_buf_delete(alt, { force = false })
          else
            print("No valid alternate buffer")
          end
        end,
        desc = "Delete Alternate Buffer",
      },
      { "<S-h>", "<cmd>BufferPrevious<cr>", desc = "Previous Buffer" },
      { "<S-l>", "<cmd>BufferNext<cr>", desc = "Next Buffer" },
    },
    opts = {
      focus_on_close = "left",
      highlight_alternate = true,
      highlight_inactive_file_icons = false,
      highlight_visible = false,
      separator_at_end = false,
      maximum_length = 30,
      icons = {
        buffer_index = true,
        buffer_number = false,
        pinned = { button = "", filename = true },
        alternate = { filetype = { custom_colors = true } },
        separator = { left = "▎", right = "▎" },
        diagnostics = {
          [vim.diagnostic.severity.ERROR] = { enabled = true },
          [vim.diagnostic.severity.WARN] = { enabled = false },
          [vim.diagnostic.severity.INFO] = { enabled = false },
          [vim.diagnostic.severity.HINT] = { enabled = false },
        },
        gitsigns = {
          added = { enabled = false },
          changed = { enabled = false },
          deleted = { enabled = false },
        },
      },
    },
  },
}
