local wezterm = require("wezterm")
local keybinds = require("keybinds")
local act = wezterm.action

wezterm.on("gui-startup", function()
	local _, _, window = wezterm.mux.spawn_window({
		workspace = "main",
	})

	window:gui_window():set_inner_size(1080, 600)
end)

local is_windows = function()
	return wezterm.target_triple == "x86_64-pc-windows-msvc"
end

local config = wezterm.config_builder()

config.leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 1500 }
config.adjust_window_size_when_changing_font_size = false
config.animation_fps = 60
config.automatically_reload_config = true
config.color_scheme_dirs = { "~/.config/wezterm/colors" }
config.color_scheme = "kanagawa-paper"
config.default_cursor_style = "SteadyBar"
config.default_workspace = "main"
config.disable_default_key_bindings = true
config.enable_kitty_keyboard = true
config.enable_scroll_bar = false
config.enable_wayland = true
config.font = wezterm.font_with_fallback({
	{ family = "FiraCode Nerd Font", weight = "Regular" },
	"JetBrains Mono",
})
config.front_end = "OpenGL"
config.harfbuzz_features = { "cv01", "cv02", "ss03", "ss05", "ss07", "ss08", "calt=0", "clig=0", "liga=0" }
config.hide_tab_bar_if_only_one_tab = false
config.inactive_pane_hsb = {
	saturation = 0.9,
	brightness = 0.7,
}
config.scrollback_lines = 7500
config.tab_and_split_indices_are_zero_based = true
config.tab_max_width = 32
config.ui_key_cap_rendering = "WindowsSymbols"
config.underline_position = -2
config.unicode_version = 14
config.use_fancy_tab_bar = false
config.use_resize_increments = true
config.warn_about_missing_glyphs = false
config.webgpu_power_preference = "HighPerformance"
config.window_close_confirmation = "NeverPrompt"
config.window_decorations = "TITLE|RESIZE"
config.window_padding = {
	left = 0,
	right = 0,
	top = 0,
	bottom = 0,
}
config.colors = {
	tab_bar = {
		background = "#282834",
		new_tab = {
			bg_color = "#282834",
			fg_color = "#808080",
		},
		new_tab_hover = {
			bg_color = "#363646",
			fg_color = "#ddd8bb",
		},
	},
}

config.keys = keybinds.basic_binds
config.key_tables = keybinds.key_tables

if is_windows() then
	config.font_size = 11
	config.win32_system_backdrop = "Mica"
	config.window_background_opacity = 0
	config.default_prog = { "nu.exe" }
	config.launch_menu = {
		{
			label = "nushell",
			args = { "nu.exe" },
		},
		{
			label = "PowerShell",
			args = { "pwsh.exe" },
		},
		{
			label = "config.d",
			args = { "config.d.exe" },
		},
	}
else
	config.font_size = 16
	config.macos_window_background_blur = 60
	config.window_background_opacity = 0.9
	config.default_prog = { "zsh", "-l" }
	config.launch_menu = {
		{
			label = "zsh",
			args = { "zsh" },
		},
		{
			label = "bash",
			args = { "bash" },
		},
	}
end

-- workspace_switcher
local workspace_switcher = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")

workspace_switcher.workspace_formatter = function(label)
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

	gui_win:perform_action(act.SendString("nvim ."), gui_win:active_pane())
	gui_win:perform_action(act.SendKey({ key = "Enter" }), gui_win:active_pane())
end)

-- tabline
local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")
print(tabline.get_colors())
tabline.setup({
	options = {
		icons_enabled = true,
		theme = "kanagawabones",
		color_overrides = {
			normal_mode = {
				a = { fg = "#282834", bg = "#7eb3c9" },
				b = { fg = "#7eb3c9", bg = "#353545" },
				c = { fg = "#696861", bg = "#282834" },
			},
			copy_mode = {
				a = { fg = "#282834", bg = "#98bc6d" },
				b = { fg = "#98bc6d", bg = "#353545" },
				c = { fg = "#696861", bg = "#282834" },
			},
			search_mode = {
				a = { fg = "#282834", bg = "#957fb8" },
				b = { fg = "#957fb8", bg = "#353545" },
				c = { fg = "#696861", bg = "#282834" },
			},
			window_mode = {
				a = { fg = "#282834", bg = "#e5c283" },
				b = { fg = "#e5c283", bg = "#353545" },
				c = { fg = "#696861", bg = "#282834" },
			},
			resize_mode = {
				a = { fg = "#282834", bg = "#e46a78" },
				b = { fg = "#e46a78", bg = "#353545" },
				c = { fg = "#696861", bg = "#282834" },
			},
			tab = {
				active = { fg = "#7eb3c9", bg = "#353545" },
				inactive = { fg = "#696861", bg = "#282834" },
				inactive_hover = { fg = "#7eb3c9", bg = "#353545" },
			},
		},
		section_separators = {
			left = wezterm.nerdfonts.ple_right_half_circle_thick,
			right = wezterm.nerdfonts.ple_left_half_circle_thick,
		},
		component_separators = {
			left = wezterm.nerdfonts.ple_right_half_circle_thin,
			right = wezterm.nerdfonts.ple_left_half_circle_thin,
		},
		tab_separators = {
			left = wezterm.nerdfonts.ple_right_half_circle_thick,
			right = wezterm.nerdfonts.ple_left_half_circle_thick,
		},
	},
	sections = {
		tabline_a = { "mode" },
		tabline_b = { "workspace" },
		tabline_c = { "  " },
		tabline_x = { { "cpu" }, { "ram" } },
		tabline_y = { "datetime" },
		tabline_z = { "hostname" },
		tab_active = {
			" ",
			{ "cwd", padding = { left = 0, right = 1 } },
		},
		tab_inactive = {
			" ",
			{ "cwd", padding = { left = 0, right = 1 } },
		},
	},
	extensions = { "smart_workspace_switcher" },
})

return config
