local constants = require("config.constants")

local hydra = { active = false }
-- prevent recursive calls to show which key menu if hydra is already open
local function hydra_show(keys)
  if hydra.active then
    -- already in which-key loop: pass the key through to which-key
    -- use non-remap so it doesn't trigger this mapping again
    vim.api.nvim_feedkeys(keys, "n", false)
    return
  end
  hydra.active = true
  local ok, err = pcall(function()
    require("which-key").show({ keys = keys, loop = true })
  end)
  hydra.active = false
  if not ok and err then
    vim.notify(err, vim.log.levels.ERROR)
  end
end

return {
  "folke/which-key.nvim",
  keys = {
    {
      "[",
      function()
        hydra_show("[")
      end,
      mode = "n",
      desc = "hydra: [",
    },
    {
      "]",
      function()
        hydra_show("]")
      end,
      mode = "n",
      desc = "hydra: ]",
    },
  },
  opts = {
    show_help = false,
    show_keys = false,
    sort = { "group", "alphanum" },
    triggers = {
      { "<auto>", mode = "nixsotc" },
      { "<leader>", mode = { "n", "x", "v" } },
      { "<localleader>", mode = { "n", "x", "v" } },
    },
    preset = "helix",
    delay = 50,
    win = {
      title = true,
      border = constants.border_chars_outer_thin,
      padding = { 1, 0 },
    },
    layout = {
      align = "left",
    },
    icons = {
      group = "",
      keys = {
        C = "ᴄᴛʀʟ ",
        M = "ᴀʟᴛ ",
        D = "ᴄᴏᴍᴍᴀɴᴅ ",
        S = "󰘶 ",
      },
    },
    plugins = {
      marks = true,
      registers = true,
      spelling = { enabled = true },
    },
    spec = {
      { "<localleader>", name = "Local" },
      { "<leader>?", name = "Buffer Keymaps" },
      { "<leader>q", name = "quit" },
      { "<leader>x", name = "diagnostics" },
      { "<leader>f", name = "file" },
    },
  },
}
