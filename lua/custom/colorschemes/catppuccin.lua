local gh = require('config.pack').gh

-- ============================================================
-- CATPPUCCIN
-- ============================================================

-- NOTE: catppuccin's repo is literally called `catppuccin/nvim`, so vim.pack
-- would name the plugin folder just "nvim", which is confusing. Passing an
-- explicit `name` keeps it readable in `:lua vim.pack.update()`.
vim.pack.add { { src = gh 'catppuccin/nvim', name = 'catppuccin' } }

require('catppuccin').setup {
  flavour = 'macchiato', -- latte (light), frappe, macchiato, mocha (darkest)

  -- NOTE: the terminal has to be transparent too, nvim can't do it by itself.
  -- On Windows Terminal that's `opacity` / `useAcrylic` in its settings.json,
  -- in neovide it's `neovide_opacity`.
  transparent_background = true,

  -- Tells catppuccin to also theme these plugins instead of leaving them
  -- on whatever default highlight groups they picked.
  integrations = {
    blink_cmp = true,
    dropbar = { enabled = true },
    gitsigns = true,
    indent_blankline = { enabled = true, scope_color = 'mauve' },
    mason = true,
    mini = { enabled = true },
    native_lsp = { enabled = true },
    telescope = { enabled = true },
    treesitter = true,
    which_key = true,
  },
}
