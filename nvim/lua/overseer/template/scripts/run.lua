local files = require("overseer.files")

return {
	generator = function(opts, cb)
		local scripts = vim.tbl_filter(function(filename)
			return filename:match("%.sh$")
		end, files.list_files(opts.dir))
		local ret = {}
		for _, filename in ipairs(scripts) do
			table.insert(ret, {
				name = "Run: " .. filename,
				params = {
					args = { optional = true, type = "list", delimiter = " " },
				},
				builder = function(params)
					return {
						cmd = { files.join(opts.dir, filename) },
						args = params.args,
					}
				end,
			})
		end

		cb(ret)
	end,
}
