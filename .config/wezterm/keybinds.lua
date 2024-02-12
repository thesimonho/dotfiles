local wezterm = require("wezterm")
local act = wezterm.action
local M = {}

M.basic_binds = {
	{
    key = 'c', mods = 'CTRL',
    action = wezterm.action_callback(function(window, pane)
        selection_text = window:get_selection_text_for_pane(pane)
        is_selection_active = string.len(selection_text) ~= 0
        if is_selection_active then
            window:perform_action(act.CopyTo('Clipboard'), pane)
        else
            window:perform_action(act.SendKey{ key='c', mods='CTRL' }, pane)
        end
    end),
	},
	{ key = "v", mods = "CTRL", action = act.PasteFrom("Clipboard") },
	{ key = "p", mods = "CTRL", action = act.ActivateCommandPalette },
	{ key = "v", mods = "LEADER", action = act.ActivateCopyMode },
	{ key = 'q', mods = 'LEADER', action = act.QuitApplication },
	{ key = "j", mods = "LEADER", action = act.ShowTabNavigator },
	{ key = "w", mods = "LEADER", action = act.ActivateKeyTable({ name = "manage_pane" }) },
	{ key = "r", mods = "LEADER", action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false }) },
}

M.key_tables = {
	manage_pane = {
		{ key = "w", action = act.PaneSelect },
		{ key = "n", action = act.SpawnWindow },
		{ key = "d", action = act.CloseCurrentPane({ confirm = true }) },
		{ key = "h", action = act.ActivatePaneDirection("Left") },
		{ key = "l", action = act.ActivatePaneDirection("Right") },
		{ key = "k", action = act.ActivatePaneDirection("Up") },
		{ key = "j", action = act.ActivatePaneDirection("Down") },
		{ key = "v", action = act.SplitPane({ direction = "Right" }) },
		{ key = "s", action = act.SplitPane({ direction = "Down" }) },
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
