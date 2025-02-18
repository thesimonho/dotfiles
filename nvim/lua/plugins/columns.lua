local git = require("utils.git")

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
                elseif args.relnum % 5 == 0 then -- every 5th line
                  hl = "CursorLineSign"
                else
                  hl = "LineNr"
                end

                local lnum = args.rnu and (args.relnum > 0 and args.relnum or (args.nu and args.lnum or 0)) or args.lnum
                local pad = (" "):rep(args.nuw - #tostring(lnum))
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
