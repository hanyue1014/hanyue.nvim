-- ============================================================
-- KEYMAPS
-- Basic keymaps plus the diagnostic config that goes with them
--
-- Only plugin-free keymaps live here. Anything that needs a plugin
-- loaded (telescope, gitsigns, lsp) is defined in that plugin's own
-- file, so I always know where to look.
-- ============================================================

-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- better movement for word wrap
-- j/k move by screen row on wrapped lines, but `5j` still counts real lines.
-- `x` not `v`, so typing j/k in select mode still replaces the selection.
vim.keymap.set({ 'n', 'x' }, 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, desc = 'Down (screen row when wrapped)' })
vim.keymap.set({ 'n', 'x' }, 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, desc = 'Up (screen row when wrapped)' })

-- MUST: kj to escape
vim.keymap.set('i', 'kj', '<Esc>', { desc = 'Exit insert mode' })

-- MUST: change/delete/paste without yanking
-- delete without yanking
vim.keymap.set({ 'n', 'v' }, '<leader>d', '"_d', { desc = 'Delete without yanking' })
vim.keymap.set({ 'n', 'v' }, '<leader>D', '"_D', { desc = 'Delete to EOL without yanking' })

-- change without yanking
vim.keymap.set({ 'n', 'v' }, '<leader>c', '"_c', { desc = 'Change without yanking' })
vim.keymap.set({ 'n', 'v' }, '<leader>C', '"_C', { desc = 'Change to EOL without yanking' })

-- paste over selection without clobbering the register
vim.keymap.set('v', '<leader>p', '"_dP', { desc = 'Paste without yanking replaced text' })

-- insert: ctrl+backspace / ctrl+delete delete a word, like other editors
-- <C-w> is the built in "delete word before cursor", and it already joins
-- with the previous line at the start of a line (see `:help 'backspace'`)
vim.keymap.set('i', '<C-BS>', '<C-w>', { desc = 'Delete previous word' })
-- terminals send ctrl+backspace as <C-h> (Neovide sends a real <C-BS>)
vim.keymap.set('i', '<C-h>', '<C-w>', { desc = 'Delete previous word (terminal)' })

-- `dw` can't join lines, so at the end of a line fall back to <Del>
vim.keymap.set('i', '<C-Del>', function()
  -- in insert mode the cursor can sit after the last character, so a column
  -- past the line's length means we're at the end: <Del> joins the next line
  -- up. Otherwise `"_dw` deletes the next word without touching the register.
  if vim.fn.col '.' > #vim.fn.getline '.' then return '<Del>' end
  return '<C-o>"_dw'
end, { expr = true, desc = 'Delete next word' })

-- visual: stay in visual mode after indenting, so >>> or <<< just works
vim.keymap.set('v', '>', '>gv', { desc = 'Indent and keep selection' })
vim.keymap.set('v', '<', '<gv', { desc = 'Outdent and keep selection' })

-- toggle comments with Neovim's built in `gc`, under the [L]anguage group.
-- `remap` is needed because `gc`/`gcc` are mappings themselves, not builtins
vim.keymap.set('n', '<leader>lc', 'gcc', { remap = true, desc = '[L]anguage: [C]omment line' })
vim.keymap.set('x', '<leader>lc', 'gc', { remap = true, desc = '[L]anguage: [C]omment selection' })

-- visual: move the selection (thank you theprimeagen)
vim.keymap.set('v', 'J', ":m '>+1<cr>gv=gv", { desc = 'Move selection down' })
vim.keymap.set('v', 'K', ":m '<-2<cr>gv=gv", { desc = 'Move selection up' })

-- normal: move the current line
vim.keymap.set('n', '<A-j>', '<cmd>m .+1<cr>==', { desc = 'Move line down' })
vim.keymap.set('n', '<A-k>', '<cmd>m .-2<cr>==', { desc = 'Move line up' })

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic Config & Keymaps
--  See `:help vim.diagnostic.Opts`
vim.diagnostic.config {
  update_in_insert = false,
  severity_sort = true,
  float = { border = 'rounded', source = 'if_many' },
  underline = { severity = { min = vim.diagnostic.severity.WARN } },

  -- Can switch between these as you prefer
  virtual_text = true, -- Text shows up at the end of the line
  virtual_lines = false, -- Text shows up underneath the line, with virtual lines

  -- Auto open the float, so you can easily read the errors when jumping with `[d` and `]d`
  jump = {
    on_jump = function(_, bufnr)
      vim.diagnostic.open_float {
        bufnr = bufnr,
        scope = 'cursor',
        focus = false,
      }
    end,
  },
}

vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- TIP: Disable arrow keys in normal mode
-- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
-- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
-- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
-- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use SPACE+w+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set('n', '<leader>wh', '<C-w><C-h>', { desc = 'Move focus left' })
vim.keymap.set('n', '<leader>wj', '<C-w><C-j>', { desc = 'Move focus down' })
vim.keymap.set('n', '<leader>wk', '<C-w><C-k>', { desc = 'Move focus up' })
vim.keymap.set('n', '<leader>wl', '<C-w><C-l>', { desc = 'Move focus right' })

-- window creation and deletion
vim.keymap.set('n', '<leader>wv', '<C-w>v', { desc = 'Split vertical' })
vim.keymap.set('n', '<leader>ws', '<C-w>s', { desc = 'Split horizontal' })
vim.keymap.set('n', '<leader>wq', '<C-w>q', { desc = 'Close window' })

-- leader key window resizes (have to repeat the whole sequence everytime)
vim.keymap.set('n', '<leader>wH', '<cmd>vertical resize -4<cr>', { desc = 'Narrower Window' })
vim.keymap.set('n', '<leader>wL', '<cmd>vertical resize +4<cr>', { desc = 'Wider Window' })
vim.keymap.set('n', '<leader>wJ', '<cmd>resize -4<cr>', { desc = 'Shorter Window' })
vim.keymap.set('n', '<leader>wK', '<cmd>resize +4<cr>', { desc = 'Taller Window' })
vim.keymap.set('n', '<leader>w=', '<C-w>=', { desc = 'Equalize Window' })
vim.keymap.set('n', '<leader>wm', '<C-w>_<C-w>|', { desc = 'Maximize Window' })

-- repeatable resizes
vim.keymap.set('n', '<C-Up>', '<cmd>resize +2<cr>', { desc = 'Window Height +' })
vim.keymap.set('n', '<C-Down>', '<cmd>resize -2<cr>', { desc = 'Window Height -' })
vim.keymap.set('n', '<C-Left>', '<cmd>vertical resize -2<cr>', { desc = 'Window Width -' })
vim.keymap.set('n', '<C-Right>', '<cmd>vertical resize +2<cr>', { desc = 'Window Width +' })

-- NOTE: Some terminals have colliding keymaps or are not able to send distinct keycodes
-- I don't move windows
-- vim.keymap.set("n", "<C-S-h>", "<C-w>H", { desc = "Move window to the left" })
-- vim.keymap.set("n", "<C-S-l>", "<C-w>L", { desc = "Move window to the right" })
-- vim.keymap.set("n", "<C-S-j>", "<C-w>J", { desc = "Move window to the lower" })
-- vim.keymap.set("n", "<C-S-k>", "<C-w>K", { desc = "Move window to the upper" })
