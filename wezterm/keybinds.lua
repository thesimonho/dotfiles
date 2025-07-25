local wezterm = require("wezterm")
local act = wezterm.action
local containers = require("containers")
local SCROLL_SPEED = 0.4

local function handle_selection(window, pane, _, label)
	if not label then
		-- no selection
		return
	end

	if label == "󰌙 detach domains" then
		local domains = wezterm.mux.all_domains()
		for _, domain in ipairs(domains) do
			if domain:state() == "Attached" and domain:name() ~= "local" and domain:is_spawnable() then
				domain:detach()
			end
		end
		return
	elseif label == "󰑓 reload domains" then
		window:perform_action(act.ReloadConfiguration, pane)
		return
	end

	local kind, name = label:match("^(.-): (.-)%s*%*?$")
	if kind == "devpod" then
		window:perform_action(
			act.SwitchToWorkspace({
				name = name,
				spawn = {
					domain = { DomainName = name },
				},
			}),
			pane
		)
	elseif kind == "distrobox" then
		window:perform_action(
			act.SpawnCommandInNewTab({
				args = { "distrobox", "enter", "--root", name },
			}),
			pane
		)
	else
		window:perform_action(
			act.SwitchToWorkspace({
				name = label,
				spawn = {
					domain = { DomainName = label },
				},
			}),
			pane
		)
	end
end

-- Creates the input selector action
local function show_domain_selector()
	-- create choices every time so we can update the * indicator
	local choices = containers.create_container_choices()

	return act.InputSelector({
		action = wezterm.action_callback(handle_selection),
		choices = choices,
		alphabet = "1234qwer",
		description = "Attach domain:",
	})
end

local M = {}

M.basic_binds = {
	-- MacOS rebinds
	{ key = "c", mods = "CMD", action = act.SendKey({ key = "c", mods = "CTRL" }) },
	{ key = "v", mods = "CMD", action = act.SendKey({ key = "v", mods = "CTRL" }) },

	-- wezterm
	{ key = "F1", action = act.ActivateCommandPalette },
	{ key = "/", mods = "CTRL", action = act.Search({ CaseInSensitiveString = "" }) },
	{ key = "y", mods = "LEADER", action = act.ActivateCopyMode },
	{ key = "q", mods = "LEADER", action = act.QuitApplication },
	{
		key = "Backspace",
		mods = "CTRL",
		action = wezterm.action.SendString("\x17"), -- Ctrl+W because C-BS can't be mapped in neovim
	},
	{
		key = "p",
		mods = "SUPER",
		action = wezterm.action_callback(function(window, pane)
			window:perform_action(show_domain_selector(), pane)
		end),
	},

	-- copy paste
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

	-- panes / windows
	{ key = "h", mods = "SUPER", action = act.ActivatePaneDirection("Left") },
	{ key = "j", mods = "SUPER", action = act.ActivatePaneDirection("Down") },
	{ key = "k", mods = "SUPER", action = act.ActivatePaneDirection("Up") },
	{ key = "l", mods = "SUPER", action = act.ActivatePaneDirection("Right") },

	-- tabs / buffers
	{ key = "t", mods = "CTRL", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "`", mods = "LEADER", action = act.ActivateLastTab },
	{ key = "h", mods = "LEADER", action = act.ActivateTabRelative(-1) },
	{ key = "l", mods = "LEADER", action = act.ActivateTabRelative(1) },

	-- scrolling
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

	-- key tables
	{
		key = "w",
		mods = "LEADER",
		action = act.ActivateKeyTable({ name = "window_mode" }),
	},
	{
		key = "b",
		mods = "LEADER",
		action = act.ActivateKeyTable({ name = "buffer_mode" }),
	},
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
