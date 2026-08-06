local agents = {
  { cmd = "codex", bin = "codex", label = "Codex" },
  { cmd = "claude --allow-dangerously-skip-permissions", bin = "claude", label = "Claude Code" },
  { cmd = "pi", bin = "pi", label = "Pi" },
}
local available_agents = {}
local open_agents = {}
for _, agent in ipairs(agents) do
  if vim.fn.executable(agent.bin) == 1 then
    available_agents[#available_agents + 1] = agent
  end
end

local function create_agent_terminal(agent)
  local Terminal = require("toggleterm.terminal").Terminal

  local t = Terminal:new({
    count = 5, -- always set to terminal #5
    cmd = agent.cmd,
    display_name = agent.label,
    direction = "tab",
    close_on_exit = true,
    auto_scroll = false,
    hidden = true,
    float_opts = {
      border = "rounded",
    },
    on_open = function(term)
      vim.cmd("startinsert!")
      vim.keymap.set("t", "<Esc>", "<Esc>", { buffer = term.bufnr, silent = true, noremap = true })
    end,
    on_stderr = function(_, job, data, name)
      if not data or #data == 0 then
        return
      end

      local msg = table.concat(data, "\n")
      msg = msg:gsub("%s+$", "")
      if msg == "" then
        return
      end

      vim.notify(msg, vim.log.levels.ERROR, {
        title = string.format("%s (%s)", name, job),
      })
    end,
    on_exit = function()
      open_agents[agent] = nil
    end,
  })
  return t
end

local function get_single_open_agent(open)
  local key, value = next(open)
  if not key then
    return nil
  end

  if next(open_agents, key) ~= nil then
    return nil
  end

  return value
end

local function get_agent_terminal(open, agent)
  local t = open[agent]
  if t then
    return t
  end

  t = create_agent_terminal(agent)
  open_agents[agent] = t
  return t
end

vim.keymap.set({ "n", "i", "v", "t" }, "<C-.>", function()
  local single = get_single_open_agent(open_agents)
  if single then
    single:toggle()
    return
  end

  vim.ui.select(available_agents, {
    prompt = "Select an AI agent",
    format_item = function(agent)
      return string.format("%s", agent.label)
    end,
  }, function(choice)
    if not choice then
      return
    end
    get_agent_terminal(open_agents, choice):toggle()
  end)
end, { noremap = true, silent = true })

local function show_agent_terminal()
  local t = open_agents[next(open_agents or {})]
  if t and not t:is_open() then
    t:open()
  end
end

vim.keymap.set("v", "<leader>as", function()
  vim.cmd("'<,'>ToggleTermSendVisualSelection 5")
  show_agent_terminal()
end, { noremap = true, silent = true, desc = "Send selection to agent terminal" })

local completion_model = {
  label = "Qwen2.5-Coder-1.5B",
  model = "QuantFactory/Qwen2.5-Coder-1.5B-GGUF:Q6_K",
  download_size = "1.3GB",
  context_size = "8192",
}

--- cursortab runs its own daemon; nvim owns only the model server. Hold off
--- requests until it is healthy, so keystrokes during a first-run download do
--- not each burn a timeout. Also called after setup(), since the plugin loads
--- lazily and can miss the transition that made the server ready.
--- @param lifecycle_state string
local function set_completion_requests_enabled(lifecycle_state)
  local ok, daemon = pcall(require, "cursortab.daemon")
  if ok then
    daemon.set_enabled(lifecycle_state == "ready")
  end
end

--- Compose service on Linux, native process on darwin: Docker on macOS has no
--- Metal passthrough, so a containerised llama-server there would run on CPU.
--- @return table
local function new_completion_service()
  if require("utils.os").is_darwin() then
    return require("utils.process_service").new({
      name = "Completion model",
      progress_context = completion_model.label,
      command = {
        "llama-server",
        "-hf",
        completion_model.model,
        "--host",
        "127.0.0.1",
        "--port",
        "8000",
        "--ctx-size",
        completion_model.context_size,
        "--cache-type-k",
        "q8_0",
        "--cache-type-v",
        "q8_0",
        -- auto, not 999: leaves llama.cpp its 1GiB margin on shared memory.
        "--n-gpu-layers",
        "auto",
        "--flash-attn",
        "auto",
        -- One slot, not the default 4: one editor, and 4 slots quadruple KV.
        "--parallel",
        "1",
      },
      health_command = {
        "curl",
        "--fail",
        "--silent",
        "--max-time",
        "5",
        "http://127.0.0.1:8000/health",
      },
      -- Generous: a first start downloads the weights over -hf's single
      -- connection. `hf download <repo> <file>` pre-warms far faster.
      poll_timeout_ms = 1800000,
      session_scoped = true,
      install_hint = "enable my.gpu.backend so llama.nix installs llama-cpp",
      slow_start_hint = string.format(
        "First run downloads %s of weights; pre-warm with `hf download %s`.",
        completion_model.download_size,
        completion_model.model:gsub(":.*", "")
      ),
      on_state_change = set_completion_requests_enabled,
    })
  end

  return require("utils.compose_service").new({
    name = "Completion model",
    progress_context = completion_model.label,
    compose_file = "~/dotfiles/AI/completion.yaml",
    service = "fim",
    docker_context = "default",
    wait_for_health = true,
    starting_message = "Preparing model",
    poll_timeout_ms = 600000,
    session_scoped = true,
    install_hint = "install Docker Engine with the NVIDIA Container Toolkit",
    on_state_change = set_completion_requests_enabled,
  })
end

local completion_service = new_completion_service()

local function configure_completion_toggle()
  require("snacks")
    .toggle({
      name = "AI Suggestions",
      get = function()
        return completion_service:is_enabled()
      end,
      set = function(is_enabled)
        completion_service:set_running(is_enabled)
      end,
    })
    :map("<leader>ul")
end

local M = {
  {
    "cursortab/cursortab.nvim",
    event = "LazyFile",
    -- Go >= 1.25.0; mise provides the toolchain (see nix/modules/mise.nix).
    build = "cd server && go build",
    init = function()
      -- Unconditional by design: the start script is idempotent under its lock,
      -- so a second nvim attaches to the running server instead of racing it
      -- onto the same port. <leader>ul still toggles it off.
      completion_service:set_running(true)

      local completion_group = vim.api.nvim_create_augroup("completion_model", { clear = true })
      vim.api.nvim_create_autocmd("FocusGained", {
        group = completion_group,
        callback = function()
          completion_service:refresh()
        end,
        desc = "Refresh completion model state",
      })

      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        once = true,
        callback = function()
          vim.schedule(configure_completion_toggle)
        end,
      })
    end,
    opts = {
      -- Flipped on by set_completion_requests_enabled once the server is up.
      enabled = false,
      -- Only debug logs the assembled prompt and the raw completion, which is
      -- what makes a model swap diagnosable. Drop to "info" once settled.
      log_level = "debug",
      provider = {
        -- Fill-in-the-middle, not next-edit: infills at the cursor and emits a
        -- line or two, where the edit-mode providers rewrite a whole span.
        type = "fim",
        url = "http://127.0.0.1:8000",
        completion_path = "/v1/completions",
        -- Ignored by llama-server, which holds one model; named for the logs.
        model = "qwen2.5-coder-1.5b",
        -- Raising context_size means raising the server's --ctx-size to match.
        max_tokens = 128,
        context_size = 1024,
        completion_timeout = 5000,
        -- fim_tokens is set in `config` below -- see the note there.
      },
      keymaps = {
        -- <Tab>/<S-Tab> are the plugin defaults and collide with blink.cmp.
        accept = "<M-l>",
        partial_accept = "<M-h>",
      },
    },
    config = function(_, opts)
      require("cursortab").setup(opts)

      -- Written here, not passed to setup(): fim_tokens is missing from
      -- cursortab's default_config, and its validator rejects any key the
      -- defaults lack (upstream bug, still on main 2026-08-06). Landing it
      -- before the deferred daemon spawn is what gets it into CURSORTAB_CONFIG;
      -- check with `jq .provider ~/.local/state/nvim/cursortab/*.config.json`.
      --
      -- Without it the provider falls back to prompt+suffix mode, which sends
      -- no stop tokens and runs to max_tokens on every request. repo_name and
      -- file_sep are what carry cross-file context, and are spelled out because
      -- the auto-detection only runs on the setup() path that errors.
      --
      -- PSM order, matching Qwen. The builder always emits prefix->suffix->
      -- middle, so an SPM-only model like Mellum-4b cannot be used here.
      local provider = require("cursortab.config").get().provider
      provider.fim_tokens = {
        prefix = "<|fim_prefix|>",
        suffix = "<|fim_suffix|>",
        middle = "<|fim_middle|>",
        repo_name = "<|repo_name|>",
        file_sep = "<|file_sep|>",
      }
      -- The service may already have reached "ready" before this plugin was
      -- loaded, in which case its on_state_change fired into a module that did
      -- not exist yet. Reconcile against the state it is actually in.
      set_completion_requests_enabled(completion_service.lifecycle_state)
    end,
  },
  {
    "supermaven-inc/supermaven-nvim",
    enabled = false,
    event = "LazyFile",
    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        once = true,
        callback = function()
          vim.schedule(function()
            require("snacks")
              .toggle({
                name = "AI Suggestions",
                get = function()
                  return require("supermaven-nvim.api").is_running() or false
                end,
                set = function()
                  require("supermaven-nvim.api").toggle()
                end,
              })
              :map("<leader>ul")
          end)
        end,
      })
    end,
    opts = {
      keymaps = {
        accept_suggestion = "<M-l>",
        clear_suggestion = "<C-e>",
        accept_word = "<M-h>",
      },
      ignore_filetypes = { "bigfile", "neo-tree-popup", "snacks_picker_input", "snacks_input", "snacks_notif" },
      color = {
        cterm = 244,
      },
      log_level = "off",
    },
  },
}

return M
