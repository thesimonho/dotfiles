local ServiceLifecycle = {}
ServiceLifecycle.__index = ServiceLifecycle

local default_spinner_frames = require("config.constants").spinner

local function trim_output(output)
  return (output or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function get_process_start_time(process_id)
  local result = vim.system({ "ps", "-o", "lstart=", "-p", tostring(process_id) }, { text = true }):wait()
  return result.code == 0 and trim_output(result.stdout) or nil
end

local function get_script(script_name)
  local module_path = debug.getinfo(1, "S").source:sub(2)
  local nvim_directory = vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(module_path)))
  return vim.fs.joinpath(nvim_directory, "scripts", script_name)
end

--- Create lifecycle management around a service backend.
--- @param options table
--- @return table
function ServiceLifecycle.new(options)
  vim.validate({
    name = { options.name, "string" },
    backend = { options.backend, "table" },
    poll_interval_ms = { options.poll_interval_ms, "number", true },
    poll_timeout_ms = { options.poll_timeout_ms, "number", true },
    spinner_frames = { options.spinner_frames, "table", true },
    session_scoped = { options.session_scoped, "boolean", true },
    on_state_change = { options.on_state_change, "function", true },
  })

  local spinner_frames = options.spinner_frames
  if not spinner_frames or #spinner_frames == 0 then
    spinner_frames = default_spinner_frames
  end

  local controller = setmetatable({
    name = options.name,
    backend = options.backend,
    session_scoped = options.session_scoped or false,
    session_registered = false,
    poll_interval_ms = options.poll_interval_ms or 1000,
    poll_timeout_ms = options.poll_timeout_ms or 60000,
    spinner_frames = spinner_frames,
    on_state_change = options.on_state_change,
    desired_running = false,
    lifecycle_state = "stopped",
    transition_generation = 0,
    operation_in_progress = false,
    progress_step = 0,
    notification_id = "service_" .. options.backend.key,
  }, ServiceLifecycle)

  if controller.session_scoped then
    controller:register_session()
  end
  return controller
end

function ServiceLifecycle:register_session()
  local process_id = vim.fn.getpid()
  local process_start_time = get_process_start_time(process_id)
  if self.session_registered or not process_start_time then
    return
  end

  local session_directory = vim.fs.joinpath(vim.fn.stdpath("run"), "nvim-services", self.backend.key)
  local session_lease = vim.fs.joinpath(session_directory, process_id .. ".lease")
  local registration =
    vim.system({ "sh", get_script("service-register.sh"), session_directory, session_lease, process_start_time }):wait()
  if registration.code ~= 0 then
    return
  end

  self.backend.operation_lock = vim.fs.joinpath(session_directory, ".operation-lock")
  self.session_registered = true
  self.session_directory = session_directory
  self.session_lease = session_lease

  local group = vim.api.nvim_create_augroup("service_" .. self.backend.key, { clear = true })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    once = true,
    callback = function()
      self:release_session()
    end,
    desc = "Release " .. self.name .. " service session",
  })
end

function ServiceLifecycle:release_session()
  if not self.session_registered then
    return
  end

  self.session_registered = false
  local command = { "sh", get_script("service-release.sh"), self.session_directory, self.session_lease, "--" }
  vim.list_extend(command, self.backend:release_command())
  vim.fn.jobstart(command, { detach = true })
end

function ServiceLifecycle:is_enabled()
  return self.desired_running
end

function ServiceLifecycle:set_lifecycle_state(lifecycle_state)
  if self.lifecycle_state == lifecycle_state then
    return
  end

  local previous_state = self.lifecycle_state
  self.lifecycle_state = lifecycle_state
  if self.on_state_change then
    self.on_state_change(lifecycle_state)
  end

  if lifecycle_state == "starting" or lifecycle_state == "stopping" then
    self.transition_started_at = vim.uv.now()
    self.progress_step = 0
    self:notify_progress(lifecycle_state == "starting" and "Waiting for health" or "Stopping")
  elseif lifecycle_state == "ready" or (lifecycle_state == "stopped" and previous_state ~= "failed") then
    self:hide_progress()
  end
end

