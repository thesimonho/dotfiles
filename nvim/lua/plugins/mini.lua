return {
  {
    "echasnovski/mini.bufremove",
    event = "LazyFile",
    keys = {
      { "<leader>bD", vim.NIL },
    },
  },
  {
    "echasnovski/mini.splitjoin",
    event = "LazyFile",
    keys = {
      { "<leader>cj", "<cmd>lua require('mini.splitjoin').toggle()<cr>", desc = "Split/join" },
    },
  },
  {
    "echasnovski/mini.ai",
    opts = function(_, opts)
      local ai = require("mini.ai")
      opts.custom_textobjects = opts.custom_textobjects or {}

      local mappings = {
        ["/"] = { query = { a = "@comment.outer", i = "@comment.inner" }, desc = "Comment" },
        ["v"] = { query = { a = "@assignment.outer", i = "@assignment.rhs" }, desc = "Variable" },
        ["k"] = { pattern = "([%w_]+)%s*[:=]", desc = "Key" },
        ["L"] = { pattern = "%l%l%l-://[A-Za-z0-9_%-/.#%%=?&'@+*]+", desc = "Link" },
      }

      -- Create new textobjects
      local new_textobjects = {}
      for k, v in pairs(mappings) do
        if v.query then
          new_textobjects[k] = ai.gen_spec.treesitter(v.query)
        elseif v.pattern then
          new_textobjects[k] = { v.pattern }
        end
      end
      opts.custom_textobjects = vim.tbl_extend("force", opts.custom_textobjects, new_textobjects)

      -- Register new textobjects with which-key
      local i = {}
      for k, v in pairs(mappings) do
        i[k] = v.desc
      end

      local a = vim.deepcopy(i)
      local root = vim.deepcopy(i)
      for key, name in pairs({ n = "Next", l = "Last" }) do
        i[key] = vim.tbl_extend("force", { name = "Inside " .. name .. " textobject" }, root)
        a[key] = vim.tbl_extend("force", { name = "Around " .. name .. " textobject" }, root)
      end

      require("which-key").register({
        mode = { "o", "x" },
        i = i,
        a = a,
      })

      return opts
    end,
  },
  {
    "echasnovski/mini.animate",
    enabled = vim.g.neovide == nil,
    event = "VeryLazy",
    opts = function()
      local mouse_scrolled = false
      for _, scroll in ipairs({ "Up", "Down" }) do
        local key = "<ScrollWheel" .. scroll .. ">"
        vim.keymap.set({ "", "i" }, key, function()
          mouse_scrolled = true
          return key
        end, { expr = true })
      end

      local animate = require("mini.animate")
      return {
        open = { enable = false },
        close = { enable = false },
        resize = {
          timing = animate.gen_timing.linear({ duration = 150, unit = "total" }),
        },
        scroll = {
          timing = animate.gen_timing.linear({ duration = 150, unit = "total" }),
          subscroll = animate.gen_subscroll.equal({
            predicate = function(total_scroll)
              if mouse_scrolled then
                mouse_scrolled = false
                return false
              end
              return total_scroll > 1
            end,
          }),
        },
        cursor = {
          enable = false,
          timing = animate.gen_timing.linear({ duration = 30, unit = "total" }),
          path = animate.gen_path.line({
            predicate = function()
              return true
            end,
          }),
        },
      }
    end,
  },
}
