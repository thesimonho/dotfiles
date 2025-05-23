local wezterm = require("wezterm")
local act = wezterm.action

M = {}

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

M.get_distrobox_images = function()
	local images = {}
	local handle = io.popen("distrobox ls")
	if not handle then
		return images
	end

	local i = 0
	for line in handle:lines() do
		if i ~= 0 then
			local cols = M.string_split(line, "|")
			if cols then
				table.insert(images, cols[2])
			end
		end
		i = i + 1
	end
	handle:close()
	return images
end

M.create_distrobox_launchers = function()
	local boxes = M.distroboxes
	if #boxes == 0 then
		return
	end
	local launchers = {}
	for _, box in ipairs(boxes) do
		table.insert(launchers, {
			label = "distrobox: " .. box,
			args = { "distrobox", "enter", "--root", box },
		})
	end
	return launchers
end

M.get_devpod_containers = function()
	local images = {}
	local handle = io.popen("devpod list")
	if not handle then
		return images
	end

	local i = 0
	for line in handle:lines() do
		if i > 2 and i < #line then
			local cols = M.string_split(line, "|")
			if cols then
				table.insert(images, cols[1])
			end
		end
		i = i + 1
	end
	handle:close()
	return images
end

M.create_devpod_launchers = function()
	local boxes = M.devcontainers
	if #boxes == 0 then
		return
	end
	local launchers = {}
	for _, pod in ipairs(boxes) do
		table.insert(launchers, {
			label = "devcontainer: " .. pod,
			args = { "ssh", pod .. ".devpod" },
		})
	end
	return launchers
end

M.create_tab_choices = function()
	local choices = {}
	for _, box in ipairs(M.devcontainers) do
		table.insert(choices, {
			label = "devcontainer: " .. box,
		})
	end
	for _, box in ipairs(M.distroboxes) do
		table.insert(choices, {
			label = "distrobox: " .. box,
		})
	end
	return choices
end

M.distroboxes = M.get_distrobox_images()
M.devcontainers = M.get_devpod_containers()
M.tab_choices = M.create_tab_choices()

return M
