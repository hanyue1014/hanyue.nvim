local gh = require('config.pack').gh

-- ============================================================
-- TOKYONIGHT
-- ============================================================
vim.pack.add { gh 'folke/tokyonight.nvim' }

---@diagnostic disable-next-line: missing-fields
require('tokyonight').setup {
  styles = {
    comments = { italic = false }, -- Disable italics in comments
  },
}
