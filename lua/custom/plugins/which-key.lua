local gh = require('config.pack').gh

-- ============================================================
-- WHICH-KEY
-- Popup showing what keys are available after a prefix
-- ============================================================

-- Useful plugin to show you pending keybinds.
vim.pack.add { gh 'folke/which-key.nvim' }
require('which-key').setup {
  -- Delay between pressing a key and opening which-key (milliseconds). Long
  -- enough that typing a mapping I already know never flashes the popup, it
  -- only shows up when I stop and think. Raise it if it still gets in the way.
  delay = 500,
  icons = { mappings = vim.g.have_nerd_font },
  -- Document existing key chains
  spec = {
    { '<leader>f', group = '[F]ind / [F]ile', mode = { 'n', 'x' } },
    { '<leader>l', group = '[L]anguage', mode = { 'n', 'x' } },
    { '<leader>t', group = '[T]oggle' },
    { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'x' } }, -- Enable gitsigns recommended keymaps first
    { '<leader>w', group = '[W]indow Actions' },
    { 'gr', group = 'LSP Actions', mode = { 'n' } },
  },
}
