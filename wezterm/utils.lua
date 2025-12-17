local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

M.is_windows = function()
	return wezterm.target_triple == "x86_64-pc-windows-msvc"
end

M.is_mac = function()
	return wezterm.target_triple == "aarch64-apple-darwin"
end

M.string_split = function(inputstr, sep)
	if sep == nil then
		sep = ","
	end
	local t = {}
	for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
		local trimmed = str:gsub("^%s*(.-)%s*$", "%1")
		table.insert(t, trimmed)
	end
	return t
end

M.move_or_split = function(win, pane, direction)
	local tab = pane:tab()
	if tab:get_pane_direction(direction) ~= nil then
		win:perform_action(act.ActivatePaneDirection(direction), pane)
		return
	end
	win:perform_action(act.SplitPane({ direction = direction }), pane)
end

-- Poll until a predicate function returns true, then stop polling.
M.poll_until_ready = function(interval, predicate)
	local function step()
		local done = predicate()
		if not done then
			wezterm.time.call_after(interval, step)
		end
	end
	wezterm.time.call_after(0.1, step)
end

return M
