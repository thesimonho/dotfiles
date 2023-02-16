local M = {
  'VonHeikemen/lsp-zero.nvim',
  cond = vim.g.vscode == nil,
  enabled = true,
  branch = 'v1.x',
  dependencies = {
    -- LSP Support
    { 'neovim/nvim-lspconfig' }, -- Required
    { 'williamboman/mason.nvim' }, -- Optional
    { 'williamboman/mason-lspconfig.nvim' }, -- Optional
    { 'jay-babu/mason-null-ls.nvim' },
    { 'jose-elias-alvarez/null-ls.nvim',  dependencies = 'nvim-lua/plenary.nvim' },

    -- Autocompletion
    { 'hrsh7th/nvim-cmp' }, -- Required
    { 'hrsh7th/cmp-nvim-lsp' }, -- Required
    { 'hrsh7th/cmp-buffer' }, -- Optional
    { 'hrsh7th/cmp-path' }, -- Optional
    { 'saadparwaiz1/cmp_luasnip' }, -- Optional
    { 'hrsh7th/cmp-nvim-lua' }, -- Optional

    -- Snippets
    { 'L3MON4D3/LuaSnip' }, -- Required
    { 'rafamadriz/friendly-snippets' }, -- Optional
  },
  event = 'VeryLazy',
}

function M.config()
  local lsp = require('lsp-zero').preset({
    name = 'recommended',
    set_lsp_keymaps = false,
    manage_nvim_cmp = true,
    suggest_lsp_servers = true,
  })

  lsp.on_attach(function(client, bufnr)
    local map = vim.keymap.set

    map('n', '<leader>g', '{}', { desc = "LSP" }) -- prefix
    map('n', '<leader>gD', '<cmd>lua vim.lsp.buf.declaration()<cr>', { desc = "Declaration", buffer = bufnr })
    map('n', '<leader>gd', '<cmd>lua vim.lsp.buf.definition()<cr>', { desc = "Definition", buffer = bufnr })
    map('n', '<leader>gt', '<cmd>lua vim.lsp.buf.type_definition()<cr>', { desc = "Type Definition", buffer = bufnr })
    map('n', '<leader>gr', '<cmd>lua vim.lsp.buf.references()<cr>', { desc = "Find all references", buffer = bufnr })
    map('n', '<leader>gR', '<cmd>lua vim.lsp.buf.rename()<cr>', { desc = "Rename", buffer = bufnr })
    map('n', '<leader>gi', '<cmd>lua vim.lsp.buf.implementation()<cr>', { desc = "Implementation", buffer = bufnr })
    map('n', '<leader>gf', '<cmd>:NullFormat<cr>', { desc = "Format with null-ls", buffer = bufnr })
    map('n', '<leader>gs', '<cmd>lua vim.lsp.buf.signature_help()<cr>', { desc = "Signature", buffer = bufnr })
    map('n', '<leader>gh', '<cmd>lua vim.lsp.buf.hover()<cr>', { desc = "Hover", buffer = bufnr })
    map('n', '<leader>ga', '<cmd>lua vim.lsp.buf.code_action()<cr>', { desc = "Code Action", buffer = bufnr })
    map('n', '<leader>ge', '<cmd>lua vim.diagnostic.open_float()<cr>', { desc = "Show Error", buffer = bufnr })
    map('n', '<leader>gE', '<cmd>TroubleToggle<cr>', { desc = "Trouble List", buffer = bufnr })
    map('n', '<leader>g[', '<cmd>lua vim.diagnostic.goto_prev()<cr>', { desc = "Prev", buffer = bufnr })
    map('n', '<leader>g]', '<cmd>lua vim.diagnostic.goto_next()<cr>', { desc = "Next", buffer = bufnr })
  end)

  -- Configure lua language server for neovim
  lsp.nvim_workspace()
  lsp.setup()

  vim.diagnostic.config({
    virtual_text = false,
    signs = true,
    update_in_insert = false,
    underline = false,
    severity_sort = true,
    float = {
      focusable = true,
      border = 'rounded',
      source = 'always',
    },
  })

  -- Configure null-ls
  local null_ls = require('null-ls')
  local null_opts = lsp.build_options('null-ls', {})

  null_ls.setup({
    on_attach = function(client, bufnr)
      null_opts.on_attach(client, bufnr)

      -- Custom command to use null-ls as the formatter.
      local format_cmd = function(input)
        vim.lsp.buf.format({
          id = client.id,
          timeout_ms = 5000,
          async = input.bang,
        })
      end

      local bufcmd = vim.api.nvim_buf_create_user_command
      bufcmd(bufnr, 'NullFormat', format_cmd, {
        bang = true,
        range = true,
      })
    end,
    sources = {}
  })

  -- Make null-ls aware of the tools installed using mason.nvim, and configure them automatically.
  require('mason-null-ls').setup({
    ensure_installed = nil,
    automatic_installation = true,
    automatic_setup = true,
  })
  require('mason-null-ls').setup_handlers()
end

return M