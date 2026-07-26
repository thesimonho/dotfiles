local M = {}
local fs = require("utils.fs")
local general = require("utils.general")
local os = require("utils.os")
local ServiceLifecycle = require("utils.service_lifecycle")

local function read_process_identity(identity_file)
  if vim.fn.filereadable(identity_file) ~= 1 then
    return nil, nil
  end
  local lines = vim.fn.readfile(identity_file, "", 2)
  return tonumber(lines[1]), lines[2]
end

local function is_owned_process_running(process_id, expected_start_time)
  if not process_id or not expected_start_time then
    return false
  end
  local succeeded, result = pcall(vim.uv.kill, process_id, 0)
  return succeeded and result == 0 and os.get_process_start_time(process_id) == expected_start_time
end

local function create_backend(options)
  local safe_name = options.name:lower():gsub("[^%w_.-]", "_")
  local working_directory = fs.absolute_path(options.cwd)
  local log_file = fs.absolute_path(options.log_file)
  local identity_parts = { working_directory or "", unpack(options.command) }
  local environment_keys = vim.tbl_keys(options.environment or {})
  table.sort(environment_keys)
  for _, key in ipairs(environment_keys) do
    table.insert(identity_parts, key .. "=" .. tostring(options.environment[key]))
  end
  local identity = table.concat(identity_parts, "\0")
  local service_key = safe_name .. "_" .. vim.fn.sha256(identity):sub(1, 12)
  local state_directory = vim.fs.joinpath(vim.fn.stdpath("state"), "services", service_key)
  local backend = {
    key = "process_" .. service_key,
    command = options.command,
    cwd = working_directory,
    environment = options.environment,
    health_command = options.health_command,
    health_timeout_ms = options.health_timeout_ms or 5000,
    pid_file = vim.fs.joinpath(state_directory, "process.pid"),
    log_file = log_file or vim.fs.joinpath(state_directory, "process.log"),
    stop_timeout_ms = options.stop_timeout_ms or 10000,
    expects_process = false,
  }

  function backend:start(callback)
    local command = {
      "sh",
      fs.config_path("scripts", "process-service-start.sh"),
      self.pid_file,
      self.log_file,
      self.cwd or "",
      "--",
    }
    command = ServiceLifecycle.with_operation_lock(command, self.operation_lock)
    if self.environment then
      table.insert(command, "env")
      for key, value in pairs(self.environment) do
        table.insert(command, key .. "=" .. value)
      end
    end
    vim.list_extend(command, self.command)
    vim.system(command, { text = true }, function(result)
      vim.schedule(function()
        if result.code == 0 then
          self.expects_process = true
        end
        callback(result)
      end)
    end)
  end

  function backend:stop(callback)
    local command = {
      "sh",
      fs.config_path("scripts", "process-service-stop.sh"),
      self.pid_file,
      tostring(self.stop_timeout_ms),
    }
    command = ServiceLifecycle.with_operation_lock(command, self.operation_lock)
    vim.system(command, { text = true }, function(result)
      vim.schedule(function()
        if result.code == 0 then
          self.expects_process = false
        end
        callback(result)
      end)
    end)
  end

  function backend:release_command()
    return {
      "sh",
      fs.config_path("scripts", "process-service-stop.sh"),
      self.pid_file,
      tostring(self.stop_timeout_ms),
    }
  end

  function backend:read_status(callback)
    local process_id, expected_start_time = read_process_identity(self.pid_file)
    if not is_owned_process_running(process_id, expected_start_time) then
      vim.fn.delete(self.pid_file)
      callback(self.expects_process and "failed" or "stopped", nil, "Process exited; see " .. self.log_file)
      return
    end
    if not self.health_command then
      callback("ready")
      return
    end

    vim.system(self.health_command, { text = true, timeout = self.health_timeout_ms }, function(result)
      vim.schedule(function()
        if result.code == 0 then
          callback("ready")
        elseif is_owned_process_running(process_id, expected_start_time) then
          callback("starting")
        else
          callback("failed", general.trim_string(result.stderr))
        end
      end)
    end)
  end

  return backend
end

--- Create a controller for an owned foreground process.
--- @param options table
--- @return table
function M.new(options)
  vim.validate({
    name = { options.name, "string" },
    command = { options.command, "table" },
    cwd = { options.cwd, "string", true },
    environment = { options.environment, "table", true },
    health_command = { options.health_command, "table", true },
    health_timeout_ms = { options.health_timeout_ms, "number", true },
    log_file = { options.log_file, "string", true },
    stop_timeout_ms = { options.stop_timeout_ms, "number", true },
  })
  return ServiceLifecycle.new(vim.tbl_extend("force", options, {
    backend = create_backend(options),
  }))
end

return M
