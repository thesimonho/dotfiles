-- Integrate Mason with nvim lsp and null-ls
local M = {
	"williamboman/mason-lspconfig.nvim",
	enabled = true,
	dependencies = {
		"neovim/nvim-lspconfig",
		"williamboman/mason.nvim",
		"jay-babu/mason-null-ls.nvim",
		"hrsh7th/cmp-nvim-lsp",
		"simrat39/rust-tools.nvim",
		{ "jose-elias-alvarez/null-ls.nvim", dependencies = "nvim-lua/plenary.nvim" },
	},
	event = "VeryLazy",
}

function M.config()
	local ensure_installed = {
		-- lsp
		"docker-compose-language-service",
		"lua-language-server",
		"pyright", -- for static type checking only
		"ruff-lsp", -- FIXME: sometimes doesnt show lint errors
		"rust-analyzer",
		"taplo",
		"typescript-language-server",
		"vim-language-server",
		"yaml-language-server",
		"vue-language-server",

		-- linters
		"eslint_d",
		"markdownlint",

		-- formatters
		"black",
		"isort",
		"prettierd",
		"rustfmt",
		"stylua",
	}

	-- setup mason for tool installation
	require("mason").setup()

	-- nvim-cmp supports additional completion capabilities, so broadcast that to servers
	local capabilities = vim.lsp.protocol.make_client_capabilities()
	capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)
	capabilities["textDocument"]["foldingRange"] = {
		dynamicRegistration = false,
		lineFoldingOnly = true,
	}

	-- settings for specific lsp servers
	local runtime_path = vim.split(package.path, ";")
	table.insert(runtime_path, "lua/?.lua")
	table.insert(runtime_path, "lua/?/init.lua")
	local servers = {
		lua_ls = {
			Lua = {
				telemetry = { enable = false },
				runtime = {
					version = "LuaJIT",
					path = runtime_path,
				},
				diagnostics = {
					-- Get the language server to recognize the `vim` global
					globals = { "vim" },
				},
				workspace = {
					checkThirdParty = false,
					library = {
						-- Make the server aware of Neovim runtime files
						vim.fn.expand("$VIMRUNTIME/lua"),
						vim.fn.stdpath("config") .. "/lua",
					},
				},
				completion = {
					callSnippet = "Replace",
				},
			},
		},
		pyrite = {
			disableLanguageServices = true,
			disableOrganizeImports = true,
			python = {
				analysis = {
					autoImportCompletions = false,
					autoSearchPaths = true,
					useLibraryCodeForTypes = true,
					typeCheckingMode = "basic",
					diagnosticMode = "openFilesOnly",
					diagnosticSeverityOverrides = {
						reportGeneralTypeIssues = "information", -- broken on pyrites end
					},
				},
			},
		},
	}

	-- on_attach function to be added to each server
	local on_attach = function(client, bufnr)
		-- map buffer local keys once lsp is attached
		MapLSP(bufnr)

		if client.name == "ruff_lsp" then
			-- Disable this in favor of pyrite's hover
			client.server_capabilities.hoverProvider = false
		end

		-- local vt = {
		-- 	spacing = 10,
		-- 	severity = { min = vim.diagnostic.severity.INFO },
		-- 	format = function(diagnostic)
		-- 		local severity_letter = string.sub(vim.diagnostic.severity[diagnostic.severity], 1, 1)
		-- 		local msg = diagnostic.message
		-- 		local msg_threshold = 100

		-- 		local num_windows = #vim.api.nvim_tabpage_list_wins(0) / 2
		-- 		if num_windows > 1 then
		-- 			msg_threshold = msg_threshold / num_windows
		-- 		end

		-- 		if string.len(msg) > msg_threshold then
		-- 			msg = string.sub(msg, 1, msg_threshold) .. "..."
		-- 		end

		-- 		return string.format("%s: %s", severity_letter, msg)
		-- 	end,
		-- }
		local vt_basic = {
			spacing = 10,
			severity = { min = vim.diagnostic.severity.INFO },
		}
		vim.diagnostic.config({ virtual_text = vt_basic })

		-- create buffer local autocommands to show and hide virtual diagnostic text
		-- vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
		-- 	buffer = bufnr,
		-- 	callback = function()
		-- 		vim.diagnostic.config({ virtual_text = vt })
		-- 	end,
		-- })
		-- vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
		-- 	buffer = bufnr,
		-- 	callback = function()
		-- 		vim.diagnostic.config({ virtual_text = false })
		-- 	end,
		-- })
	end

	-- setup lsp servers
	require("mason-lspconfig").setup()
	require("mason-lspconfig").setup_handlers({
		function(server_name)
			require("lspconfig")[server_name].setup({
				on_attach = on_attach,
				capabilities = capabilities,
				settings = servers[server_name],
			})
		end,
		["rust_analyzer"] = function() -- dont autosetup rust_analyzer; use rust-tools instead
			require("rust-tools").setup({
				tools = {
					inlay_hints = { auto = true },
					hover_actions = { border = "solid" },
					executor = require("rust-tools/executors").toggleterm,
				},
				server = {
					on_attach = on_attach,
					standalone = true,
					capabilities = capabilities,
					checkOnSave = {
						allFeatures = true,
						overrideCommand = {
							"cargo",
							"clippy",
							"--workspace",
							"--message-format=json",
							"--all-targets",
							"--all-features",
						},
					},
				},
			})
		end,
	})

	-- setup null-ls
	require("mason-null-ls").setup({
		ensure_installed = ensure_installed, -- lsp, linter, formatter
		automatic_installation = false,
		handlers = {},
	})

	local null_ls = require("null-ls")
	null_ls.setup({
		on_attach = function(client, bufnr)
			-- Custom command to use null-ls as the formatter.
			local format_cmd = function(input)
				vim.lsp.buf.format({
					id = client.id,
					timeout_ms = 5000,
					async = input.bang,
				})
			end

			local bufcmd = vim.api.nvim_buf_create_user_command
			bufcmd(bufnr, "NullFormat", format_cmd, {
				bang = true,
				range = true,
			})

			-- format on save
			-- if client.supports_method("textDocument/formatting") then
			-- 	local format_group = vim.api.nvim_create_augroup("autoformat", { clear = true })
			-- 	vim.api.nvim_create_autocmd("BufWritePre", {
			-- 		group = format_group,
			-- 		buffer = bufnr,
			-- 		callback = function()
			-- 			vim.cmd("NullFormat")
			-- 		end,
			-- 	})
			-- end
		end,
		sources = {
			-- Anything not supported by mason.
			null_ls.builtins.completion.spell,
			null_ls.builtins.code_actions.refactoring,
		},
	})

	-- setup lsp diagnostic signs
	vim.fn.sign_define("DiagnosticSignError", { texthl = "DiagnosticSignError", text = "", numhl = "" })
	vim.fn.sign_define("DiagnosticSignWarn", { texthl = "DiagnosticSignWarn", text = "", numhl = "" })
	vim.fn.sign_define("DiagnosticSignHint", { texthl = "DiagnosticSignHint", text = "", numhl = "" })
	vim.fn.sign_define("DiagnosticSignInfo", { texthl = "DiagnosticSignInfo", text = "", numhl = "" })
end

return M
