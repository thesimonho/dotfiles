local wezterm = require("wezterm")
local keybinds = require("keybinds")

wezterm.on("gui-startup", function()
	-- main workspace
	local tab, pane, window = wezterm.mux.spawn_window({
		workspace = "main",
	})

	-- terminals workspace
	local tab_terms, pane_terms, window_terms = wezterm.mux.spawn_window({
		workspace = "terminals",
	})

	local pane_top = pane_terms:split({
		direction = "Top",
		size = 0.5,
	})

	local pane_right = pane_terms:split({
		direction = "Left",
		size = 0.5,
	})

	local pane_left = pane_top:split({
		direction = "Left",
		size = 0.5,
	})

	window:gui_window():set_inner_size(1080, 600)
end)

local is_windows = function()
	return wezterm.target_triple == "x86_64-pc-windows-msvc"
end

local config = wezterm.config_builder()

config.adjust_window_size_when_changing_font_size = false
config.animation_fps = 60
config.automatically_reload_config = true
config.color_scheme_dirs = { "~/.config/wezterm/colors" }
config.color_scheme = "kanagawa-paper"
config.default_cursor_style = "SteadyBar"
config.default_workspace = "main"
config.disable_default_key_bindings = true
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
config.leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 1500 }
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
local workspace_switcher = wezterm.plugin.require("http://github.com/MLFlexer/smart_workspace_switcher.wezterm")

workspace_switcher.workspace_formatter = function(label)
	return wezterm.format({
		{ Attribute = { Intensity = "Bold" } },
		{ Foreground = { Color = "#8ea4a2" } },
		{ Text = "󱂬: " .. label },
	})
end

wezterm.on("smart_workspace_switcher.workspace_switcher.chosen", function(window, workspace)
	local gui_win = window:gui_window()
	local base_path = string.gsub(workspace, "(.*[/\\])(.*)", "%2")
	gui_win:set_right_status(wezterm.format({
		{ Attribute = { Intensity = "Bold" } },
		{ Foreground = { Color = "#8ea4a2" } },
		{ Text = "󱂬: " .. base_path .. " " },
	}))
end)

wezterm.on("smart_workspace_switcher.workspace_switcher.created", function(window, workspace)
	local gui_win = window:gui_window()
	local base_path = string.gsub(workspace, "(.*[/\\])(.*)", "%2")
	gui_win:set_right_status(wezterm.format({
		{ Attribute = { Intensity = "Bold" } },
		{ Foreground = { Color = "#8ea4a2" } },
		{ Text = "󱂬: " .. base_path .. " " },
	}))
end)

return config
