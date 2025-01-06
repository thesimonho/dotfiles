return {
  "tadaa/vimade",
  event = "VeryLazy",
  opts = {
    recipe = { "default", { animate = true } },
    ncmode = "windows",
    fadelevel = 0.8, -- any value between 0 and 1. 0 is hidden and 1 is opaque.
    tint = {
      fg = { rgb = { 120, 120, 120 }, intensity = 0.2 },
    },
    groupdiff = true,
    groupscrollbind = true,
    enablefocusfading = false,
    usecursorhold = true,
  },
}
