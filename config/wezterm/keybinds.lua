local wezterm = require("wezterm")
local workspace_switcher = wezterm.plugin.require("http://github.com/MLFlexer/smart_workspace_switcher.wezterm")
local act = wezterm.action

local function move_or_split(win, pane, direction)
	local tab = pane:tab()
	if tab:get_pane_direction(direction) ~= nil then
		win:perform_action(act.ActivatePaneDirection(direction), pane)
		return
	end
	win:perform_action(act.SplitPane({ direction = direction }), pane)
end

local M = {}

M.basic_binds = {
	{ key = "F1", mods = "SUPER", action = act.ActivateCommandPalette },
	{ key = "p", mods = "CTRL", action = act.ActivateCommandPalette },
	{ key = "p", mods = "SUPER", action = workspace_switcher.switch_workspace() },
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
	-- BUG: conflicts with neovim bind. should only activate in wezterm pane
	-- { key = "u", mods = "CTRL", action = act.ScrollByPage(-0.3) },
	-- { key = "d", mods = "CTRL", action = act.ScrollByPage(0.3) },
	{ key = "PageUp", action = act.ScrollByPage(-0.3) },
	{ key = "PageDown", action = act.ScrollByPage(0.3) },
	{ key = "=", mods = "CTRL", action = act.IncreaseFontSize },
	{ key = "-", mods = "CTRL", action = act.DecreaseFontSize },
	{ key = "0", mods = "CTRL", action = act.ResetFontSize },
	{ key = "y", mods = "LEADER", action = act.ActivateCopyMode },
	{ key = "q", mods = "LEADER", action = act.QuitApplication },
	{ key = "`", mods = "LEADER", action = act.ActivateLastTab },
	{
		key = "h",
		mods = "SUPER",
		action = wezterm.action_callback(function(win, pane)
			move_or_split(win, pane, "Left")
		end),
	},
	{
		key = "j",
		mods = "SUPER",
		action = wezterm.action_callback(function(win, pane)
			move_or_split(win, pane, "Down")
		end),
	},
	{
		key = "k",
		mods = "SUPER",
		action = wezterm.action_callback(function(win, pane)
			move_or_split(win, pane, "Up")
		end),
	},
	{
		key = "l",
		mods = "SUPER",
		action = wezterm.action_callback(function(win, pane)
			move_or_split(win, pane, "Right")
		end),
	},
	{ key = "w", mods = "LEADER", action = act.ActivateKeyTable({ name = "window_mode" }) },

	-- MacOS rebinds
	{ key = "c", mods = "CMD", action = act.SendKey({ key = "c", mods = "CTRL" }) },
	{ key = "v", mods = "CMD", action = act.SendKey({ key = "v", mods = "CTRL" }) },
}

M.key_tables = {
	window_mode = {
		{ key = "r", action = act.ActivateKeyTable({ name = "resize_mode", one_shot = false }) },
		{ key = "w", action = act.PaneSelect },
		{ key = "n", action = act.SpawnWindow },
		{ key = "d", action = act.CloseCurrentPane({ confirm = true }) },
		{ key = "v", action = act.SplitPane({ direction = "Right" }) },
		{ key = "s", action = act.SplitPane({ direction = "Down" }) },
	},
	resize_mode = {
		{ key = "h", action = act.AdjustPaneSize({ "Left", 1 }) },
		{ key = "l", action = act.AdjustPaneSize({ "Right", 1 }) },
		{ key = "k", action = act.AdjustPaneSize({ "Up", 1 }) },
		{ key = "j", action = act.AdjustPaneSize({ "Down", 1 }) },
		{ key = "Escape", action = "PopKeyTable" },
	},
}

return M
