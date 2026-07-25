local ComposeService = {}
ComposeService.__index = ComposeService

local default_spinner_frames = require("config.constants").spinner

local function get_process_start_time(process_id)
  local process_stat = io.open(string.format("/proc/%s/stat", process_id), "r")
  if not process_stat then
    return nil
  end

  local stat_content = process_stat:read("*a")
  process_stat:close()

  local fields_after_name = stat_content:match("^%d+ %b() (.+)$")
  if not fields_after_name then
    return nil
  end

  local process_fields = vim.split(fields_after_name, "%s+")
  return process_fields[20]
end

local function get_release_script()
  local module_path = debug.getinfo(1, "S").source:sub(2)
  local nvim_directory = vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(module_path)))
  return vim.fs.joinpath(nvim_directory, "scripts", "compose-service-release.sh")
end

local function trim_output(output)
  return (output or ""):gsub("%s+$", "")
end

--- Create a controller for one Docker Compose service.
--- @param options { name: string, compose_file: string, service: string, docker_context: string|nil, wait_for_health: boolean|nil, poll_interval_ms: integer|nil, poll_timeout_ms: integer|nil, spinner_frames: string[]|nil, session_scoped: boolean|nil, on_state_change: fun(state: string)|nil }
--- @return table
function ComposeService.new(options)
  vim.validate({
    name = { options.name, "string" },
    compose_file = { options.compose_file, "string" },
    service = { options.service, "string" },
    docker_context = { options.docker_context, "string", true },
    wait_for_health = { options.wait_for_health, "boolean", true },
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
    compose_file = vim.fn.expand(options.compose_file),
    service = options.service,
    docker_context = options.docker_context,
    session_scoped = options.session_scoped or false,
    session_registered = false,
    wait_for_health = options.wait_for_health or false,
    poll_interval_ms = options.poll_interval_ms or 1000,
    poll_timeout_ms = options.poll_timeout_ms or 60000,
    spinner_frames = spinner_frames,
    on_state_change = options.on_state_change,
    desired_running = false,
    lifecycle_state = "stopped",
    transition_generation = 0,
    progress_step = 0,
    transition_started_at = nil,
    notification_id = string.format("compose_service_%s_%s", options.name, options.service),
  }, ComposeService)

  if controller.session_scoped then
    controller:register_session()
  end

  return controller
end

--- Register this Neovim process as a user of the Compose service.
function ComposeService:register_session()
  if self.session_registered then
    return
  end

  local process_id = vim.fn.getpid()
  local process_start_time = get_process_start_time(process_id)
  if not process_start_time then
    return
  end

  local safe_service_name = self.service:gsub("[^%w_.-]", "_")
  local session_directory = vim.fs.joinpath(vim.fn.stdpath("run"), "nvim-compose-services", safe_service_name)
  vim.fn.mkdir(session_directory, "p")

  local lease_name = string.format("%s-%s.lease", process_id, process_start_time)
  local session_lease = vim.fs.joinpath(session_directory, lease_name)
  local lock_file = vim.fs.joinpath(session_directory, ".lock")
  local registration = vim
    .system({ "flock", lock_file, "tee", session_lease }, {
      stdin = process_start_time .. "\n",
      text = true,
    })
    :wait()
  if registration.code ~= 0 then
    return
  end

  self.session_registered = true
  self.session_directory = session_directory
  self.session_lease = session_lease

  local session_group = vim.api.nvim_create_augroup("compose_service_" .. safe_service_name, { clear = true })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = session_group,
    once = true,
    callback = function()
      self:release_session()
    end,
    desc = "Release " .. self.name .. " container session",
  })
end

--- Release this process lease and let a detached helper stop an unused service.
function ComposeService:release_session()
  if not self.session_registered then
    return
  end

  self.session_registered = false
  vim.fn.jobstart({
    "sh",
    get_release_script(),
    self.session_directory,
    self.session_lease,
    self.compose_file,
    self.service,
    self.docker_context or "",
  }, { detach = true })
end

--- Return whether the user currently wants the service enabled.
--- @return boolean
function ComposeService:is_enabled()
  return self.desired_running
end

--- Update lifecycle state and notify the integration when it changes.
--- @param lifecycle_state "stopped"|"starting"|"ready"|"stopping"|"failed"
function ComposeService:set_lifecycle_state(lifecycle_state)
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
  elseif lifecycle_state == "ready" then
    self:hide_progress()
  elseif lifecycle_state == "stopped" and previous_state ~= "failed" then
    self:hide_progress()
  end
end

--- Update the persistent notification for an in-progress transition.
--- @param message string
function ComposeService:notify_progress(message)
  self.progress_step = self.progress_step + 1
  local started_at = self.transition_started_at or vim.uv.now()
  local elapsed_seconds = math.floor((vim.uv.now() - started_at) / 1000)
  local spinner_index = (self.progress_step - 1) % #self.spinner_frames + 1
  local spinner = self.spinner_frames[spinner_index]

  vim.notify(string.format("%s  %s · %ds", spinner, message, elapsed_seconds), vim.log.levels.INFO, {
    id = self.notification_id,
    title = self.name .. " container",
    timeout = false,
  })
end

--- Keep an in-progress notification moving while a Compose command runs.
--- @param generation integer
--- @param lifecycle_state "starting"|"stopping"
--- @param message string
function ComposeService:animate_transition(generation, lifecycle_state, message)
  if generation ~= self.transition_generation or self.lifecycle_state ~= lifecycle_state then
    return
  end

  self:notify_progress(message)
  vim.defer_fn(function()
    self:animate_transition(generation, lifecycle_state, message)
  end, self.poll_interval_ms)
