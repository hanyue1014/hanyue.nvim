local gh = require('config.pack').gh

-- ============================================================
-- INDENT-BLANKLINE
-- A guide at every indent level, blank lines included
--
-- Meant to be read together with the breadcrumbs from dropbar.lua:
-- the winbar says which loop / if the cursor is in, the guides show
-- where each of them runs. The scope under the cursor (treesitter)
-- is highlighted, so a `break` inside an `if` inside a `for` shows
-- the if's guide lit up and the loop's guide still there beside it.
--
-- The defaults already skip nofile / terminal / quickfix buffers,
-- which covers the start screen and neo-tree, so nothing needs
-- excluding by hand.
-- See `:help ibl`
-- ============================================================
vim.pack.add { gh 'lukas-reineke/indent-blankline.nvim' }
require('ibl').setup {}
