local wezterm = require("wezterm")
local workspace_switcher = wezterm.plugin.require("http://github.com/MLFlexer/smart_workspace_switcher.wezterm")
local act = wezterm.action
local M = {}

M.basic_binds = {
	{ key = "F1", action = act.ActivateCommandPalette },
	{
		key = "c",
		mods = "CTRL|SHIFT",
		action = wezterm.action_callback(function(window, pane)
			local selection_text = window:get_selection_text_for_pane(pane)
			local is_selection_active = string.len(selection_text) ~= 0
			if is_selection_active then
				window:perform_action(act.CopyTo("Clipboard"), pane)
			else
				window:perform_action(act.SendKey({ key = "c", mods = "CTRL" }), pane)
			end
		end),
	},
	{
		key = "v",
		mods = "CTRL|SHIFT",
		action = act.PasteFrom("Clipboard"),
	},
	{ key = "/", mods = "CTRL", action = act.Search({ CaseInSensitiveString = "" }) },
	{
		key = "f",
		mods = "CTRL",
		action = act.SendString("fzf\r"),
	},
	{
		key = "e",
		mods = "CTRL",
		action = act.SendString("yazi\r"),
	},
	{ key = "t", mods = "CTRL", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "PageUp", action = act.ScrollByPage(-1) },
	{ key = "PageDown", action = act.ScrollByPage(1) },
	{ key = "=", mods = "CTRL", action = act.IncreaseFontSize },
	{ key = "-", mods = "CTRL", action = act.DecreaseFontSize },
	{ key = "0", mods = "CTRL", action = act.ResetFontSize },
	{ key = "v", mods = "LEADER", action = act.ActivateCopyMode },
	{ key = "q", mods = "LEADER", action = act.QuitApplication },
	{ key = "w", mods = "LEADER", action = act.ActivateKeyTable({ name = "window_mode" }) },
	{ key = "r", mods = "LEADER", action = act.ActivateKeyTable({ name = "resize_mode", one_shot = false }) },
	{ key = "p", mods = "ALT", action = workspace_switcher.switch_workspace() },
	-- MacOS rebinds
	{ key = "p", mods = "CMD", action = act.SendKey({ key = "p", mods = "CTRL" }) },
	{ key = "q", mods = "CMD", action = act.SendKey({ key = "q", mods = "CTRL" }) },
	{ key = "v", mods = "CMD", action = act.SendKey({ key = "v", mods = "CTRL" }) },
	{ key = "r", mods = "CMD", action = act.SendKey({ key = "r", mods = "CTRL" }) },
	{ key = "h", mods = "CMD", action = act.SendKey({ key = "h", mods = "CTRL" }) },
	{ key = "j", mods = "CMD", action = act.SendKey({ key = "j", mods = "CTRL" }) },
	{ key = "k", mods = "CMD", action = act.SendKey({ key = "k", mods = "CTRL" }) },
	{ key = "l", mods = "CMD", action = act.SendKey({ key = "l", mods = "CTRL" }) },
	{ key = "d", mods = "CMD", action = act.SendKey({ key = "d", mods = "CTRL" }) },
	{ key = "u", mods = "CMD", action = act.SendKey({ key = "u", mods = "CTRL" }) },
	{ key = "e", mods = "CMD", action = act.SendKey({ key = "e", mods = "CTRL" }) },
}

M.key_tables = {
	window_mode = {
		{ key = "w", action = act.PaneSelect },
		{ key = "n", action = act.SpawnWindow },
		{ key = "[", action = act.ActivateWindowRelative(-1) },
		{ key = "]", action = act.ActivateWindowRelative(1) },
		{ key = "d", action = act.CloseCurrentTab({ confirm = true }) },
		{ key = "h", action = act.ActivatePaneDirection("Left") },
		{ key = "l", action = act.ActivatePaneDirection("Right") },
		{ key = "k", action = act.ActivatePaneDirection("Up") },
		{ key = "j", action = act.ActivatePaneDirection("Down") },
		{ key = "v", action = act.SplitPane({ direction = "Right" }) },
		{ key = "s", action = act.SplitPane({ direction = "Down" }) },
	},
	resize_mode = {
		{ key = "LeftArrow", action = act.AdjustPaneSize({ "Left", 1 }) },
		{ key = "RightArrow", action = act.AdjustPaneSize({ "Right", 1 }) },
		{ key = "UpArrow", action = act.AdjustPaneSize({ "Up", 1 }) },
		{ key = "DownArrow", action = act.AdjustPaneSize({ "Down", 1 }) },
		{ key = "Escape", action = "PopKeyTable" },
	},
}

return M
