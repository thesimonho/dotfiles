local wezterm = require("wezterm")
local theme = require("theme_switcher")

local function find_binary(name)
	local handle = io.popen("command -v " .. name .. " 2>/dev/null")
	if not handle then
		return nil
	end

	local result = handle:read("*a")
	handle:close()

	result = result:gsub("%s+", "")
	if result == "" then
		return nil
	end
	return result
end

local M = {}

-- workspace_switcher
M.workspace_switcher = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")
M.workspace_switcher.zoxide_path = find_binary("zoxide") or "/usr/bin/zoxide"

M.workspace_switcher.workspace_formatter = function(label)
	return wezterm.format({
		{ Attribute = { Intensity = "Bold" } },
		{ Foreground = { Color = "#8ea4a2" } },
		{ Text = "󱂬 : " .. label },
	})
end

wezterm.on("smart_workspace_switcher.workspace_switcher.chosen", function(window, workspace)
	local gui_win = window:gui_window()
	local base_path = string.gsub(workspace, "(.*[/\\])(.*)", "%2")
	gui_win:set_right_status(wezterm.format({
		{ Attribute = { Intensity = "Bold" } },
		{ Foreground = { Color = "#8ea4a2" } },
		{ Text = "󱂬 : " .. base_path .. " " },
	}))
end)

wezterm.on("smart_workspace_switcher.workspace_switcher.created", function(window, workspace)
	local gui_win = window:gui_window()
	local base_path = string.gsub(workspace, "(.*[/\\])(.*)", "%2")
	gui_win:set_right_status(wezterm.format({
		{ Attribute = { Intensity = "Bold" } },
		{ Foreground = { Color = "#8ea4a2" } },
		{ Text = "󱂬 : " .. base_path .. " " },
	}))
end)

-- tabline
M.tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")
M.tabline.setup({
	options = {
		icons_enabled = true,
		theme = require("colors.wezterm_tabline." .. theme.color_scheme),
		section_separators = {
			left = wezterm.nerdfonts.ple_right_half_circle_thick,
			right = wezterm.nerdfonts.ple_left_half_circle_thick,
		},
		component_separators = {
			left = wezterm.nerdfonts.ple_right_half_circle_thin,
			right = wezterm.nerdfonts.ple_left_half_circle_thin,
		},
		tab_separators = {
			left = " ",
			right = "",
		},
	},
	sections = {
		tabline_a = {
			{
				"mode",
				icon = "🐼",
				fmt = function(text)
					return string.lower(text)
				end,
			},
		},
		tabline_b = {
			{ "workspace", padding = { left = 1, right = 0 } },
			-- {
			-- 	"domain",
			-- 	padding = { left = 1, right = 0 },
			-- 	cond = function()
			-- 		if #wezterm.mux.all_domains() > 2 then
			-- 			return true
			-- 		end
			-- 		return false
			-- 	end,
			-- },
		},
		tabline_c = { " " },
		tabline_x = {
			function(window)
				local metadata = window:active_pane():get_metadata()
				if not metadata then
					return ""
				end

				local latency = metadata.since_last_response_ms
				if not latency then
					return ""
				end

				local color
				local icon
				local red = "\27[31m"
				local yellow = "\27[33m"
				local green = "\27[32m"
				if metadata.is_tardy then
					if latency > 10000 then
						color = red
						icon = "󰢼"
						latency = ">999"
					else
						color = yellow
						icon = "󰢽"
					end
				else
					color = green
					icon = "󰢾"
					latency = "<1"
				end
				return string.format(color .. icon .. " %sms ", latency)
			end,
		},
		tabline_y = {
			{
				"datetime",
				style = "%A %b %d",
				icon = "",
				hour_to_icon = false,
			},
		},
		tabline_z = { "hostname" },
		tab_active = {
			{ "process", icons_only = true, padding = { left = 2, right = 0 } },
			{ "parent", max_length = 10, padding = 0 },
			"/",
			{ "cwd", max_length = 15, padding = { left = 0, right = 2 } },
			{ "zoomed", padding = 0 },
		},
		tab_inactive = {
			{ "process", icons_only = true, padding = { left = 2, right = 0 } },
			{ "parent", max_length = 10, padding = 0 },
			"/",
			{ "cwd", max_length = 15, padding = { left = 0, right = 2 } },
		},
	},
	extensions = { "smart_workspace_switcher" },
})

return M
