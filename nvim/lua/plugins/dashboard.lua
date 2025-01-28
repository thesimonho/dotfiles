local fs = require("utils.fs")
local headers = require("config.headers")
local quotes = require("config.quotes")

math.randomseed(os.time())

local function format_tbl_text(text)
  return table.concat(text, "\n")
end

local function list_image_files(directory)
  local image_extensions = { ".png", ".jpg", ".jpeg", ".gif", ".bmp", ".webp" }
  local files = {}

  local handle = vim.loop.fs_scandir(directory)
  if not handle then
    return files
  end

  while true do
    local name, type = vim.loop.fs_scandir_next(handle)
    if not name then
      break
    end

    if type == "file" then
      for _, ext in ipairs(image_extensions) do
        if name:sub(-#ext):lower() == ext then
          table.insert(files, name)
        end
      end
    end
  end
  return files
end

local function choose_header(use_image)
  if use_image then
    local path_wallpapers = vim.fn.stdpath("config") .. fs.get_path_sep() .. "wallpapers"
    local images = list_image_files(path_wallpapers)
    local image_path = path_wallpapers .. fs.get_path_sep() .. images[math.random(#images)]

    return {
      section = "terminal",
      cmd = "chafa " .. image_path .. " --format symbols --align center --symbols vhalf --size=60x20; sleep .1",
      height = 20,
    }
  end

  return {
    text = { format_tbl_text(headers[math.random(#headers)]), hl = "String" },
    align = "center",
    padding = 2,
  }
end

local M = {
  {
    "folke/snacks.nvim",
    opts = {
      styles = {
        dashboard = {
          wo = {
            foldcolumn = "0",
          },
        },
      },
      dashboard = {
        width = 60,
        pane_gap = 15,
        preset = {
          keys = {
            {
              icon = " ",
              key = "c",
              desc = "Config",
              action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
            },
            { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy", enabled = package.loaded.lazy ~= nil },
            { icon = "󰟾 ", key = "m", desc = "Mason", action = ":Mason" },
          },
        },
        sections = {
          choose_header(({ true, false })[math.random(2)]), -- randomize between image and text header
          { section = "startup", padding = 1 },
          { section = "keys", padding = 4 },
          {
            text = { "  " .. format_tbl_text(quotes[math.random(#quotes)]), hl = "Comment" },
            align = "right",
            padding = 2,
          },
          { pane = 2, header = "Recent", padding = 2 },
          {
            pane = 2,
            icon = " ",
            title = "Files",
            section = "recent_files",
            limit = 10,
            indent = 2,
            padding = 2,
          },
          { pane = 2, icon = " ", title = "Projects", section = "projects", limit = 10, indent = 2, padding = 2 },
        },
        formats = {
          key = function(item)
            return { { "[", hl = "Special" }, { item.key, hl = "WindowPickerStatusLine" }, { "]", hl = "Special" } }
          end,
        },
      },
    },
  },
}

return M
