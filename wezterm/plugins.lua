local wezterm = require("wezterm")
local act = wezterm.action
local config = require("config")
local keybinds = require("keybinds")
local containers = require("containers")
local utils = require("utils")

local enabled = {
	tabline = true,
	workspace = true,
	resurrect = false,
	toggle_terminal = false,
	dev_containers = false,
}

local M = {}

-- sessions
if enabled.workspace then
	M.workspace_switcher = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")

	local function get_previous(choices)
		choices = choices or {}
		if not wezterm.GLOBAL.previous_workspace then
			return choices
		end

		table.insert(choices, {
			id = wezterm.GLOBAL.previous_workspace,
			label = wezterm.format({
				{ Foreground = { AnsiColor = "Maroon" } },
				{ Attribute = { Intensity = "Bold" } },
				{ Text = wezterm.GLOBAL.previous_workspace },
			}),
		})
		return choices
	end

	local function create_choices(path, choices, depth)
		choices = choices or {}
		local current = {}
		depth = depth or 1

		-- normalize path
		if path:sub(-1) ~= "/" then
			path = path .. "/"
		end

		-- helper to build repeated patterns like "*/" or "*/*/"
		local function build_pattern(base, level)
			if level == 1 then
				return base .. "*/.git"
			end
			return base .. string.rep("*/", level - 1) .. "*/.git"
		end

		for level = 1, depth do
			for _, dir in ipairs(wezterm.glob(build_pattern(path, level))) do
				local label_pattern
				if level == 1 then
					label_pattern = "^" .. path .. "([^/]+)/%.git/?$"
				else
					label_pattern = "^" .. path .. ".-/([^/]+)/%.git/?$"
				end

				table.insert(current, {
					id = dir:gsub("/%.git$", ""),
					label = dir:gsub(label_pattern, "%1"):lower(),
				})
			end
		end

		table.sort(current, function(a, b)
			return a.label < b.label
		end)

		for i = 1, #current do
			choices[#choices + 1] = current[i]
		end

		return choices
	end

	M.workspace_switcher.get_choices = function()
		local choices = {}
		choices = get_previous(choices)
		choices = M.workspace_switcher.choices.get_workspace_elements(choices)
		choices = create_choices(wezterm.home_dir .. "/Projects", choices, 2)
		return choices
	end

	table.insert(keybinds.basic_binds, {
		key = "p",
		mods = "SUPER",
		action = M.workspace_switcher.switch_workspace(),
	})
	table.insert(keybinds.basic_binds, {
		key = "`",
		mods = "SUPER",
		action = M.workspace_switcher.switch_to_prev_workspace(),
	})
end

-- resurrect
if enabled.resurrect then
	M.resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")
	M.resurrect.state_manager.periodic_save({
		interval_seconds = 10 * 60,
		save_workspaces = true,
		save_windows = true,
		save_tabs = true,
	})

	wezterm.on("resurrect.error", function(err)
		wezterm.log_error("Resurrect error: " .. err)
	end)

	if enabled.workspace then
		wezterm.on("smart_workspace_switcher.workspace_switcher.selected", function()
			local workspace_state = M.resurrect.workspace_state
			M.resurrect.state_manager.save_state(workspace_state.get_workspace_state())
		end)

		wezterm.on("smart_workspace_switcher.workspace_switcher.created", function(window, _, label)
			local workspace_state = M.resurrect.workspace_state
			workspace_state.restore_workspace(M.resurrect.state_manager.load_state(label, "workspace"), {
				window = window,
				relative = true,
				restore_text = true,
				resize_window = false,
				on_pane_restore = M.resurrect.tab_state.default_on_pane_restore,
			})
		end)
	end
end

-- toggle term
if enabled.toggle_terminal then
	M.toggle_terminal = wezterm.plugin.require("https://github.com/zsh-sage/toggle_terminal.wez")
	M.toggle_terminal.apply_to_config(config, {
		key = "\\",
		mods = "SUPER",
		direction = "Right",
		size = { Percent = 50 },
		change_invoker_id_everytime = false, -- Change invoker pane on every toggle
		zoom = {
			auto_zoom_toggle_terminal = false,
			auto_zoom_invoker_pane = true,
			remember_zoomed = true,
		},
	})
end

-- tabline
if enabled.tabline then
	M.tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")

	local theme_name = utils.is_dark() and "kanagawa-paper-ink" or "kanagawa-paper-canvas"
	M.tabline_theme = require("colors.wezterm_tabline." .. theme_name)
	local hint_icon = "󰋗 "

	local function generate_keytable_hint_text(tbl, sep)
		if not tbl then
			return ""
		end
		sep = sep or " │ "
		local hint = {}
		for _, entry in ipairs(tbl) do
			if entry.desc then
				table.insert(hint, string.format("(%s) %s", entry.key, entry.desc))
			end
		end
		return table.concat(hint, sep)
	end

	local function keytable_hint(window)
		local kt = window:active_key_table()
		if not kt or not kt:match("_mode$") then
			return hint_icon
		end
		return hint_icon .. " " .. M.tabline.hints[kt] .. " "
	end

	M.tabline.hints = {}
	for name, tbl in pairs(keybinds.key_tables) do
		M.tabline.hints[name] = generate_keytable_hint_text(tbl)
		-- if tabline_theme doesnt contain the keytable, use default
		if not M.tabline_theme[name] then
			M.tabline_theme[name] = M.tabline_theme.default_mode
		end
	end

	M.tabline.setup({
		options = {
			theme = M.tabline_theme,
			icons_enabled = true,
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
		-- extensions = { "resurrect" },
		sections = {
			tabline_a = {
				{
					"mode",
					fmt = function(text)
						return "🐼 " .. string.lower(text)
					end,
					padding = { left = 1, right = 1 },
				},
			},
			tabline_b = {
				{ "workspace", padding = { left = 1, right = 0 } },
			},
			tabline_c = { " " },
			tabline_x = {},
			tabline_y = { keytable_hint },
			tabline_z = {
				{
					"datetime",
					style = "%a %b %d",
					padding = { left = 0, right = 1 },
				},
			},
			tab_active = {
				{ "index", padding = { left = 2, right = 1 } },
				{ "process", icons_only = false, padding = { left = 0, right = 2 } },
				-- { "cwd", max_length = 10, padding = { left = 0, right = 2 } },
			},
			tab_inactive = {
				{ "index", padding = { left = 2, right = 1 } },
				{ "process", icons_only = false, padding = { left = 0, right = 2 } },
				-- { "cwd", max_length = 10, padding = { left = 0, right = 2 } },
			},
		},
	})
end

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

return M
