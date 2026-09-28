local gh = require('config.pack').gh

-- ============================================================
-- DROPBAR
-- Breadcrumbs in the winbar: file path, then every block around
-- the cursor, like `main > for > if`
--
-- Picked over treesitter-context's sticky headers because it sits
-- in the winbar instead of floating over buffer lines, so the
-- guides from indent-blankline.lua run unbroken to the top of the
-- window. The cost: blocks show as `for` / `if`, not the whole
-- condition text.
-- See `:help dropbar`
-- ============================================================
vim.pack.add { gh 'Bekaboo/dropbar.nvim' }

require('dropbar').setup {
  bar = {
    -- dropbar's default, with treesitter and lsp swapped. Language
    -- servers only report functions and types, so with lsp first a
    -- loop or an if never shows up. Treesitter sees those, lsp stays
    -- as the fallback for buffers with no parser.
    sources = function(buf, _)
      local sources = require 'dropbar.sources'
      local utils = require 'dropbar.utils'
      if vim.bo[buf].ft == 'markdown' then return { sources.path, sources.markdown } end
      if vim.bo[buf].buftype == 'terminal' then return { sources.terminal } end
      return {
        sources.path,
        utils.source.fallback { sources.treesitter, sources.lsp },
      }
    end,
  },
}

-- Only the pick map. dropbar's README also suggests [; (jump to the start
-- of the current block) and ]; (menu of the blocks inside it), left out:
-- `[{` already does the first in brace languages, and the pick menu
-- reaches both.
vim.keymap.set('n', '<leader>lb', require('dropbar.api').pick, { desc = '[L]anguage [B]readcrumbs, pick one' })
