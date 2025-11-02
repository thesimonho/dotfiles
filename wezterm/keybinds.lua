local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

M.basic_binds = {
	-- MacOS rebinds
	{ key = "c", mods = "CMD", action = act.SendKey({ key = "c", mods = "CTRL" }) },
	{ key = "v", mods = "CMD", action = act.SendKey({ key = "v", mods = "CTRL" }) },

	-- wezterm
	{ key = "F1", action = act.ActivateCommandPalette },
	{ key = "/", mods = "CTRL", action = act.Search({ CaseInSensitiveString = "" }) },
	{ key = "y", mods = "SUPER", action = act.ActivateCopyMode },
	{ key = "q", mods = "SUPER", action = act.QuitApplication },
	{
		key = "Backspace",
		mods = "CTRL",
		action = wezterm.action.SendString("\x17"), -- Ctrl+W because C-BS can't be mapped in neovim
	},
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
	{ key = "v", mods = "CTRL|SHIFT", action = act.PasteFrom("Clipboard") },

	-- font size
	{ key = "=", mods = "CTRL", action = act.IncreaseFontSize },
	{ key = "-", mods = "CTRL", action = act.DecreaseFontSize },
	{ key = "0", mods = "CTRL", action = act.ResetFontSize },

	-- key tables
	{
		key = "w",
		mods = "SUPER",
		action = act.ActivateKeyTable({ name = "window_mode", timeout_milliseconds = 10000 }),
	},
	{
		key = "t",
		mods = "SUPER",
		action = act.ActivateKeyTable({ name = "tab_mode", timeout_milliseconds = 10000 }),
	},
}

M.key_tables = {
	tab_mode = { -- wezterm tabs
		{ key = "Escape", action = "PopKeyTable" },
		{ key = "`", action = act.ActivateLastTab, desc = "Last" },
		{ key = "n", action = act.SpawnTab("CurrentPaneDomain"), desc = "New" },
		{ key = "h", action = act.ActivateTabRelative(-1), desc = "" },
		{ key = "l", action = act.ActivateTabRelative(1), desc = "" },
		{ key = "d", action = act.CloseCurrentTab({ confirm = true }), desc = "Close" },
	},
	window_mode = { -- wezterm panes
		{ key = "Escape", action = "PopKeyTable" },
		{
			key = "r",
			action = act.ActivateKeyTable({ name = "resize_mode", one_shot = false, timeout_milliseconds = 5000 }),
			desc = "Resize",
		},
		{
			key = "e",
			action = act.ActivateKeyTable({ name = "extract_mode", timeout_milliseconds = 5000 }),
			desc = "Extract",
		},
		{ key = "p", action = act.PaneSelect, desc = "Pick" },
		{ key = "v", action = act.SplitPane({ direction = "Right" }), desc = "Split |" },
		{ key = "s", action = act.SplitPane({ direction = "Down" }), desc = "Split -" },
		{ key = "x", action = act.RotatePanes("Clockwise"), desc = "Rotate" },
		{ key = "h", action = act.ActivatePaneDirection("Left"), desc = "" },
		{ key = "j", action = act.ActivatePaneDirection("Down"), desc = "" },
		{ key = "k", action = act.ActivatePaneDirection("Up"), desc = "" },
		{ key = "l", action = act.ActivatePaneDirection("Right"), desc = "" },
		{ key = "d", action = act.CloseCurrentPane({ confirm = true }), desc = "Close" },
	},
	resize_mode = {
		{ key = "Escape", action = "PopKeyTable" },
		{ key = "h", action = act.AdjustPaneSize({ "Left", 1 }), desc = "" },
		{ key = "j", action = act.AdjustPaneSize({ "Down", 1 }), desc = "" },
		{ key = "k", action = act.AdjustPaneSize({ "Up", 1 }), desc = "" },
		{ key = "l", action = act.AdjustPaneSize({ "Right", 1 }), desc = "" },
	},
	extract_mode = {
		{ key = "Escape", action = "PopKeyTable" },
		{
			key = "t",
			action = wezterm.action_callback(function(_, pane)
				pane:move_to_new_tab()
			end),
			desc = "to Tab",
		},
		{
			key = "w",
			action = wezterm.action_callback(function(_, pane)
				pane:move_to_new_window()
			end),
			desc = "to Window",
		},
	},
}

-- super + number to activate that tab
for i = 1, 9 do
	table.insert(M.basic_binds, {
		key = tostring(i),
		mods = "SUPER",
		action = wezterm.action.ActivateTab(i - 1),
	})
end

return M
