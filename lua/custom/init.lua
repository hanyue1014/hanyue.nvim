-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information

-- This is kickstart's loader, just moved up one folder out of `plugins/` so
-- that the directory below holds nothing but actual plugins.

-- Colorscheme gets required by name first, otherwise it loads whenever the
-- filesystem happens to hand it over and you get a flash of the default theme
-- on startup. `require` caches, so the loop below won't run it a second time.
require 'custom.plugins.colorscheme'

-- Iterate over all Lua files in the plugins directory and load them.
-- `vim.fs.dir()` iteration order is unspecified and must not be relied upon.
local plugins_dir = vim.fs.joinpath(vim.fn.stdpath 'config', 'lua', 'custom', 'plugins')
for file_name, type in vim.fs.dir(plugins_dir, { follow = true }) do
  if (type == 'file' or type == 'link') and file_name:match '%.lua$' then
    local module = file_name:gsub('%.lua$', '')
    require('custom.plugins.' .. module)
  end
end
