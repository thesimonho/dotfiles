return {
  "nvim-pack/nvim-spectre",
  opts = {
    live_update = true,
    highlight = {
      headers = "SpectreFaint",
      filedirectory = "SpectreFaint",
      border = "SpectreFaint",
    },
    mapping = {
      ["tab"] = {
        map = "<Tab>",
        cmd = "<cmd>lua require('spectre').tab()<cr>",
        desc = "next",
      },
      ["shift-tab"] = {
        map = "<S-Tab>",
        cmd = "<cmd>lua require('spectre').tab_shift()<cr>",
        desc = "previous",
      },
      ["toggle_line"] = {
        map = "dd",
        cmd = "<cmd>lua require('spectre').toggle_line()<CR>",
        desc = "toggle",
      },
      ["enter_file"] = {
        map = "<cr>",
        cmd = "<cmd>lua require('spectre.actions').select_entry()<CR>",
        desc = "open file",
      },
      ["send_to_qf"] = {
        map = "<c-q>",
        cmd = "<cmd>lua require('spectre.actions').send_to_qf()<CR>",
        desc = "send to quickfix",
      },
      ["replace_cmd"] = {
        map = "<localleader>c",
        cmd = "<cmd>lua require('spectre.actions').replace_cmd()<CR>",
        desc = "input replace command",
      },
      ["show_option_menu"] = {
        map = "<localleader>o",
        cmd = "<cmd>lua require('spectre').show_options()<CR>",
        desc = "show options",
      },
      ["run_current_replace"] = {
        map = "<localleader>r",
        cmd = "<cmd>lua require('spectre.actions').run_current_replace()<CR>",
        desc = "replace line",
      },
      ["run_replace"] = {
        map = "<localleader>R",
        cmd = "<cmd>lua require('spectre.actions').run_replace()<CR>",
        desc = "replace all",
      },
      ["change_view_mode"] = {
        map = "<localleader>v",
        cmd = "<cmd>lua require('spectre').change_view()<CR>",
        desc = "change result view mode",
      },
      ["change_replace_sed"] = {
        map = "<localleader>ts",
        cmd = "<cmd>lua require('spectre').change_engine_replace('sed')<CR>",
        desc = "use sed to replace",
      },
      ["change_replace_oxi"] = {
        map = "<localleader>to",
        cmd = "<cmd>lua require('spectre').change_engine_replace('oxi')<CR>",
        desc = "use oxi to replace",
      },
      ["toggle_live_update"] = {
        map = "<localleader>tu",
        cmd = "<cmd>lua require('spectre').toggle_live_update()<CR>",
        desc = "update on write",
      },
      ["toggle_ignore_case"] = {
        map = "<localleader>ti",
        cmd = "<cmd>lua require('spectre').change_options('ignore-case')<CR>",
        desc = "toggle ignore case",
      },
      ["toggle_ignore_hidden"] = {
        map = "<localleader>th",
        cmd = "<cmd>lua require('spectre').change_options('hidden')<CR>",
        desc = "toggle search hidden",
      },
      ["resume_last_search"] = {
        map = "<localleader>l",
        cmd = "<cmd>lua require('spectre').resume_last_search()<CR>",
        desc = "repeat last search",
      },
      ["select_template"] = {
        map = "<localleader>p",
        cmd = "<cmd>lua require('spectre.actions').select_template()<CR>",
        desc = "pick template",
      },
    },
  },
}