end

--- Dismiss a completed transition without adding a success notification.
function ComposeService:hide_progress()
  require("snacks.notifier").hide(self.notification_id)
end

--- Run a Docker Compose command asynchronously.
--- @param arguments string[]
--- @param callback fun(result: vim.SystemCompleted)
function ComposeService:run(arguments, callback)
  local command = { "docker" }
  if self.docker_context then
    vim.list_extend(command, { "--context", self.docker_context })
  end
  vim.list_extend(command, { "compose", "--file", self.compose_file })
  vim.list_extend(command, arguments)
  vim.system(command, { text = true }, function(result)
    vim.schedule(function()
      callback(result)
    end)
  end)
end

--- Show a lifecycle failure without blocking Neovim.
--- @param message string
function ComposeService:notify_failure(message)
  vim.notify(message, vim.log.levels.ERROR, {
    id = self.notification_id,
    title = self.name .. " container",
  })
end

--- Parse one service record from `docker compose ps --format json`.
--- @param output string
--- @return table|nil
function ComposeService:parse_service_status(output)
  local status_json = trim_output(output)
  if status_json == "" then
    return nil
  end

  local has_status, status = pcall(vim.json.decode, status_json)
  return has_status and status or nil
end

--- Determine the lifecycle state represented by a Compose service record.
--- @param status table|nil
--- @return "stopped"|"starting"|"ready"|"failed"
function ComposeService:classify_status(status)
  if not status then
    return "stopped"
  end

  if status.State ~= "running" then
    return status.State == "exited" and "failed" or "stopped"
  end

  if not self.wait_for_health or status.Health == "healthy" then
    return "ready"
  end

  return status.Health == "unhealthy" and "failed" or "starting"
end

--- Read the current Compose service record.
--- @param callback fun(status: table|nil, error_message: string|nil)
function ComposeService:read_status(callback)
  self:run({ "ps", "--all", "--format", "json", self.service }, function(result)
    if result.code ~= 0 then
      local error_message = trim_output(result.stderr)
      callback(nil, error_message ~= "" and error_message or "Unable to read Docker Compose service status")
      return
    end

    callback(self:parse_service_status(result.stdout), nil)
  end)
end

--- Roll back a failed start and stop any unhealthy container left behind.
--- @param generation integer
--- @param message string
function ComposeService:fail_start(generation, message)
  self.desired_running = false
  self:set_lifecycle_state("failed")
  self:notify_failure(message)
  self:run({ "stop", self.service }, function(result)
    if generation == self.transition_generation and result.code == 0 then
      self:set_lifecycle_state("stopped")
    end
  end)
end

--- Poll until the requested service is ready or definitively fails.
--- @param generation integer
--- @param deadline integer
function ComposeService:poll_until_ready(generation, deadline)
  if generation ~= self.transition_generation or not self.desired_running then
    return
  end

  self:read_status(function(status, error_message)
    if generation ~= self.transition_generation or not self.desired_running then
      return
    end

    local lifecycle_state = self:classify_status(status)
    if lifecycle_state == "ready" then
      self:set_lifecycle_state("ready")
      return
    end

    local has_timed_out = vim.uv.now() >= deadline
    if error_message or lifecycle_state == "failed" or has_timed_out then
      local failure_message = string.format("%s did not become healthy in time", self.name)
      if error_message then
        failure_message = error_message
      elseif lifecycle_state == "failed" and status then
        failure_message = status.Status
      end
      self:fail_start(generation, failure_message)
      return
    end

    self:set_lifecycle_state("starting")
    self:notify_progress("Waiting for health")
    vim.defer_fn(function()
      self:poll_until_ready(generation, deadline)
    end, self.poll_interval_ms)
  end)
end

--- Reconcile desired and lifecycle state with Docker Compose.
function ComposeService:refresh()
  local has_active_transition = self.lifecycle_state == "starting" or self.lifecycle_state == "stopping"
  if has_active_transition then
    return
  end

  local generation = self.transition_generation
  self:read_status(function(status, error_message)
    if generation ~= self.transition_generation or error_message then
      return
    end

    local lifecycle_state = self:classify_status(status)
    self.desired_running = lifecycle_state == "ready" or lifecycle_state == "starting"
    self:set_lifecycle_state(lifecycle_state)

    if lifecycle_state == "starting" then
      local deadline = vim.uv.now() + self.poll_timeout_ms
      self:poll_until_ready(generation, deadline)
    end
  end)
end

--- Optimistically request that the service starts or stops.
--- @param should_run boolean
function ComposeService:set_running(should_run)
  self.transition_generation = self.transition_generation + 1
  local generation = self.transition_generation
  local previous_desired_state = self.desired_running

  self.desired_running = should_run
  self:set_lifecycle_state(should_run and "starting" or "stopping")
  local arguments = should_run and { "up", "--detach", self.service } or { "stop", self.service }
  if not should_run then
    self:animate_transition(generation, "stopping", "Stopping")
  end
  self:run(arguments, function(result)
    if generation ~= self.transition_generation then
      return
    end

    if result.code ~= 0 then
      self.desired_running = previous_desired_state
      self:set_lifecycle_state(previous_desired_state and "ready" or "stopped")
      local message = trim_output(result.stderr)
      self:notify_failure(
        message ~= "" and message or string.format("Docker Compose exited with status %s", result.code)
      )
      return
    end

    if should_run then
      local deadline = vim.uv.now() + self.poll_timeout_ms
      self:poll_until_ready(generation, deadline)
    else
      self:set_lifecycle_state("stopped")
    end
  end)
end

return ComposeService
