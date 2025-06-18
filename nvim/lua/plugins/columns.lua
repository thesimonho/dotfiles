local git = require("utils.git")

local function get_marks_on_current_line(lineNr, bufNr)
  local marks = {}
  local ignored = { '"', "^", "[", "]", "<", ">" }
  for _, mark in ipairs(vim.fn.getmarklist(bufNr)) do
    local pos = mark.pos
    local name = mark.mark
    if
      pos[1] == bufNr
      and pos[2] == lineNr
      and not name:match("%d")
      and not vim.tbl_contains(ignored, name:sub(2, 2))
    then
      table.insert(marks, string.sub(name, -1))
    end
  end
  return marks
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
                if not args.nu or not args.rnu then
                  return ""
                end

                local marks = get_marks_on_current_line(args.lnum, vim.api.nvim_get_current_buf())

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
                elseif args.virtnum > 0 then
                  hl = "SnacksIndent"
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
                if not args.nu or not args.rnu then
                  return ""
                end

                local hl = git.get_git_sign_hl(vim.api.nvim_get_current_buf(), args.lnum)

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
