local wezterm = require("wezterm")
local keybinds = require("keybinds")
local theme = require("theme_switcher")
local act = wezterm.action

wezterm.on("gui-startup", function(cmd)
	local _, _, window = wezterm.mux.spawn_window(cmd or {
		workspace = "main",
	})
	window:gui_window()
	local screens = wezterm.gui.screens()
	local proportion = 0.6
	local width = math.floor(screens.active.width * proportion)
	local height = math.floor(screens.active.height * proportion)
	window:gui_window():set_inner_size(width, height)
end)

local is_windows = function()
	return wezterm.target_triple == "x86_64-pc-windows-msvc"
end

local is_mac = function()
	return wezterm.target_triple == "aarch64-apple-darwin"
end

local config = wezterm.config_builder()

config.leader = { key = "Super", timeout_milliseconds = 1500 }
config.adjust_window_size_when_changing_font_size = false
config.animation_fps = 60
config.automatically_reload_config = true
config.color_scheme_dirs = { "~/.config/wezterm/colors" }
config.color_scheme = theme.color_scheme
config.cursor_blink_rate = 0
config.default_cursor_style = "SteadyBar"
config.default_workspace = "main"
config.disable_default_key_bindings = true
config.enable_scroll_bar = false
config.enable_wayland = true
config.font = wezterm.font_with_fallback({
	{ family = "MonaspiceRn Nerd Font", weight = "Book" },
	{ family = "MonaspiceNe Nerd Font", weight = "Regular" },
	{ family = "MonaspiceAr Nerd Font", weight = "Regular" },
	{ family = "MonaspiceKr Nerd Font", weight = "Regular" },
	{ family = "MonaspiceXe Nerd Font", weight = "Regular" },
	{ family = "Monofur Nerd Font", weight = "Regular" },
	{ family = "FiraCode Nerd Font", weight = "Regular" },
	"Liberation Mono",
})
config.front_end = "OpenGL"
config.harfbuzz_features = { "zero", "cv01", "cv02", "ss03", "ss05", "ss07", "ss08", "calt", "clig=0", "liga=0" }
config.hide_tab_bar_if_only_one_tab = false
config.inactive_pane_hsb = {
	saturation = 0.9,
	brightness = 0.7,
}
config.keys = keybinds.basic_binds
config.key_tables = keybinds.key_tables
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

if is_windows() then
	config.font_size = 12
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
			label = "Command Prompt",
			args = { "cmd.exe" },
		},
	}
elseif is_mac() then
	config.font_size = 16
	config.macos_window_background_blur = 60
	config.window_background_opacity = 1.0
	config.default_prog = { "/opt/homebrew/bin/nu" }
	config.launch_menu = {
		{
			label = "nu",
			args = { "/opt/homebrew/bin/nu" },
		},
		{
			label = "zsh",
			args = { "zsh" },
		},
		{
			label = "bash",
			args = { "bash" },
		},
	}
else
	config.font_size = 12
	config.window_background_opacity = 0.95
	config.default_prog = { "/home/linuxbrew/.linuxbrew/bin/nu" }
	config.launch_menu = {
		{
			label = "nu",
			args = { "/home/linuxbrew/.linuxbrew/bin/nu" },
		},
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
tabline.setup({
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
		tabline_b = { "workspace" },
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
	extensions = { "smart_workspace_switcher" },
})

return config
