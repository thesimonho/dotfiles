-- NOTE: mid sentence inserts before a space autocloses brackets - useful? annoying?

return {
  "windwp/nvim-autopairs",
  event = "InsertEnter",
  config = true,
  opts = {
    disable_filetype = { "TelescopePrompt", "spectre_panel" },
    check_ts = true,
    ignored_next_char = [=[[%w%%%'%[%"%.%`%$%{%(%<]]=],
    enable_check_bracket_line = true,
  },
}
