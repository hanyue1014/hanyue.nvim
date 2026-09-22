local gh = require('config.pack').gh

-- ============================================================
-- TODO-COMMENTS
-- Highlights TODO / FIXME / NOTE / HACK / WARN in comments
-- ============================================================

-- Highlight todo, notes, etc in comments
vim.pack.add { gh 'folke/todo-comments.nvim' }
require('todo-comments').setup { signs = false }
