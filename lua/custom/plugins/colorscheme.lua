-- ============================================================
-- COLORSCHEME
-- Loads every colorscheme in `lua/custom/colorschemes/`, then
-- applies the default below
--
-- Each file there installs and sets up one colorscheme, nothing
-- else, so adding one is a new file and removing one is deleting
-- its file. All of them stay installed, so `:colorscheme <name>`
-- (or `:Telescope colorscheme`) switches for the session.
-- ============================================================

-- The one applied on startup. Must be a colorscheme set up in that folder.
local default = 'catppuccin'

local colorschemes_dir = vim.fs.joinpath(vim.fn.stdpath 'config', 'lua', 'custom', 'colorschemes')
for file_name, type in vim.fs.dir(colorschemes_dir, { follow = true }) do
  if (type == 'file' or type == 'link') and file_name:match '%.lua$' then
    local module = file_name:gsub('%.lua$', '')
    require('custom.colorschemes.' .. module)
  end
end

vim.cmd.colorscheme(default)
