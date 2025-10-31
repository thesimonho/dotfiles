local wezterm = require("wezterm")
local act = wezterm.action
local config = require("config")
local keybinds = require("keybinds")
local containers = require("containers")
local theme = require("theme_switcher")

local enabled = {
	tabline = true,
	dev_containers = false,
}

local M = {}

-- dev containers
if enabled.dev_containers then
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

	keybinds.basic_binds[#keybinds.basic_binds + 1] = {
		key = "p",
		mods = "SUPER",
		action = wezterm.action_callback(function(window, pane)
			window:perform_action(show_domain_selector(), pane)
		end),
	}

	config.ssh_domains = containers.create_ssh_domains()
end

-- tabline
if enabled.tabline then
	M.tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")
	M.tabline.setup({
		options = {
			icons_enabled = true,
			theme = require("colors.wezterm_tabline." .. theme.color_scheme),
			section_separators = {
				left = wezterm.nerdfonts.ple_right_half_circle_thick,
				right = wezterm.nerdfonts.ple_left_half_circle_thick,
			},
			component_separators = {
				left = wezterm.nerdfonts.ple_right_half_circle_thin,
				right = wezterm.nerdfonts.ple_left_half_circle_thin,
			},
			tab_separators = {
				left = " ",
				right = "",
			},
		},
		sections = {
			tabline_a = {
				{
					"mode",
					icon = "🐼",
					fmt = function(text)
						return string.lower(text)
					end,
				},
			},
			tabline_b = {
				{ "workspace", padding = { left = 1, right = 0 } },
			},
			tabline_c = { " " },
			tabline_x = {
				function(window)
					local metadata = window:active_pane():get_metadata()
					if not metadata then
						return ""
					end

					local latency = metadata.since_last_response_ms
					if not latency then
						return ""
					end

					local color
					local icon
					local red = "\27[31m"
					local yellow = "\27[33m"
					local green = "\27[32m"
					if metadata.is_tardy then
						if latency > 10000 then
							color = red
							icon = "󰢼"
							latency = ">999"
						else
							color = yellow
							icon = "󰢽"
						end
					else
						color = green
						icon = "󰢾"
						latency = "<1"
					end
					return string.format(color .. icon .. " %sms ", latency)
				end,
			},
			tabline_y = {
				{
					"datetime",
					style = "%A %b %d",
					icon = "",
					hour_to_icon = false,
				},
			},
			tabline_z = { "hostname" },
			tab_active = {
				{ "process", icons_only = true, padding = { left = 2, right = 0 } },
				{ "index" },
				{ "parent", max_length = 10, padding = 0 },
				"/",
				{ "cwd", max_length = 15, padding = { left = 0, right = 2 } },
				{ "zoomed", padding = 0 },
			},
			tab_inactive = {
				{ "process", icons_only = true, padding = { left = 2, right = 0 } },
				{ "index" },
				{ "parent", max_length = 10, padding = 0 },
				"/",
				{ "cwd", max_length = 15, padding = { left = 0, right = 2 } },
			},
		},
		extensions = { "smart_workspace_switcher" },
	})
end

return M
