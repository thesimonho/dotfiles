local M = {
	"goolord/alpha-nvim",
	enabled = true,
	dependencies = { "nvim-tree/nvim-web-devicons" },
	event = "VimEnter",
}

function M.config()
	local headers = require("headers")
	local quotes = require("quotes")
	local theme = require("alpha.themes.theta")

	-- Header
	local function get_header(headers)
		math.randomseed(os.time())
		local header_text = headers[math.random(#headers)]
		return {
			type = "text",
			val = header_text,
			opts = {
				position = "center",
				hl = "Boolean",
			},
		}
	end

	-- Footer
	local function get_footer(quotes, width)
		math.randomseed(os.time())
		local quote_text = quotes[math.random(#quotes)]

		local max_width = width or 35

		local tbl = {}
		for _, text in ipairs(quote_text) do
			local padded_text = require("utils").pad_string(text, max_width, "right")
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
		local total_plugins = " " .. lazy_stats.loaded .. "/" .. lazy_stats.count .. " packages"
		local datetime = os.date(" %A %B %d")
		local version = vim.version()
		local nvim_version_info = "ⓥ " .. version.major .. "." .. version.minor .. "." .. version.patch

		local info_string = datetime .. "  |  " .. total_plugins .. "  |  " .. nvim_version_info

		return {
			type = "text",
			val = info_string,
			opts = {
				hl = "Delimiter",
				position = "center",
			},
		}
	end

	-- Links / tools
	local dashboard = require("alpha.themes.dashboard")
	local links = {
		type = "group",
		val = {
			{ type = "text", val = "Tools", opts = { hl = "SpecialComment", position = "center" } },
			dashboard.button("l", "💤 Lazy", "<cmd>Lazy<CR>"),
			dashboard.button("m", "🧱 Mason", "<cmd>Mason<CR>"),
		},
		position = "center",
	}

	-- MRU
	local function get_mru(max_shown)
		local tbl = {
			{ type = "text", val = "Recent Files", opts = { hl = "SpecialComment", position = "center" } },
		}

		local mru_list = theme.mru(1, "", max_shown)
		for _, file in ipairs(mru_list.val) do
			table.insert(tbl, file)
		end

		return { type = "group", val = tbl, opts = {} }
	end

	-- Projects
	local function get_projects(max_shown)
		local alphabet = "abcdefghijknopqrstuvwxyz"

		local tbl = {
			{ type = "text", val = "Recent Projects", opts = { hl = "SpecialComment", position = "center" } },
		}

		local project_list = require("telescope._extensions.project.utils").get_projects("recent")
		for i, project in ipairs(project_list) do
			if i > max_shown then
				break
			end

			local icon = "📁 "
			local path_escape = project.path:gsub("\\", "\\\\")

			-- get semantic letter for project
			local letter
			local project_shortname = project.title:match("[/\\][%a.]*$")
			if project_shortname == nil then
				letter = string.sub(project.title, 1, 1):lower()
				project_shortname = project.title
			else
				letter = string.sub(project_shortname, 2, 2):lower()
				project_shortname = project_shortname:gsub("[/\\]", "")
			end

			-- get alternate letter if not available
			if string.find(alphabet, letter) == nil then
				letter = string.sub(alphabet, 1, 1):lower()
			end

			-- remove letter from available alphabet
			alphabet = alphabet:gsub(letter, "")

			-- create button element
			local file_button_el = dashboard.button(
				letter,
				icon .. project.title,
				"<cmd>lua require('telescope.builtin').find_files( { cwd = '" .. path_escape .. "' }) <cr>"
			)

			-- create hl group for the start of the path
			local fb_hl = {}
			local path_parents = project.title:match("[/\\].*$")
			if path_parents ~= nil then
				table.insert(fb_hl, { "Comment", 0, #icon + #project.title - #project_shortname })
			end
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
		{ type = "padding", val = 4 },
		get_header({ headers.cool, headers.panda }),
		{ type = "padding", val = 1 },
		-- get_info(),
		-- { type = "padding", val = 2 },
		links,
		{ type = "padding", val = 2 },
		get_projects(5),
		{ type = "padding", val = 2 },
		get_mru(5),
		{ type = "padding", val = 3 },
		get_footer({ quotes.roar }, 50),
	}
	require("alpha").setup(theme.config)
end

return M
