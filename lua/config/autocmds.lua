-- ============================================================
-- AUTOCOMMANDS
-- Basic autocmds that don't belong to any one plugin
--
-- The indentation autocmds live in `lua/config/indent.lua`, and
-- the LSP ones live in `lua/plugins/lsp.lua`.
-- ============================================================

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.hl.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function() vim.hl.on_yank() end,
})

-- Show every file by its path relative to the cwd (`src/x.c`), however it was
-- opened. A buffer keeps the name it was opened with: the start screen opens
-- relative paths, telescope and neo-tree full ones, so `:f` / <C-g> showed
-- either. Neovim only re-shortens names when the cwd changes, and `:cd .`
-- counts as a change without moving anywhere.
--   - noautocmd: nothing sees a DirChanged, since nothing really changed
--   - lcd / tcd when the window or tab has its own directory, so that stays
--   - renaming the buffer instead would break `:w` (E13: File exists)
-- The full path is still one key away: <leader>fp, or :CopyPath.
vim.api.nvim_create_autocmd('BufWinEnter', {
  desc = 'Show file names relative to the cwd',
  group = vim.api.nvim_create_augroup('hanyue-relative-names', { clear = true }),
  callback = function()
    local cd = vim.fn.haslocaldir() == 1 and 'lcd' or vim.fn.haslocaldir(-1, 0) == 1 and 'tcd' or 'cd'
    vim.cmd('noautocmd silent ' .. cd .. ' .')
  end,
})
