return {
  {
    "nvim-neotest/neotest",
    opts = {
      summary = {
        follow = true,
      },
      output = {
        open_on_run = false,
      },
      quickfix = {
        open = false,
      },
      -- Auto-open the summary panel (right split) whenever a run starts
      consumers = {
        -- auto_open_summary = function(client)
        --   client.listeners.run = function()
        --     require("neotest").summary.open()
        --   end
        --   return {}
        -- end,
      },
    },
  },
}
