local wezterm = require("wezterm")
local act = wezterm.action
local config = require("config")
local keybinds = require("keybinds")
local containers = require("containers")
local theme = require("theme_switcher")

local enabled = {
	tabline = true,
	session = true,
	resurrect = true,
	toggle_terminal = true,
	dev_containers = false,
}

local M = {}

-- sessions
if enabled.session then
	M.sessionizer = wezterm.plugin.require("https://github.com/mikkasendke/sessionizer.wezterm")
	M.sessionizer_history = wezterm.plugin.require("https://github.com/mikkasendke/sessionizer-history")

	M.sessionizer_schema = {
		options = {
			prompt = "Switch to workspace: ",
			callback = M.sessionizer_history.Wrapper(function(win, pane, id, label)
				if not id then
					return
				end

				win:perform_action(act.SwitchToWorkspace({ name = id, spawn = { cwd = id } }), pane)

				if enabled.resurrect then
					local opts = {
						spawn_in_workspace = true,
						window = win:mux_window(),
						relative = true,
						restore_text = true,
						close_open_tabs = true,
						close_open_panes = true,
						resize_window = false,
						on_pane_restore = M.resurrect.tab_state.default_on_pane_restore,
					}

					local loaded_state
					local loaded_ok, load_err = pcall(function()
						loaded_state = M.resurrect.state_manager.load_state(id, "workspace")
					end)
					if not loaded_ok then
						wezterm.log_error("Failed to load resurrect state: " .. load_err)
					end

					wezterm.time.call_after(1000, function()
						local ok, err = pcall(function()
							local workspace_state = M.resurrect.workspace_state
							workspace_state.restore_workspace(loaded_state, opts)
						end)
						if not ok then
							wezterm.log_error(err)
						end
					end)
				end
			end),
		},
		{
			M.sessionizer_history.MostRecentWorkspace({}),
			processing = M.sessionizer.for_each_entry(function(entry)
				entry.label = entry.label:gsub("^Recent %((.-)%)$", "%1")
				entry.label = wezterm.format({
					{ Foreground = { AnsiColor = "Maroon" } },
					{ Attribute = { Intensity = "Bold" } },
					{ Text = " " .. entry.label },
				})
			end),
		},
		{
			M.sessionizer.AllActiveWorkspaces({ filter_current = false, filter_default = false }),
			processing = M.sessionizer.for_each_entry(function(entry)
				entry.label = wezterm.format({
					{ Foreground = { AnsiColor = "Green" } },
					{ Attribute = { Italic = true } },
					{ Text = "󱂬 " .. entry.label },
				})
			end),
		},
		{
			M.sessionizer.FdSearch({
				wezterm.home_dir .. "/Projects",
				fd_path = "/home/linuxbrew/.linuxbrew/bin/fd",
				exclude = { ".Trash-1000", "node_modules" },
			}),
			processing = M.sessionizer.for_each_entry(function(entry)
				entry.label = entry.label:gsub("^" .. wezterm.home_dir .. "/Projects/", " ")
			end),
		},
		processing = M.sessionizer.for_each_entry(function(entry)
			entry.label = entry.label:gsub(wezterm.home_dir, "~")
		end),
	}

	table.insert(keybinds.basic_binds, {
		key = "p",
		mods = "SUPER",
		action = wezterm.action_callback(function(window, pane)
			if enabled.resurrect then
				-- Save current workspace before switching
				local workspace_state = M.resurrect.workspace_state
				M.resurrect.state_manager.save_state(workspace_state.get_workspace_state())
			end
			window:perform_action(M.sessionizer.show(M.sessionizer_schema), pane)
		end),
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
	M.tabline_theme = require("colors.wezterm_tabline." .. theme.color_scheme)
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
		extensions = { "resurrect" },
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
