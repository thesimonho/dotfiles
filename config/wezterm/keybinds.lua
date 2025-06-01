local wezterm = require("wezterm")
local act = wezterm.action
local plugins = require("plugins")
local utils = require("utils")
local SCROLL_SPEED = 0.4

local M = {}

M.basic_binds = {
	-- MacOS rebinds
	{ key = "c", mods = "CMD", action = act.SendKey({ key = "c", mods = "CTRL" }) },
	{ key = "v", mods = "CMD", action = act.SendKey({ key = "v", mods = "CTRL" }) },

	{ key = "F1", mods = "SUPER", action = act.ActivateCommandPalette },
	{ key = "p", mods = "CTRL", action = act.ActivateCommandPalette },
	{ key = "p", mods = "SUPER", action = plugins.workspace_switcher.switch_workspace() },
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
		key = "t",
		mods = "CTRL",
		action = act.SpawnTab("CurrentPaneDomain"),
	},
	{
		key = "n",
		mods = "SUPER",
		action = wezterm.action_callback(function(window, pane)
			window:perform_action(
				act.InputSelector({
					action = wezterm.action_callback(function(win, pan, _, label)
						local kind, name = label:match("^(.-): (.+)$")
						if kind == "devcontainer" then
							win:perform_action(
								act.SwitchToWorkspace({
									name = name,
									spawn = {
										args = { "ssh", name .. ".devpod" },
									},
								}),
								pan
							)
						elseif kind == "distrobox" then
							win:perform_action(
								act.SpawnCommandInNewTab({
									args = { "distrobox", "enter", "--root", name },
								}),
								pan
							)
						else
							win:perform_action(
								act.SpawnCommandInNewTab({
									args = { name },
								}),
								pan
							)
						end
					end),
					choices = utils.tab_choices,
					alphabet = "1234qwer",
					description = "Launch in new tab:",
				}),
				pane
			)
		end),
	},
	{ key = "PageUp", action = act.ScrollByPage(-SCROLL_SPEED) },
	{ key = "PageDown", action = act.ScrollByPage(SCROLL_SPEED) },
	-- {
	-- 	key = "u",
	-- 	mods = "CTRL",
	-- 	action = wezterm.action_callback(function(window, pane)
	-- 		if utils.is_not_nvim(pane) then
	-- 			window:perform_action(act.ScrollByPage(-SCROLL_SPEED), pane)
	-- 		else
	-- 			window:perform_action(act.SendKey({ key = "u", mods = "CTRL" }), pane)
	-- 		end
	-- 	end),
	-- },
	-- {
	-- 	key = "d",
	-- 	mods = "CTRL",
	-- 	action = wezterm.action_callback(function(window, pane)
	-- 		if utils.is_not_nvim(pane) then
	-- 			window:perform_action(act.ScrollByPage(SCROLL_SPEED), pane)
	-- 		else
	-- 			window:perform_action(act.SendKey({ key = "d", mods = "CTRL" }), pane)
	-- 		end
	-- 	end),
	-- },
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
			utils.move_or_split(win, pane, "Left")
		end),
	},
	{
		key = "j",
		mods = "SUPER",
		action = wezterm.action_callback(function(win, pane)
			utils.move_or_split(win, pane, "Down")
		end),
	},
	{
		key = "k",
		mods = "SUPER",
		action = wezterm.action_callback(function(win, pane)
			utils.move_or_split(win, pane, "Up")
		end),
	},
	{
		key = "l",
		mods = "SUPER",
		action = wezterm.action_callback(function(win, pane)
			utils.move_or_split(win, pane, "Right")
		end),
	},
	{
		key = "`",
		mods = "LEADER",
		action = wezterm.action.ActivateLastTab,
	},
	{ key = "h", mods = "LEADER", action = act.ActivateTabRelative(-1) },
	{ key = "l", mods = "LEADER", action = act.ActivateTabRelative(1) },
	{ key = "w", mods = "LEADER", action = act.ActivateKeyTable({ name = "window_mode" }) },
	{ key = "b", mods = "LEADER", action = act.ActivateKeyTable({ name = "buffer_mode" }) },
}

M.key_tables = {
	buffer_mode = { -- wezterm tabs
		{ key = "d", action = act.CloseCurrentTab({ confirm = true }) },
	},
	window_mode = { -- wezterm panes
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
