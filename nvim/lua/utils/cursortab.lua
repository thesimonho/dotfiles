local M = {}

local function replace_once(source, original, replacement)
  local first, last = source:find(original, 1, true)
  assert(first, "cursortab UI patch no longer matches the pinned plugin")
  assert(not source:find(original, last + 1, true), "cursortab UI patch matched more than once")
  return source:sub(1, first - 1) .. replacement .. source:sub(last + 1)
end

function M.install_ui_patch()
  local module_name = "cursortab.ui"
  local source_path = vim.api.nvim_get_runtime_file("lua/cursortab/ui.lua", false)[1]
  assert(source_path, "cursortab UI module not found")
  local source = table.concat(vim.fn.readfile(source_path), "\n")

  source = replace_once(
    source,
    [[	-- Use screenpos so wrap, folds, and virtual lines from other plugins]],
    [[	-- A float is not clipped to its parent, so an unconstrained completion
	-- can cover an adjacent split. Cap it at the source window's right edge.
	local relative_col = overlay_window_col(wininfo, col, screen_anchor)
	local available_width = math.max(1, vim.api.nvim_win_get_width(parent_win) - relative_col)
	max_width = math.max(1, math.min(max_width, available_width))
	local overlay_height = 0
	for _, line_content in ipairs(content_lines) do
		local line_width = vim.fn.strdisplaywidth(line_content)
		overlay_height = overlay_height + math.max(1, math.ceil(line_width / max_width))
	end

	-- Use screenpos so wrap, folds, and virtual lines from other plugins]]
  )
  source = replace_once(source, [[		col = overlay_window_col(wininfo, col, screen_anchor),]], [[		col = relative_col,]])
  source = replace_once(source, [[		height = #content_lines,]], [[		height = overlay_height,]])
  source = replace_once(
    source,
    [[	})

	local overlay_start_line]],
    [[	})
	vim.api.nvim_set_option_value("wrap", true, { win = overlay_win })

	local overlay_start_line]]
  )

  local loader = assert(load(source, "@" .. source_path, "t"))
  package.preload[module_name] = loader
end

return M
