local wezterm = require("wezterm")
local keybinds = require("keybinds")

return {
	color_scheme_dirs = { "~/.config/wezterm/colors" },
	color_scheme = "kanagawa",
	font_size = 11,
	font = wezterm.font_with_fallback({
		{ family = "FiraCode NF", weight = "Regular" },
		"Source_Code_Pro",
		"JetBrains Mono",
	}),
	default_cursor_style = "SteadyBar",
	underline_position = -2,
	front_end = "WebGpu",
	webgpu_power_preference = "HighPerformance",
	animation_fps = 60,
	window_padding = {
		left = 0,
		right = 0,
		top = 0,
		bottom = 0,
	},
	window_background_opacity = 0.99,
	use_resize_increments = true,
	inactive_pane_hsb = {
		saturation = 0.9,
		brightness = 0.7,
	},
	use_fancy_tab_bar = true,
	disable_default_key_bindings = true,
	leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 1000 },
	keys = keybinds.basic_binds,
	key_tables = keybinds.key_tables,
	launch_menu = {
		{
			label = "PowerShell",
			args = { "powershell.exe" },
		},
		{
			label = "cmd",
			args = { "cmd.exe" },
		},
	},
}
