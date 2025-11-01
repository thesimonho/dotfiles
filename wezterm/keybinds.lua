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

	-- tabs / buffers
	{ key = "t", mods = "SUPER", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "`", mods = "SUPER", action = act.ActivateLastTab },
	{ key = "h", mods = "SUPER|SHIFT", action = act.ActivateTabRelative(-1) },
	{ key = "l", mods = "SUPER|SHIFT", action = act.ActivateTabRelative(1) },

	-- panes / windows
	{ key = "h", mods = "SUPER", action = act.ActivatePaneDirection("Left") },
	{ key = "j", mods = "SUPER", action = act.ActivatePaneDirection("Down") },
	{ key = "k", mods = "SUPER", action = act.ActivatePaneDirection("Up") },
	{ key = "l", mods = "SUPER", action = act.ActivatePaneDirection("Right") },

	-- key tables
	{
		key = "w",
		mods = "SUPER",
		action = act.ActivateKeyTable({ name = "window_mode", timeout_milliseconds = 5000 }),
	},
	{
		key = "b",
		mods = "SUPER",
		action = act.ActivateKeyTable({ name = "tab_mode", timeout_milliseconds = 5000 }),
	},
}

M.key_tables = {
	tab_mode = { -- wezterm tabs
		{ key = "Escape", action = "PopKeyTable" },
		{ key = "n", action = act.SpawnTab("CurrentPaneDomain"), desc = "New" },
		{ key = "d", action = act.CloseCurrentTab({ confirm = true }), desc = "Close" },
	},
	window_mode = { -- wezterm panes
		{ key = "Escape", action = "PopKeyTable" },
		{
			key = "r",
			action = act.ActivateKeyTable({ name = "resize_mode", one_shot = false, timeout_milliseconds = 5000 }),
			desc = "Resize",
		},
		{ key = "w", action = act.PaneSelect, desc = "Pick" },
		{ key = "v", action = act.SplitPane({ direction = "Right" }), desc = "Split Right" },
		{ key = "s", action = act.SplitPane({ direction = "Down" }), desc = "Split Down" },
		{ key = "x", action = act.RotatePanes("Clockwise"), desc = "Rotate" },
		{ key = "d", action = act.CloseCurrentPane({ confirm = true }), desc = "Close" },
	},
	resize_mode = {
		{ key = "Escape", action = "PopKeyTable" },
		{ key = "h", action = act.AdjustPaneSize({ "Left", 1 }), desc = "Left" },
		{ key = "j", action = act.AdjustPaneSize({ "Down", 1 }), desc = "Down" },
		{ key = "k", action = act.AdjustPaneSize({ "Up", 1 }), desc = "Up" },
		{ key = "l", action = act.AdjustPaneSize({ "Right", 1 }), desc = "Right" },
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
