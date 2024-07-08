local enabled = true
if not enabled then
  return {}
end

local utils = require("config.utils")

local function StartREPL(repl)
  local tempfile = utils.create_tempfile("wezterm_pane_id.txt")

  -- Use os.execute to run the wezterm CLI command to create a vertical split and get the pane ID
  local command = "wezterm cli split-pane --horizontal --percent 40 -- " .. repl .. " > " .. tempfile
  os.execute(command)

  -- Read the pane ID from the temporary file
  local file = io.open(tempfile, "r")
  local pane_id
  if file then
    pane_id = file:read("*all")
    file:close()
    os.remove(tempfile)
  end

  -- Trim any whitespace from the pane_id
  pane_id = pane_id:gsub("%s+", "")

  -- Set the slime configuration with the pane ID
  vim.b.slime_config = { pane_id = pane_id }
end

local insert_code_chunk = function(lang)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<esc>", true, false, true), "n", true)
  local keys = [[o```{]] .. lang .. [[}<cr>```<esc>O]]
  keys = vim.api.nvim_replace_termcodes(keys, true, false, true)
  vim.api.nvim_feedkeys(keys, "n", false)
end

M = {
  {
    "lukas-reineke/headlines.nvim",
    opts = function(_, opts)
      opts.quarto = {
        query = vim.treesitter.query.parse(
          "markdown",
          [[
          (thematic_break) @dash

          (fenced_code_block) @codeblock

          (block_quote_marker) @quote
          (block_quote (paragraph (inline (block_continuation) @quote)))
          ]]
        ),
        treesitter_language = "markdown",
        codeblock_highlight = "CodeBlock",
        headline_highlights = { "Headline1", "Headline2", "Headline3" },
        fat_headlines = true,
        fat_headline_upper_string = "▄",
        fat_headline_lower_string = "▀",
      }
    end,
  },
  {
    "hrsh7th/nvim-cmp",
    opts = function(_, opts)
      table.insert(opts.sources, { name = "otter", group_index = 0 })
    end,
  },
  {
    "quarto-dev/quarto-nvim",
    dependencies = {
      "jmbuhr/otter.nvim",
      "hrsh7th/nvim-cmp",
      "neovim/nvim-lspconfig",
      "nvim-treesitter/nvim-treesitter",
    },
    ft = "quarto",
    cmd = { "QuartoPreview" },
    keys = {
      {
        "<localleader>p",
        "<cmd>lua require('quarto').quartoPreview()<cr>",
        ft = "quarto",
        desc = "Preview (Quarto)",
      },
      {
        "<localleader>o",
        "<cmd>lua require('otter').activate()<cr>",
        ft = { "quarto" },
        desc = "Activate otter",
      },
      {
        "<localleader>i",
        function()
          insert_code_chunk("python")
        end,
        ft = { "quarto" },
        desc = "Insert code block",
      },
    },
    opts = {
      lspFeatures = {
        enabled = true,
        languages = { "r", "python", "julia", "bash", "lua", "html", "javascript", "typescript" },
      },
      codeRunner = {
        enabled = true,
        default_method = "slime",
      },
      completion = {
        enabled = true,
      },
      keymap = {
        rename = false,
        format = false,
      },
    },
  },
  {
    "GCBallesteros/jupytext.nvim",
    opts = {
      custom_language_formatting = {
        python = {
          extension = "qmd",
          style = "quarto",
          force_ft = "quarto",
        },
      },
    },
  },
  {
    "jpalardy/vim-slime",
    ft = { "python", "quarto" },
    keys = {
      {
        "<localleader>r",
        function()
          StartREPL("poetry run ipython")
        end,
        ft = { "python", "quarto" },
        desc = "Start REPL",
      },
      {
        "<localleader>xx",
        "<cmd>lua require('quarto.runner').run_cell()<cr>",
        ft = { "python", "quarto" },
        mode = "n",
        desc = "Run cell",
      },
      {
        "<localleader>xf",
        "<cmd>lua require('quarto.runner').run_all()<cr>",
        ft = { "python", "quarto" },
        desc = "Run file",
      },
      {
        "<localleader>xa",
        "<cmd>lua require('quarto.runner').run_above()<cr>",
        ft = { "python", "quarto" },
        desc = "Run above",
      },
      {
        "<localleader>xb",
        "<cmd>lua require('quarto.runner').run_below()<cr>",
        ft = { "python", "quarto" },
        desc = "Run below",
      },
      {
        "<localleader>xl",
        "<cmd>lua require('quarto.runner').run_line()<cr>",
        ft = { "python", "quarto" },
        desc = "Run line",
      },
      {
        "<localleader>xx",
        "<cmd>lua require('quarto.runner').run_range()<cr>",
        ft = { "python", "quarto" },
        mode = "v",
        desc = "Run selection",
      },
    },
    init = function()
      vim.b["quarto_is_python_chunk"] = false
      Quarto_is_in_python_chunk = function()
        require("otter.tools.functions").is_otter_language_context("python")
      end

      vim.cmd([[
          let g:slime_dispatch_ipython_pause = 100
            function SlimeOverride_EscapeText_quarto(text)
          call v:lua.Quarto_is_in_python_chunk()
      if exists('g:slime_python_ipython') && len(split(a:text,"\n")) > 1 && b:quarto_is_python_chunk && !(exists('b:quarto_is_r_mode') && b:quarto_is_r_mode)
      return ["%cpaste -q\n", g:slime_dispatch_ipython_pause, a:text, "--", "\n"]
      else
      if exists('b:quarto_is_r_mode') && b:quarto_is_r_mode && b:quarto_is_python_chunk
        return [a:text, "\n"]
      else
      return [a:text]
      end
      end
      endfunction
      ]])

      vim.g.slime_target = "wezterm"
      vim.g.slime_no_mappings = true
      vim.g.slime_bracketed_paste = 1 -- use this if using wezterm
      vim.g.slime_default_config = '{"pane_direction": "right"}'
    end,
    config = function()
      vim.g.slime_input_pid = false
      vim.g.slime_suggest_default = true
      vim.g.slime_menu_config = false
      vim.g.slime_neovim_ignore_unlisted = true

      local function mark_terminal()
        local job_id = vim.b.terminal_job_id
        vim.print("job_id: " .. job_id)
      end

      local function set_terminal()
        vim.fn.call("slime#config", {})
      end
      vim.keymap.set("n", "<localleader>tm", mark_terminal, { desc = "mark terminal" })
      vim.keymap.set("n", "<localleader>ts", set_terminal, { desc = "set terminal" })
    end,
  },
}

return M
