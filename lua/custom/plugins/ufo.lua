local gh = require('config.pack').gh

-- ============================================================
-- NVIM-UFO
-- Folding: where the fold ranges come from, and what a closed
-- fold looks like
-- ============================================================

-- The built in `foldmethod=expr` + `vim.treesitter.foldexpr()` gets you folds,
-- but a closed fold is then just its first line with nothing on it to say how
-- much is hidden. ufo draws the fold line as virtual text, so it gets a marker
-- on the end, and the line keeps its real syntax highlighting.
--
-- It also falls back to indent folds in buffers with no treesitter parser,
-- where the plain foldexpr setup gives you no folds at all.
--
-- promise-async is ufo's one dependency and has to be added before it, so both
-- live in this file. See the note at the bottom of init.lua about ordering.
vim.pack.add {
  gh 'kevinhwang91/promise-async',
  gh 'kevinhwang91/nvim-ufo',
}

-- [[ The options ufo needs ]]
--  See `:help folding`
--
-- There is deliberately no 'foldmethod' or 'foldexpr' here. ufo drives the
-- folds itself: it sets foldmethod=manual per window and applies the ranges
-- its providers hand back, so anything set here would just be overridden.
--
-- 'foldlevel' and 'foldlevelstart' at 99 means files open with everything
-- unfolded. ufo needs this specifically, it reads foldlevel to decide what to
-- close, and the default of 0 would open every file fully collapsed.
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldenable = true

-- No fold column. A one cell wide chevron in the gutter is easy to lose next
-- to the sign column and the relative numbers, and the marker on the fold line
-- is the legible version of the same information. `'1'` or `'auto:1'` here
-- brings the gutter back if you ever want both.
vim.o.foldcolumn = '0'

-- Pad the rest of a closed fold's line with spaces. The default is `·`, which
-- would trail dots off to the right of the marker.
vim.opt.fillchars:append { fold = ' ' }

-- [[ What a closed fold looks like ]]
--
-- ufo already does this by default: its own handler appends ` ⋯ ` highlighted
-- as UfoFoldedEllipsis, which links to Comment. Delete this function and the
-- `fold_virt_text_handler` line below to go back to that.
--
-- This one only changes the marker to `>…` and adds the line count. The loop
-- is the part that isn't free: `virt_text` is the fold's first line in
-- {text, highlight} chunks, and without measuring it against `width` a long
-- first line pushes the marker off the right edge, which puts you back to a
-- fold with no marker on it. ufo's `truncate` cuts the chunk that straddles
-- the edge.
local function fold_marker(virt_text, lnum, end_lnum, width, truncate)
  local suffix = ('  >… %d lines '):format(end_lnum - lnum)
  local budget = width - vim.fn.strdisplaywidth(suffix)

  local chunks, used = {}, 0
  for _, chunk in ipairs(virt_text) do
    local chunk_width = vim.fn.strdisplaywidth(chunk[1])
    if used + chunk_width > budget then
      chunks[#chunks + 1] = { truncate(chunk[1], budget - used), chunk[2] }
      break
    end
    chunks[#chunks + 1] = chunk
    used = used + chunk_width
  end

  -- MoreMsg is the group ufo's own README example uses for the suffix. It's a
  -- stock highlight, so the colorscheme owns the colour and this file doesn't
  -- have to guess at one: #89b4fa under catppuccin, a fairly loud blue.
  --
  -- For a quieter marker, 'Comment' (#9399b2, and italic under catppuccin) and
  -- 'LspInlayHint' (#6c7086, matching the hints from <leader>th) are both stock
  -- too, so either is a one word swap here.
  chunks[#chunks + 1] = { suffix, 'MoreMsg' }
  return chunks
end

require('ufo').setup {
  -- 'treesitter' ahead of ufo's default 'lsp': the parsers are already
  -- installed by treesitter.lua and are there the moment the buffer opens,
  -- with no waiting on a language server to attach. 'indent' is the fallback
  -- for anything treesitter has no parser for.
  provider_selector = function() return { 'treesitter', 'indent' } end,

  fold_virt_text_handler = fold_marker,
}

-- zR and zM have to go through ufo. The built in ones only move 'foldlevel',
-- and ufo is the thing actually holding the fold ranges, so the built ins
-- would only half work.
vim.keymap.set('n', 'zR', require('ufo').openAllFolds, { desc = 'Open all folds' })
vim.keymap.set('n', 'zM', require('ufo').closeAllFolds, { desc = 'Close all folds' })
