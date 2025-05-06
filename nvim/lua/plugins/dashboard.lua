local fs = require("utils.fs")
local ui = require("utils.ui")
local headers = require("config.headers")
local quotes = require("config.quotes")

math.randomseed(os.time())

local function format_tbl_text(text)
  return table.concat(text, "\n")
end

local function list_image_files(directory)
  local image_extensions = { ".png", ".jpg", ".jpeg", ".gif", ".bmp", ".webp" }
  local files = {}

  local handle = vim.uv.fs_scandir(directory)
  if not handle then
    return files
  end

  while true do
    local name, type = vim.uv.fs_scandir_next(handle)
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
      cmd = "chafa " .. image_path .. " --format symbols --align center --symbols vhalf --size=70x20; sleep .1",
      height = 22,
    }
  end

  return {
    text = { format_tbl_text(headers[math.random(#headers)]), hl = "String" },
    align = "center",
    padding = 2,
  }
end

local function get_projects()
  local limit = 10
  local dirs = {}

  local iter = Snacks.dashboard.oldfiles()
  while true do
    local file = iter()
    if not file then
      break
    end

    local dir = Snacks.git.get_root(file)
    if dir and not vim.tbl_contains(dirs, dir) then
      table.insert(dirs, dir)
      if #dirs >= limit then
        break
      end
    end
  end

  local ret = {} ---@type snacks.dashboard.Item[]
  for _, dir in ipairs(dirs) do
    ret[#ret + 1] = {
      file = dir,
      icon = "󰊢",
      autokey = true,
      action = function()
        ui.load_project_session(dir)
      end,
    }
  end

  return vim.tbl_map(function(item)
    return vim.tbl_extend("force", {
      pane = 2,
      padding = 0,
      indent = 2,
    }, item)
  end, ret)
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
        width = 70,
        pane_gap = 15,
        autokeys = "1234567890abcdefghijklmnopqrstuvwxyz",
        preset = {
          keys = {
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
          { pane = 2, title = "Projects", icon = "" },
          get_projects,
        },
        formats = {
          key = function(item)
            return { { "[", hl = "Special2" }, { item.key, hl = "WindowPickerStatusLine" }, { "]", hl = "Special2" } }
          end,
        },
      },
    },
  },
}

return M
