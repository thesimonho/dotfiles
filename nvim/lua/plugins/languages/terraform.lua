local os_utils = require("utils.os")
if not os_utils.has_executable("terraform") then
  return {}
end

vim.filetype.add({
  extension = {
    tf = "terraform",
    tfvars = "terraform",
  },
})

return {}
