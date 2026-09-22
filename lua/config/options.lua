-- ============================================================
-- OPTIONS
-- Core Neovim settings, leaders, options
--
-- This file must be required first: it sets the leader key, and
-- that has to happen before any plugin gets loaded.
-- ============================================================

-- Enable faster startup by caching compiled Lua modules
vim.loader.enable()

-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = false

-- [[ Setting options ]]
--  See `:help vim.o`
-- NOTE: You can change these options as you wish!
--  For more options, you can see `:help option-list`

-- Make line numbers default
vim.o.number = true
vim.o.relativenumber = true

-- Enable mouse mode, can be useful for resizing splits for example!
vim.o.mouse = 'a'

-- Don't show the mode, since it's already in the status line
-- I think the some theme disables this
-- TODO revisit
-- vim.o.showmode = false

-- Sets keyboard provider to OSC52 (special control sequence to copy to host's clipboard)
-- Only some terminal emulator supports it though
-- Only a remote terminal session needs OSC 52. Local desktop (xclip/wl-copy),
-- native Windows, and WSL (win32yank/clip.exe) are all auto-detected.
if vim.env.SSH_TTY then
  local osc52 = require 'vim.ui.clipboard.osc52'
  vim.g.clipboard = {
    name = 'osc52',
    copy = { ['+'] = osc52.copy '+', ['*'] = osc52.copy '*' },
    -- Copy-only: most terminals refuse to let a program *read* the clipboard,
    -- so reading would hang or silently fail. Paste from the unnamed register.
    paste = {
      ['+'] = function() return vim.split(vim.fn.getreg '', '\n') end,
      ['*'] = function() return vim.split(vim.fn.getreg '', '\n') end,
    },
  }
end

-- Sync clipboard between OS and Neovim.
--  Schedule the setting after `UiEnter` because it can increase startup-time.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)

-- Enable break indent
vim.o.breakindent = true

-- Enable undo/redo changes even after closing and reopening a file
vim.o.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.o.signcolumn = 'yes'

-- Decrease update time
vim.o.updatetime = 250

-- Decrease mapped sequence wait time
vim.o.timeoutlen = 300

-- Configure how new splits should be opened
vim.o.splitright = true
vim.o.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
--
--  Notice listchars is set using `vim.opt` instead of `vim.o`.
--  It is very similar to `vim.o` but offers an interface for conveniently interacting with tables.
--   See `:help lua-options`
--   and `:help lua-guide-options`
vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- Preview substitutions live, as you type!
vim.o.inccommand = 'split'

-- Show which line your cursor is on
vim.o.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.o.scrolloff = 10

-- NOTE: the indentation options used to sit here, they moved to
-- `lua/config/indent.lua` so all the tab width stuff lives in one place.
