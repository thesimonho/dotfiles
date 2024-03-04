# Plugins

Lazy.nvim will auto load all plugins found in the `modules` directory.

To temporarily disable a plugin, there are a couple of options:

1. Set the `enabled` property to `false` in the module file. Details [here](https://github.com/folke/lazy.nvim#-plugin-spec)
2. Rename the module file from `*.lua` to `*.bak` (anything but lua)

To delete a plugin, remove the module file entirely.
