local wezterm = require("wezterm")
local act = wezterm.action

return {
	color_scheme_dirs = { os.getenv("HOME") .. "/.config/wezterm/colors" },
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
	keys = {
		{ key = "v", mods = "CTRL", action = act.PasteFrom("Clipboard") },
		{ key = "n", mods = "LEADER", action = act.SpawnWindow },
		{ key = "q", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },
		{ key = "w", mods = "LEADER", action = act.PaneSelect },
		{ key = "h", mods = "LEADER", action = act.SplitPane({ direction = "Left" }) },
		{ key = "j", mods = "LEADER", action = act.SplitPane({ direction = "Down" }) },
		{ key = "k", mods = "LEADER", action = act.SplitPane({ direction = "Up" }) },
		{ key = "l", mods = "LEADER", action = act.SplitPane({ direction = "Right" }) },
		{ key = "LeftArrow", mods = "LEADER", action = act.AdjustPaneSize({ "Left", 10 }) },
		{ key = "DownArrow", mods = "LEADER", action = act.AdjustPaneSize({ "Down", 10 }) },
		{ key = "UpArrow", mods = "LEADER", action = act.AdjustPaneSize({ "Up", 10 }) },
		{ key = "RightArrow", mods = "LEADER", action = act.AdjustPaneSize({ "Right", 10 }) },
	},
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
	-- force_reverse_video_cursor = true,
}
