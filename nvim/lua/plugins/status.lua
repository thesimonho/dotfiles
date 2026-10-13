local git = require("utils.git")

-- statuscol refreshes args.tick once per redraw. Keep buffer data on its
-- window-owned args table so wrapped rows reuse it and closed windows release it.
local function redraw_cache(args)
  local cache = args.dotfiles_cache
  if cache and cache.tick == args.tick and cache.buf == args.buf then
    return cache
  end
  cache = { tick = args.tick, buf = args.buf, marks = {}, git = {} }
  local ignored = { '"', "^", "[", "]", "<", ">" }
  for _, mark in ipairs(vim.fn.getmarklist(args.buf)) do
    local pos, name = mark.pos, mark.mark
    if pos[1] == args.buf and not name:match("%d") and not vim.tbl_contains(ignored, name:sub(2, 2)) then
      cache.marks[pos[2]] = cache.marks[pos[2]] or {}
      table.insert(cache.marks[pos[2]], name:sub(-1))
    end
  end
  args.dotfiles_cache = cache
  return cache
end

return {
  {
    "luukvbaal/statuscol.nvim",
    event = "LazyFile",
    config = function()
      local builtin = require("statuscol.builtin")
      require("statuscol").setup({
        relculright = true,
        segments = {
          {
            sign = {
              name = { ".*" },
              namespace = { "diagnostic/signs" },
              maxwidth = 2,
              colwidth = 1,
              auto = false,
              wrap = true,
            },
            click = "v:lua.ScSa",
          },
          {
            text = {
              function(args)
                if not args.nu and not args.rnu then
                  return ""
                end

                local marks = redraw_cache(args).marks[args.lnum] or {}

                -- highlights
                local hl
                if args.relnum == 0 then -- current line
                  local mode = vim.api.nvim_get_mode().mode
                  if mode == "i" or mode == "R" then
                    hl = "Special2"
                  elseif mode == "v" or mode == "V" or mode == "\22" then
                    hl = "Special3"
                  else
                    hl = "Special1"
                  end
                elseif #marks > 0 then
                  hl = "Mark"
                else
                  hl = "LineNr"
                end

                -- numbers
                local lnum
                local pad
                if args.virtnum > 0 then
                  lnum = "↪"
                  pad = (" "):rep(args.nuw - 1)
                elseif #marks > 0 and args.relnum ~= 0 then
                  lnum = marks[1]
                  pad = (" "):rep(args.nuw - #tostring(lnum))
                else
                  if args.rnu then
                    if args.relnum > 0 then
                      lnum = args.relnum
                    elseif args.nu then
                      lnum = args.lnum
                    else
                      lnum = 0
                    end
                  else
                    lnum = args.lnum
                  end
                  pad = (" "):rep(args.nuw - #tostring(lnum))
                end
                return "%#" .. hl .. "#%=" .. pad .. tostring(lnum)
              end,
            },
            click = "v:lua.ScLa",
          },
          {
            text = {
              function(args)
                if not args.nu and not args.rnu then
                  return ""
                end

                local cache = redraw_cache(args)
                if cache.git[args.lnum] == nil then
                  cache.git[args.lnum] = git.get_git_sign_hl(args.buf, args.lnum) or false
                end
                local hl = cache.git[args.lnum]

                if hl then
                  return "%#" .. hl .. "#%=" .. " ┃"
                else
                  return "%#LineNr#%=" .. " │"
                end
              end,
            },
          },
          {
            text = { builtin.foldfunc, " " },
            auto = false,
            click = "v:lua.ScFa",
          },
        },
      })
    end,
  },
}
