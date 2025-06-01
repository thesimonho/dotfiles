local wezterm = require("wezterm")
local theme = require("theme_switcher")

local M = {}

-- workspace_switcher
-- M.workspace_switcher = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")
--
-- M.workspace_switcher.workspace_formatter = function(label)
-- 	return wezterm.format({
-- 		{ Attribute = { Intensity = "Bold" } },
-- 		{ Foreground = { Color = "#8ea4a2" } },
-- 		{ Text = "󱂬 : " .. label },
-- 	})
-- end
--
-- wezterm.on("smart_workspace_switcher.workspace_switcher.chosen", function(window, workspace)
-- 	local gui_win = window:gui_window()
-- 	local base_path = string.gsub(workspace, "(.*[/\\])(.*)", "%2")
-- 	gui_win:set_right_status(wezterm.format({
-- 		{ Attribute = { Intensity = "Bold" } },
-- 		{ Foreground = { Color = "#8ea4a2" } },
-- 		{ Text = "󱂬 : " .. base_path .. " " },
-- 	}))
-- end)
--
-- wezterm.on("smart_workspace_switcher.workspace_switcher.created", function(window, workspace)
-- 	local gui_win = window:gui_window()
-- 	local base_path = string.gsub(workspace, "(.*[/\\])(.*)", "%2")
-- 	gui_win:set_right_status(wezterm.format({
-- 		{ Attribute = { Intensity = "Bold" } },
-- 		{ Foreground = { Color = "#8ea4a2" } },
-- 		{ Text = "󱂬 : " .. base_path .. " " },
-- 	}))
--
-- 	-- TODO: auto launch container if there is one
-- 	-- gui_win:perform_action(act.SendString("nvim ."), gui_win:active_pane())
-- 	-- gui_win:perform_action(act.SendKey({ key = "Enter" }), gui_win:active_pane())
-- end)

-- tabline
M.tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")
M.tabline.setup({
	options = {
		icons_enabled = true,
		theme_overrides = require("colors.wezterm_tabline." .. theme.color_scheme).theme_overrides,
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
			{ "domain", padding = { left = 1, right = 0 } },
		},
		tabline_c = { " " },
		tabline_x = { { "cpu" }, { "ram" } },
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
		},
		tab_inactive = {
			{ "process", icons_only = true, padding = { left = 2, right = 0 } },
			{ "parent", max_length = 10, padding = 0 },
			"/",
			{ "cwd", max_length = 15, padding = { left = 0, right = 2 } },
		},
	},
	-- extensions = { "smart_workspace_switcher" },
})

return M
