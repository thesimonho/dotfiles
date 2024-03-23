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
    "echasnovski/mini.animate",
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
          timing = animate.gen_timing.linear({ duration = 50, unit = "total" }),
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