function ServiceLifecycle:notify_progress(message)
  self.progress_step = self.progress_step + 1
  local elapsed_seconds = math.floor((vim.uv.now() - (self.transition_started_at or vim.uv.now())) / 1000)
  local spinner = self.spinner_frames[(self.progress_step - 1) % #self.spinner_frames + 1]
  vim.notify(string.format("%s  %s · %ds", spinner, message, elapsed_seconds), vim.log.levels.INFO, {
    id = self.notification_id,
    title = self.name .. " service",
    timeout = false,
  })
end

function ServiceLifecycle:animate_transition(generation, lifecycle_state, message)
  if generation ~= self.transition_generation or self.lifecycle_state ~= lifecycle_state then
    return
  end
  self:notify_progress(message)
  vim.defer_fn(function()
    self:animate_transition(generation, lifecycle_state, message)
  end, self.poll_interval_ms)
end

function ServiceLifecycle:hide_progress()
  require("snacks.notifier").hide(self.notification_id)
end

function ServiceLifecycle:notify_failure(message)
  vim.notify(message, vim.log.levels.ERROR, { id = self.notification_id, title = self.name .. " service" })
end

function ServiceLifecycle:fail_start(generation, message)
  self.desired_running = false
  self:set_lifecycle_state("failed")
  self:notify_failure(message)
  self.backend:stop(function(result)
    if generation == self.transition_generation and result.code == 0 then
      self:set_lifecycle_state("stopped")
    end
  end)
end

function ServiceLifecycle:poll_until_ready(generation, deadline)
  if generation ~= self.transition_generation or not self.desired_running then
    return
  end

  self.backend:read_status(function(lifecycle_state, error_message, detail)
    if generation ~= self.transition_generation or not self.desired_running then
      return
    end
    if lifecycle_state == "ready" then
      self:set_lifecycle_state("ready")
      return
    end

    local has_timed_out = vim.uv.now() >= deadline
    if error_message or lifecycle_state == "failed" or has_timed_out then
      local message = error_message or detail or string.format("%s did not become healthy in time", self.name)
      self:fail_start(generation, message)
      return
    end

    self:set_lifecycle_state("starting")
    self:notify_progress("Waiting for health")
    vim.defer_fn(function()
      self:poll_until_ready(generation, deadline)
    end, self.poll_interval_ms)
  end)
end

function ServiceLifecycle:refresh()
  if self.lifecycle_state == "starting" or self.lifecycle_state == "stopping" then
    return
  end

  local generation = self.transition_generation
  self.backend:read_status(function(lifecycle_state, error_message)
    if generation ~= self.transition_generation or error_message then
      return
    end
    self.desired_running = lifecycle_state == "ready" or lifecycle_state == "starting"
    self:set_lifecycle_state(lifecycle_state)
    if lifecycle_state == "starting" then
      self:poll_until_ready(generation, vim.uv.now() + self.poll_timeout_ms)
    end
  end)
end

function ServiceLifecycle:run_operation(should_run)
  self.operation_in_progress = true
  local operation = should_run and self.backend.start or self.backend.stop
  operation(self.backend, function(result)
    self.operation_in_progress = false
    if should_run ~= self.desired_running then
      self:run_operation(self.desired_running)
      return
    end
    if result.code ~= 0 then
      self.desired_running = not should_run
      self:set_lifecycle_state(should_run and "stopped" or "ready")
      local error_message = result.stderr or ""
      self:notify_failure(
        error_message ~= "" and error_message or string.format("Service exited with status %s", result.code)
      )
      return
    end
    if should_run then
      local generation = self.transition_generation
      self:poll_until_ready(generation, vim.uv.now() + self.poll_timeout_ms)
    else
      self:set_lifecycle_state("stopped")
    end
  end)
end

function ServiceLifecycle:set_running(should_run)
  self.transition_generation = self.transition_generation + 1
  local generation = self.transition_generation
  self.desired_running = should_run
  self:set_lifecycle_state(should_run and "starting" or "stopping")
  if not should_run then
    self:animate_transition(generation, "stopping", "Stopping")
  end
  if not self.operation_in_progress then
    self:run_operation(should_run)
  end
end

return ServiceLifecycle
