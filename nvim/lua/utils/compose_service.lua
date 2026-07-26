local M = {}

local function trim_output(output)
  return (output or ""):gsub("%s+$", "")
end

local function get_command_script()
  local module_path = debug.getinfo(1, "S").source:sub(2)
  local nvim_directory = vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(module_path)))
  return vim.fs.joinpath(nvim_directory, "scripts", "service-command.sh")
end

local function compose_command(backend, arguments)
  local command = { "docker" }
  if backend.docker_context then
    vim.list_extend(command, { "--context", backend.docker_context })
  end
  vim.list_extend(command, { "compose", "--file", backend.compose_file })
  vim.list_extend(command, arguments)
  return command
end

local function create_backend(options)
  local identity =
    table.concat({ options.docker_context or "", vim.fn.expand(options.compose_file), options.service }, "\0")
  local backend = {
    key = "compose_" .. options.service:gsub("[^%w_.-]", "_") .. "_" .. vim.fn.sha256(identity):sub(1, 12),
    compose_file = vim.fn.expand(options.compose_file),
    service = options.service,
    docker_context = options.docker_context,
    wait_for_health = options.wait_for_health or false,
  }

  function backend:run(arguments, callback)
    local command = compose_command(self, arguments)
    if self.operation_lock and (arguments[1] == "up" or arguments[1] == "stop") then
      command = { "sh", get_command_script(), self.operation_lock, "--", unpack(command) }
    end
    vim.system(command, { text = true }, function(result)
      vim.schedule(function()
        callback(result)
      end)
    end)
  end

  function backend:start(callback)
    self:run({ "up", "--detach", self.service }, callback)
  end

  function backend:stop(callback)
    self:run({ "stop", self.service }, callback)
  end

  function backend:release_command()
    return compose_command(self, { "stop", self.service })
  end

  function backend:read_status(callback)
    self:run({ "ps", "--all", "--format", "json", self.service }, function(result)
      if result.code ~= 0 then
        local message = trim_output(result.stderr)
        callback(nil, message ~= "" and message or "Unable to read Docker Compose service status")
        return
      end

      local output = trim_output(result.stdout)
      local has_status, status = pcall(vim.json.decode, output)
      status = output ~= "" and has_status and status or nil
      if not status then
        callback("stopped")
      elseif status.State ~= "running" then
        callback(status.State == "exited" and "failed" or "stopped", nil, status.Status)
      elseif not self.wait_for_health or status.Health == "healthy" then
        callback("ready")
      else
        callback(status.Health == "unhealthy" and "failed" or "starting", nil, status.Status)
      end
    end)
  end

  return backend
end

--- Create a controller for one Docker Compose service.
--- @param options table
--- @return table
function M.new(options)
  vim.validate({
    name = { options.name, "string" },
    compose_file = { options.compose_file, "string" },
    service = { options.service, "string" },
    docker_context = { options.docker_context, "string", true },
    wait_for_health = { options.wait_for_health, "boolean", true },
  })

  return require("utils.service_lifecycle").new(vim.tbl_extend("force", options, {
    backend = create_backend(options),
  }))
end

return M
