return {
  {
    "hrsh7th/nvim-cmp",
    opts = function(_, opts)
      local has_words_before = function()
        unpack = unpack or table.unpack
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
      end

      local cmp = require("cmp")

      opts.window = vim.tbl_extend("force", opts.window or {}, {
        completion = vim.tbl_extend("force", cmp.config.window.bordered(), { winblend = 0 }),
        documentation = vim.tbl_extend("force", cmp.config.window.bordered(), { winblend = 0 }),
      })

      opts.view = vim.tbl_extend("force", opts.view or {}, {
        docs = {
          auto_open = true,
        },
        entries = {
          follow_cursor = true,
        },
      })

      opts.experimental = vim.tbl_extend("force", opts.experimental or {}, {
        ghost_text = true,
      })

      opts.mapping = vim.tbl_extend("force", opts.mapping, {
        ["<C-n>"] = cmp.mapping({
          i = cmp.config.disable,
        }),
        ["<C-p>"] = cmp.mapping({
          i = cmp.config.disable,
        }),
        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
          elseif vim.snippet.active({ direction = 1 }) then
            vim.schedule(function()
              vim.snippet.jump(1)
            end)
          elseif has_words_before() then
            cmp.complete({ behavior = cmp.ConfirmBehavior.Replace })
          else
            fallback()
          end
        end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item({ behavior = cmp.SelectBehavior.Select })
          elseif vim.snippet.active({ direction = -1 }) then
            vim.schedule(function()
              vim.snippet.jump(-1)
            end)
          else
            fallback()
          end
        end, { "i", "s" }),
      })
    end,
  },
}
