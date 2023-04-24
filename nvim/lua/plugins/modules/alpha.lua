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
	local path_ok, plenary_path = pcall(require, "plenary.path")
	if not path_ok then
		return
	end

	math.randomseed(os.time())

	-- Header
	local function apply_gradient_hl(text)
		local gradient = require("utils").create_gradient("#DCA561", "#658594", #text)

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

	local function get_header(headers)
		local header_text = headers[math.random(#headers)]
		return apply_gradient_hl(header_text)
	end

	-- Footer
	local function get_footer(quotes, width)
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
				"<cmd>lua require('telescope.builtin').find_files( { cwd = '"
					.. project.path:gsub("\\", "/")
					.. "' }) <cr>"
			)

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
		{ type = "padding", val = 4 },
		get_header({ headers.cool, headers.panda }),
		{ type = "padding", val = 1 },
		links,
		{ type = "padding", val = 2 },
		get_projects(5),
		{ type = "padding", val = 2 },
		get_mru(7),
		{ type = "padding", val = 3 },
		get_footer({ quotes.roar, quotes.path }, 50),
	}
	require("alpha").setup(theme.config)
end

return M
