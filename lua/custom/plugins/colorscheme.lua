local gh = require('config.pack').gh

-- ============================================================
-- COLORSCHEME
-- catppuccin (default, pastel + transparent) and tokyonight (spare)
-- ============================================================

-- [[ Colorscheme ]]
-- You can easily change to a different colorscheme.
-- Change the name of the colorscheme plugin below, and then
-- change the command under that to load whatever the name of that colorscheme is.
--
-- If you want to see what colorschemes are already installed, you can use `:Telescope colorscheme`.
--
-- I keep two installed. catppuccin-mocha is the default because it is pastel
-- and has a proper transparent mode. tokyonight sticks around because I still
-- like it, so `:colorscheme tokyonight-night` whenever I want the change.

-- NOTE: catppuccin's repo is literally called `catppuccin/nvim`, so vim.pack
-- would name the plugin folder just "nvim", which is confusing. Passing an
-- explicit `name` keeps it readable in `:lua vim.pack.update()`.
vim.pack.add {
  { src = gh 'catppuccin/nvim', name = 'catppuccin' },
  gh 'folke/tokyonight.nvim',
}

---@diagnostic disable-next-line: missing-fields
require('tokyonight').setup {
  styles = {
    comments = { italic = false }, -- Disable italics in comments
  },
}

require('catppuccin').setup {
  flavour = 'mocha', -- latte (light), frappe, macchiato, mocha (darkest)

  -- NOTE: the terminal has to be transparent too, nvim can't do it by itself.
  -- On Windows Terminal that's `opacity` / `useAcrylic` in its settings.json.
  transparent_background = true,

  -- Tells catppuccin to also theme these plugins instead of leaving them
  -- on whatever default highlight groups they picked.
  integrations = {
    blink_cmp = true,
    gitsigns = true,
    mason = true,
    mini = { enabled = true },
    native_lsp = { enabled = true },
    telescope = { enabled = true },
    treesitter = true,
    which_key = true,
  },
}

-- Load the colorscheme here.
-- Like tokyonight, this one has different styles too, and you could load
-- any other flavour by changing `flavour` above or using the full name here,
-- such as 'catppuccin-frappe', 'catppuccin-macchiato' or 'catppuccin-latte'.
vim.cmd.colorscheme 'catppuccin'
