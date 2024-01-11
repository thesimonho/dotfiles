local wezterm = require("wezterm")
local keybinds = require("keybinds")

--wezterm.on("gui-startup", function(cmd)
--	local _, _, window = wezterm.mux.spawn_window(cmd or {})
--	window:gui_window():maximize()
--end)

local is_windows = function()
	return wezterm.target_triple:find("windows") ~= nil
end

local default_prog
local launch_menu

if(is_windows == true) then
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
	launch_menu = {}
end

return {
	show_update_window = true,
	unicode_version = 14,
	color_scheme_dirs = { "~/.config/wezterm/colors" },
	color_scheme = "kanagawa",
	font_size = 11,
	font = wezterm.font_with_fallback({
		{ family = "FiraCode Nerd Font", weight = "Regular" },
		"Source_Code_Pro",
		"JetBrains Mono",
	}),
	harfbuzz_features = { "cv01", "cv02", "ss03", "ss05", "ss07", "ss08" },
	default_cursor_style = "SteadyBar",
	-- force_reverse_video_cursor = true,
	underline_position = -2,
	front_end = "WebGpu",
	webgpu_power_preference = "HighPerformance",
	animation_fps = 60,
	adjust_window_size_when_changing_font_size = false,
	window_padding = {
		left = 0,
		right = 0,
		top = 0,
		bottom = 0,
	},
	window_background_opacity = 0.9,
	window_decorations = "TITLE|RESIZE",
	use_resize_increments = true,
	inactive_pane_hsb = {
		saturation = 0.9,
		brightness = 0.7,
	},
	hide_tab_bar_if_only_one_tab = false,
	use_fancy_tab_bar = true,
	disable_default_key_bindings = true,
	leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 1000 },
	keys = keybinds.basic_binds,
	key_tables = keybinds.key_tables,
	default_prog = default_prog,
	launch_menu = launch_menu,
}
