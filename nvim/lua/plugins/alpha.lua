local M = {
  "goolord/alpha-nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  event = "VimEnter",
}

function M.config()
  local headers = require("config.headers")
  local quotes = require("config.quotes")
  local utils = require("config.utils")
  local pickers = require("config/telescope_pickers")
  local theme = require("alpha.themes.theta")
  local path_ok, plenary_path = pcall(require, "plenary.path")
  if not path_ok then
    return
  end

  math.randomseed(os.time())

  -- Header
  local function apply_gradient_hl(text)
    local gradient = utils.create_gradient("#DCA561", "#658594", #text)

    local lines = {}
    for i, line in ipairs(text) do
      local tbl = {
        type = "text",
        val = line,
        opts = {
          hl = "HeaderGradient" .. i,
          shrink_margin = false,
          position = "center",
        },
      }
      table.insert(lines, tbl)

      -- create hl group
      vim.api.nvim_set_hl(0, "HeaderGradient" .. i, { fg = gradient[i] })
    end

    return {
      type = "group",
      val = lines,
      opts = { position = "center" },
    }
  end

  local function get_header(header_list)
    local header_text = header_list[math.random(#header_list)]
    return apply_gradient_hl(header_text)
  end

  -- Footer
  local function get_footer(quote_list, width)
    local quote_text = quote_list[math.random(#quote_list)]

    local max_width = width or 35

    local tbl = {}
    for _, text in ipairs(quote_text) do
      local padded_text = utils.pad_string(text, max_width, "right")
      table.insert(tbl, { type = "text", val = padded_text, opts = { hl = "Comment", position = "center" } })
    end

    return {
      type = "group",
      val = tbl,
      opts = {},
    }
  end

  -- Info section
  local function get_info()
    local lazy_stats = require("lazy").stats()
    local total_plugins =
      string.format(" %d/%d (%dms)", lazy_stats.loaded, lazy_stats.count, math.floor(lazy_stats.times.LazyDone))
    local datetime = os.date(" %a %B %d")
    local version = vim.version()
    local nvim_version_info = string.format(" %d.%d.%d", version.major, version.minor, version.patch)

    local info_string = string.format("%s  |  %s  |  %s", datetime, total_plugins, nvim_version_info)

    return {
      type = "text",
      val = info_string,
      opts = {
        hl = "SpecialComment",
        position = "center",
      },
    }
  end

  -- Links / tools
  local dashboard = require("alpha.themes.dashboard")
  local lazy = dashboard.button("l", "💤 Lazy", "<cmd>Lazy<CR>")
  lazy.opts.hl_shortcut = "WindowPickerStatusLine"
  local mason = dashboard.button("m", "🧱 Mason", "<cmd>Mason<CR>")
  mason.opts.hl_shortcut = "WindowPickerStatusLine"

  local links = {
    type = "group",
    val = {
      lazy,
      mason,
    },
    position = "center",
  }

  -- MRU
  local function file_button(fn, sc, short_fn, autocd)
    short_fn = short_fn or fn
    local ico_txt
    local fb_hl = {}

    local ico, hl = utils.get_web_icon(fn)
    table.insert(fb_hl, { hl, 0, #ico })
    ico_txt = ico .. "  "

    local cd_cmd = (autocd and " | cd %:p:h" or "")
    local file_button_el =
      dashboard.button(sc, ico_txt .. short_fn, "<cmd>e " .. vim.fn.fnameescape(fn) .. cd_cmd .. " <CR>")
    local fn_start = short_fn:match(".*[/\\]")
    if fn_start ~= nil then
      table.insert(fb_hl, { "Comment", #ico_txt - 2, #fn_start + #ico_txt })
    end
    file_button_el.opts.hl = fb_hl
    return file_button_el
  end

  local function get_mru(items_number, opts)
    local oldfiles = {}
    for _, v in pairs(vim.v.oldfiles) do
      if #oldfiles == items_number then
        break
      end
      if vim.fn.filereadable(v) == 1 then
        oldfiles[#oldfiles + 1] = v
      end
    end

    local target_width = 35

    local tbl = {
      { type = "text", val = "Recent Files", opts = { hl = "SpecialComment", position = "center" } },
    }

    for i, fn in ipairs(oldfiles) do
      local short_fn
      local parts = vim.split(fn, plenary_path.path.sep)
      local max_parents = math.min(4, #parts - 1)

      repeat
        short_fn = table.concat(parts, plenary_path.path.sep, #parts - max_parents, #parts)
        max_parents = max_parents - 1
      until #short_fn < target_width or max_parents == 0 or #parts == max_parents

      local shortcut = tostring(i)
      local file_button_el = file_button(fn, shortcut, short_fn, opts.autocd)
      file_button_el.opts.hl_shortcut = "WindowPickerStatusLine"
      tbl[i + 1] = file_button_el
    end

    return {
      type = "group",
      val = tbl,
      opts = {},
    }
  end

  -- Projects
  local function get_projects(max_shown)
    local alphabet = "abcdefghinopqrstuvwxyz"

    local tbl = {
      { type = "text", val = "Recent Projects", opts = { hl = "SpecialComment", position = "center" } },
    }

    local success, project_list = pcall(require("telescope._extensions.project.utils").get_projects)
    if not success then
      return { type = "text", val = "No projects found", opts = { hl = "SpecialComment", position = "center" } }
    end

    for i, project in ipairs(project_list) do
      if i > max_shown then
        break
      end

      local icon = "📁 "

      -- create shortened path for display
      local target_width = 35
      local display_path = project.path:gsub("/", "\\"):gsub("\\\\", "\\")
      if #display_path > target_width then
        display_path = plenary_path.new(display_path):shorten(1, { -2, -1 })
        if #display_path > target_width then
          display_path = plenary_path.new(display_path):shorten(1, { -1 })
        end
      end

      -- get semantic letter for project
      local letter
      local project_name = display_path:match("[/\\][%w%s%.%-]*$")
      if project_name == nil then
        project_name = display_path
      end
      project_name = project_name:gsub("[/\\]", "")
      letter = string.sub(project_name, 1, 1):lower()

      -- get alternate letter if not available
      if string.find(alphabet, letter) == nil then
        letter = string.sub(alphabet, 1, 1):lower()
      end

      -- remove letter from available alphabet
      alphabet = alphabet:gsub(letter, "")

      -- create button element
      local file_button_el = dashboard.button(
        letter,
        icon .. display_path,
        "<cmd>lua require('config.telescope_pickers').prettyFilesPicker({picker = 'find_files', options = {cwd = '"
          .. project.path:gsub("\\", "/")
          .. "'}})<cr>"
      )
      file_button_el.opts.hl_shortcut = "WindowPickerStatusLine"

      -- create hl group for the start of the path
      local fb_hl = {}
      table.insert(fb_hl, { "Comment", 0, #icon + #display_path - #project_name })
      file_button_el.opts.hl = fb_hl

      table.insert(tbl, file_button_el)
    end

    return {
      type = "group",
      val = tbl,
      opts = {},
    }
  end

  -- Layout
  theme.config.layout = {
    { type = "padding", val = 2 },
    get_header({ headers.cool, headers.vim, headers.panda, headers.snorlax, headers.undertale }),
    { type = "padding", val = 1 },
    get_info(),
    { type = "padding", val = 1 },
    links,
    { type = "padding", val = 2 },
    get_projects(5),
    { type = "padding", val = 2 },
    get_mru(5, { autocd = false }),
    { type = "padding", val = 2 },
    get_footer({ quotes.roar, quotes.path, quotes.fear, quotes.gd }, 50),
  }
  require("alpha").setup(theme.config)
end

return M
