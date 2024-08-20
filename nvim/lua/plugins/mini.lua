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
    init = function()
      local wk = require("which-key")
      wk.add({ "<leader>cj", desc = "Split/join", icon = "󱐪" })
    end,
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
        ["A"] = { query = { a = "@attribute.outer", i = "@attribute.inner" }, desc = "Attribute" },
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
      local ret = { mode = { "o", "x" } }
      for prefix, name in pairs({
        i = "inside",
        a = "around",
        il = "last",
        ["in"] = "next",
        al = "last",
        an = "next",
      }) do
        ret[#ret + 1] = { prefix, group = name }
        for key, obj in pairs(mappings) do
          local desc = obj.desc
          if prefix:sub(1, 1) == "i" then
            desc = desc:gsub(" with ws", "")
          end
          ret[#ret + 1] = { prefix .. key, desc = obj.desc }
        end
      end
      require("which-key").add(ret, { notify = false })

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
          enable = true,
          timing = animate.gen_timing.linear({ duration = 10, unit = "total" }),
        },
        scroll = {
          enable = true,
          timing = animate.gen_timing.linear({ duration = 50, unit = "total" }),
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
