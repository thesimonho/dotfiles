-- Integrate Mason with nvim lsp and null-ls
local M = {
	"williamboman/mason-lspconfig.nvim",
	cond = vim.g.vscode == nil,
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
		"marksman",
		"powershell-editor-services",
		"pyright",
		"rust-analyzer",
		"taplo",
		"typescript-language-server",
		"vim-language-server",
		"yaml-language-server",

		-- linters
		"eslint_d",
		"markdownlint",
		"ruff",

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

	-- settings for lsp servers
	local servers = {
		lua_ls = {
			Lua = {
				workspace = { checkThirdParty = false },
				telemetry = { enable = false },
				diagnostics = {
					globals = { "vim" },
				},
			},
		},
	}

	-- on_attach function to be added to each server
	local on_attach = function(_, bufnr)
		-- map buffer local keys once lsp is attached
		MapLSP(bufnr)
		-- vim.diagnostic.config({ virtual_text = false })

		-- create buffer local autocommands to show and hide virtual diagnostic text
		local vt = {
			spacing = 10,
			severity = { min = vim.diagnostic.severity.WARN },
			format = function(diagnostic)
				local severity_letter = string.sub(vim.diagnostic.severity[diagnostic.severity], 1, 1)
				local msg = diagnostic.message
				local msg_threshold = 100

				local num_windows = #vim.api.nvim_tabpage_list_wins(0) / 2
				if num_windows > 1 then
					msg_threshold = msg_threshold / num_windows
				end

				if string.len(msg) > msg_threshold then
					msg = string.sub(msg, 1, msg_threshold) .. "..."
				end

				return string.format("%s: %s", severity_letter, msg)
			end,
		}
		vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
			buffer = bufnr,
			callback = function()
				vim.diagnostic.config({ virtual_text = vt })
			end,
		})
		vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
			buffer = bufnr,
			callback = function()
				vim.diagnostic.config({ virtual_text = false })
			end,
		})
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
		automatic_setup = true,
	})
	require("mason-null-ls").setup_handlers()
	require("null-ls").setup({
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
		end,
		sources = {
			-- Anything not supported by mason.
			require("null-ls").builtins.code_actions.gitsigns,
		},
	})

	-- setup lsp diagnostic signs
	vim.fn.sign_define("DiagnosticSignError", { texthl = "DiagnosticSignError", text = "", numhl = "" })
	vim.fn.sign_define("DiagnosticSignWarn", { texthl = "DiagnosticSignWarn", text = "", numhl = "" })
	vim.fn.sign_define("DiagnosticSignHint", { texthl = "DiagnosticSignHint", text = "", numhl = "" })
	vim.fn.sign_define("DiagnosticSignInfo", { texthl = "DiagnosticSignInfo", text = "", numhl = "" })
end

return M
