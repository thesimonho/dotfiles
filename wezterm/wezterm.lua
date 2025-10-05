local wezterm = require("wezterm")
local config = require("config")
require("plugins")

wezterm.on("gui-startup", function(cmd)
	local _, _, window = wezterm.mux.spawn_window(cmd or {
		workspace = "local",
	})
	window:gui_window()
	local screens = wezterm.gui.screens()
	local proportion = 0.6
	local width = math.floor(screens.active.width * proportion)
	local height = math.floor(screens.active.height * proportion)
	window:gui_window():set_inner_size(width, height)
end)

return config
