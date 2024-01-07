local wezterm = require("wezterm")
local act = wezterm.action
local M = {}

M.basic_binds = {
	{ key = "v", mods = "CTRL", action = act.PasteFrom("Clipboard") },
	{ key = "p", mods = "CTRL|SHIFT", action = act.ActivateCommandPalette },
	{ key = "n", mods = "LEADER", action = act.SpawnWindow },
	{ key = "w", mods = "LEADER", action = act.ActivateKeyTable({ name = "manage_pane" }) },
	{ key = "r", mods = "LEADER", action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false }) },
}

M.key_tables = {
	manage_pane = {
		{ key = "w", action = act.PaneSelect },
		{ key = "q", action = act.CloseCurrentPane({ confirm = true }) },
		{ key = "h", action = act.ActivatePaneDirection("Left") },
		{ key = "l", action = act.ActivatePaneDirection("Right") },
		{ key = "k", action = act.ActivatePaneDirection("Up") },
		{ key = "j", action = act.ActivatePaneDirection("Down") },
		{ key = "H", action = act.SplitPane({ direction = "Left" }) },
		{ key = "L", action = act.SplitPane({ direction = "Right" }) },
		{ key = "K", action = act.SplitPane({ direction = "Up" }) },
		{ key = "J", action = act.SplitPane({ direction = "Down" }) },
	},
	resize_pane = {
		{ key = "LeftArrow", action = act.AdjustPaneSize({ "Left", 1 }) },
		{ key = "RightArrow", action = act.AdjustPaneSize({ "Right", 1 }) },
		{ key = "UpArrow", action = act.AdjustPaneSize({ "Up", 1 }) },
		{ key = "DownArrow", action = act.AdjustPaneSize({ "Down", 1 }) },
		{ key = "Escape", action = "PopKeyTable" },
	},
}

return M
