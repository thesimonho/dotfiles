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

local default_prog
local launch_menu

if is_windows then
	default_prog = { "nu.exe" }
	launch_menu = {
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
	default_prog = { "nu" }
	launch_menu = {
		{
			label = "nu",
			args = { "nu" },
		},
		{
			label = "bash",
			args = { "bash" },
		},
	}
end

return {
	adjust_window_size_when_changing_font_size = false,
	animation_fps = 60,
	automatically_reload_config = true,
	color_scheme_dirs = { "~/.config/wezterm/colors" },
	color_scheme = "kanagawa",
	default_cursor_style = "SteadyBar",
	disable_default_key_bindings = true,
	enable_scroll_bar = true,
	enable_wayland = true,
	font_size = 11,
	font = wezterm.font_with_fallback({
		{ family = "FiraCode Nerd Font", weight = "Regular" },
		"Source_Code_Pro",
		"JetBrains Mono",
	}),
	front_end = "OpenGL",
	harfbuzz_features = { "cv01", "cv02", "ss03", "ss05", "ss07", "ss08" },
	hide_tab_bar_if_only_one_tab = false,
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
	default_prog = default_prog,
	launch_menu = launch_menu,
}
