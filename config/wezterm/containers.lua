local utils = require("utils")

local M = {}

M.get_container_ids = function()
	local container_ids = {}
	local cmd = "docker container ls --format '{{.ID}}'"
	local handle = io.popen(cmd)
	if handle then
		for line in handle:lines() do
			table.insert(container_ids, line)
		end
		handle:close()
	end
	return container_ids
end

-- Parse ports into a table
M.map_ports = function(ports)
	local port_map = {}
	if ports and ports ~= "" then
		for container_port, host_port in ports:gmatch("(%S+)->(%S+)") do
			port_map[container_port] = host_port
		end
	end
	return port_map
end

-- Extract workspace name from image (before colon, strip after last '-')
M.extract_workspace_name = function(image)
	local workspace = image:match("^([^:]+)")
	if workspace then
		workspace = workspace:match("^(.*)%-.+$") or workspace
	end
	return workspace
end

M.devpods = {}
M.get_devpod_info = function()
	local ids = M.get_container_ids()
	local devpods = {}

	for _, id in ipairs(ids) do
		local cmd = string.format(
			"docker inspect -f '{{.Name}} {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}} {{.Config.Image}} {{.State.Status}} {{.Config.User}} {{range $p, $conf := .NetworkSettings.Ports}}{{$p}}->{{if $conf}}{{(index $conf 0).HostPort}}{{end}} {{end}}' %s",
			id
		)
		local handle = io.popen(cmd)
		if handle then
			local line = handle:read("*l")
			handle:close()
			if line then
				local name, ip, image, state, user, ports =
					line:match("^/(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S*)%s*(.*)$")
				if name and image and ports then
					local workspace = M.extract_workspace_name(image)
					local port_map = M.map_ports(ports)
					devpods[name] = {
						ip = ip,
						image = image,
						workspace = workspace,
						state = state,
						user = user ~= "" and user or nil,
						ports = port_map,
					}
				end
			end
		end
	end
	return devpods
end

M.create_ssh_domains = function()
	if next(M.devpods) == nil then
		M.devpods = M.get_devpod_info()
	end

	local ssh_domains = {}
	for name, data in pairs(M.devpods) do
		table.insert(ssh_domains, {
			name = data.workspace or name,
			remote_address = string.format("127.0.0.1:%s", data.ports["2222/tcp"]),
			username = data.user or "vscode",
			connect_automatically = false,
			multiplexing = "WezTerm",
			remote_wezterm_path = "/usr/bin/wezterm",
			ssh_option = {
				identityfile = "~/.ssh/id_devcontainer",
			},
		})
	end
	return ssh_domains
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
			local cols = utils.string_split(line, "|")
			if cols then
				table.insert(images, cols[2])
			end
		end
		i = i + 1
	end
	handle:close()
	return images
end

M.container_choices = {}
M.create_container_choices = function()
	if next(M.distroboxes) == nil then
		M.distroboxes = M.get_distrobox_images()
	end
	if next(M.devpods) == nil then
		M.devpods = M.get_devpod_info()
	end

	table.insert(M.container_choices, {
		label = "local",
	})

	for _, pod in pairs(M.devpods) do
		table.insert(M.container_choices, {
			label = "devpod: " .. pod.workspace,
		})
	end
	for _, box in ipairs(M.distroboxes) do
		table.insert(M.container_choices, {
			label = "distrobox: " .. box,
		})
	end

	table.insert(M.container_choices, {
		label = "󰑓 reload domains",
	})

	return M.container_choices
end

return M
