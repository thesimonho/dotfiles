local wezterm = require("wezterm")
local keybinds = require("keybinds")

wezterm.on("gui-startup", function(cmd)
	local _, _, window = wezterm.mux.spawn_window(cmd or {})
	-- window:gui_window():maximize()
	window:gui_window():set_inner_size(1080, 600)
end)

local is_windows = function()
	return wezterm.target_triple == "x86_64-pc-windows-msvc"
end

local c = {
	adjust_window_size_when_changing_font_size = false,
	animation_fps = 60,
	automatically_reload_config = true,
	color_scheme_dirs = { "~/.config/wezterm/colors" },
	color_scheme = "kanagawa-paper",
	default_cursor_style = "SteadyBar",
	disable_default_key_bindings = true,
	enable_scroll_bar = false,
	enable_wayland = true,
	font = wezterm.font_with_fallback({
		{ family = "FiraCode Nerd Font", weight = "Regular" },
		"Source_Code_Pro",
		"JetBrains Mono",
	}),
	front_end = "OpenGL",
	harfbuzz_features = { "cv01", "cv02", "ss03", "ss05", "ss07", "ss08", "calt=0", "clig=0", "liga=0" },
	hide_tab_bar_if_only_one_tab = true,
	inactive_pane_hsb = {
		saturation = 0.9,
		brightness = 0.7,
	},
	scrollback_lines = 7500,
	show_update_window = true,
	underline_position = -2,
	unicode_version = 14,
	use_fancy_tab_bar = true,
	use_resize_increments = true,
	webgpu_power_preference = "HighPerformance",
	window_background_opacity = 0.95,
	window_close_confirmation = "NeverPrompt",
	window_decorations = "TITLE|RESIZE",
	window_padding = {
		left = 0,
		right = 0,
		top = 0,
		bottom = 0,
	},
	leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 1500 },
	keys = keybinds.basic_binds,
	key_tables = keybinds.key_tables,
}

if is_windows() then
	c.font_size = 11
	c.default_prog = { "nu.exe" }
	c.launch_menu = {
		{
			label = "nushell",
			args = { "nu.exe" },
		},
		{
			label = "PowerShell",
			args = { "pwsh.exe" },
		},
		{
			label = "cmd",
			args = { "cmd.exe" },
		},
	}
else
	c.font_size = 16
	c.default_prog = { "zsh", "-l" }
	c.launch_menu = {
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

return c
