local wezterm = require("wezterm")
local config = wezterm.config_builder()
local keybinds = require("keybinds")
local theme = require("theme_switcher")
local utils = require("utils")

config.leader = { key = "Space", mods = "SUPER", timeout_milliseconds = 1500 }
config.adjust_window_size_when_changing_font_size = false
config.animation_fps = 60
config.automatically_reload_config = true
config.color_scheme_dirs = { "~/.config/wezterm/colors" }
config.color_scheme = theme.color_scheme
config.cursor_blink_rate = 0
config.default_cursor_style = "SteadyBar"
config.default_domain = "local"
config.default_workspace = "default"
config.disable_default_key_bindings = true
config.enable_kitty_keyboard = false -- this sends wrong termcodes for Del and BS
config.enable_scroll_bar = false
config.enable_tab_bar = true
config.enable_wayland = true
config.font = wezterm.font_with_fallback({
	{ family = "CaskaydiaCove Nerd Font Mono", weight = "DemiLight" },
	{ family = "FiraCode Nerd Font", weight = "Regular" },
	"Liberation Mono",
})
config.front_end = "WebGpu"
config.harfbuzz_features = { "zero", "cv01", "cv02", "ss03", "ss05", "ss08", "calt=0", "clig=0", "liga=0" }
config.hide_tab_bar_if_only_one_tab = false
config.inactive_pane_hsb = {
	saturation = 0.9,
	brightness = 0.7,
}
config.keys = keybinds.basic_binds
config.key_tables = keybinds.key_tables
config.mux_enable_ssh_agent = false
config.scrollback_lines = 7500
config.show_new_tab_button_in_tab_bar = true
config.tab_and_split_indices_are_zero_based = false
config.tab_max_width = 48
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

local additional_shells = {}
if utils.is_windows() then
	config.font_size = 12
	config.win32_system_backdrop = "Mica"
	config.window_background_opacity = 0
	config.default_prog = { "nu.exe" }
	additional_shells = {
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
elseif utils.is_mac() then
	config.font_size = 16
	config.macos_window_background_blur = 20
	config.window_background_opacity = 0.92
	config.default_prog = { "zsh" }
else
	config.font_size = 12
	config.window_background_opacity = 0.9
	config.kde_window_background_blur = true
	config.default_prog = { "zsh" }
end

config.launch_menu = {}

for _, shell in ipairs(additional_shells) do
	table.insert(config.launch_menu, shell)
end

return config
