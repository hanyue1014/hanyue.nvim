local gh = require('config.pack').gh

-- ============================================================
-- MINI.NVIM
-- icons, around/inside textobjects, surround, statusline, start screen
--
-- All the mini modules share one plugin, so they share one file.
-- ============================================================

-- [[ mini.nvim ]]
--  A collection of various small independent plugins/modules
vim.pack.add { gh 'nvim-mini/mini.nvim' }

-- If a nerd font is available, load the icons module for pretty icons in various plugins.
if vim.g.have_nerd_font then
  require('mini.icons').setup()
  -- Used for backwards compatibility with plugins that require `nvim-web-devicons` (e.g. telescope.nvim)
  MiniIcons.mock_nvim_web_devicons()
end

-- Better Around/Inside textobjects
--
-- Examples:
--  - va)  - [V]isually select [A]round [)]paren
--  - yiiq - [Y]ank [I]nside [I]+1 [Q]uote
--  - ci'  - [C]hange [I]nside [']quote
require('mini.ai').setup {
  -- NOTE: Avoid conflicts with the built-in incremental selection mappings on Neovim>=0.12 (see `:help treesitter-incremental-selection`)
  mappings = {
    around_next = 'aa',
    inside_next = 'ii',
  },
  n_lines = 500,
}

-- Add/delete/replace surroundings (brackets, quotes, etc.)
--
-- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
-- - sd'   - [S]urround [D]elete [']quotes
-- - sr)'  - [S]urround [R]eplace [)] [']
require('mini.surround').setup()

-- Jump anywhere on screen, like leap: <leader>j, type the character you're
-- looking at, then the label that shows up on it. Looks at every window in
-- the tab, so it jumps straight into another split too.
require('mini.jump2d').setup {
  -- mini's own mapping always runs its default mode (a label on every word,
  -- not the one character one) and always maps visual mode too, so it's off
  -- and <leader>j below does the job. Off also keeps it from taking Enter.
  mappings = { start_jumping = '' },
}
-- `o` is after an operator: `d<leader>j` + target deletes up to it
vim.keymap.set({ 'n', 'o' }, '<leader>j', function() MiniJump2d.start(MiniJump2d.builtin_opts.single_character) end, { desc = '[J]ump to a character on screen' })

-- Simple and easy statusline.
--  You could remove this setup call if you don't like it,
--  and try some other statusline plugin
local statusline = require 'mini.statusline'
-- Set `use_icons` to true if you have a Nerd Font
statusline.setup { use_icons = vim.g.have_nerd_font }

-- You can configure sections in the statusline by overriding their
-- default behavior. For example, here we set the section for
-- cursor location to LINE:COLUMN
---@diagnostic disable-next-line: duplicate-set-field
statusline.section_location = function() return '%2l:%-2v' end

-- Start screen. Takes over the empty startup buffer and wipes it once you
-- open something, so no [No Name] is left in the buffer list.
--
-- Type the first letters of an item to narrow it down, <CR> to run it.
-- That's why the item names are plain text, the icons live in the section
-- names and the bullet instead, where they don't get in the way of typing.
local starter = require 'mini.starter'
local icon = function(glyph) return vim.g.have_nerd_font and (glyph .. ' ') or '' end

local header = function()
  local hour = tonumber(os.date '%H')
  local greeting = hour < 12 and 'Good morning' or hour < 18 and 'Good afternoon' or 'Good evening'
  return table.concat({
    '███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗',
    '████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║',
    '██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║',
    '██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║',
    '██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║',
    '╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝',
    '',
    greeting .. ', welcome back.',
  }, '\n')
end

local footer = function()
  local v = vim.version()
  return table.concat({
    icon '\u{f073}' .. os.date '%A, %d %B %Y',
    icon '\u{f1e6}' .. #vim.pack.get() .. ' plugins',
    icon '\u{e62b}' .. string.format('v%d.%d.%d', v.major, v.minor, v.patch),
  }, '   ')
end

-- Telescope is required lazily, it loads after this file
local telescope = function(picker, opts)
  return function() require('telescope.builtin')[picker](opts) end
end

-- Recent files in the cwd, renamed from the default
-- "Recent files (current directory)" so it gets an icon like Actions
local recent_files = function()
  local items = starter.sections.recent_files(6, true, false)()
  for _, item in ipairs(items) do
    item.section = icon '\u{f1da}' .. 'Recent files'
  end
  return items
end

local actions = icon '\u{f0e7}' .. 'Actions'
starter.setup {
  header = header,
  footer = footer,
  items = {
    { section = actions, name = 'Find file', action = telescope 'find_files' },
    { section = actions, name = 'Grep text', action = telescope 'live_grep' },
    -- reveal = false, or neo-tree tries to find the start screen itself in
    -- the tree and asks to change cwd to `ministarter:/`
    { section = actions, name = 'Explorer', action = function() require('neo-tree.command').execute { reveal = false } end },
    { section = actions, name = 'New file', action = 'enew' },
    { section = actions, name = 'Config', action = telescope('find_files', { cwd = vim.fn.stdpath 'config', follow = true }) },
    { section = actions, name = 'Update plugins', action = function() vim.pack.update() end },
    { section = actions, name = 'Quit', action = 'qall' },
    recent_files,
  },
  content_hooks = {
    starter.gen_hook.adding_bullet(vim.g.have_nerd_font and '\u{f105} ' or '▎ '),
    starter.gen_hook.aligning('center', 'center'),
  },
  -- Letters typed on the start screen filter the items (type `gr` and only
  -- "Grep text" is left). That's mini's default, with every letter. j and k
  -- are taken out of that list so they can move up and down instead, mapped
  -- below. The only cost: an item starting with j or k can't be picked by
  -- typing its first letter, move onto it with j/k instead.
  query_updaters = 'abcdefghilmnopqrstuvwxyz0123456789_-.',
  -- No "(mini.starter) Query: ..." line at the bottom. It lingered after
  -- leaving the start screen until the next command cleared it. Errors
  -- still show.
  silent = true,
}

vim.api.nvim_create_autocmd('User', {
  desc = 'j/k to move between start screen items',
  group = vim.api.nvim_create_augroup('hanyue-starter-jk', { clear = true }),
  pattern = 'MiniStarterOpened',
  callback = function()
    local buf = vim.api.nvim_get_current_buf()
    vim.keymap.set('n', 'j', function() MiniStarter.update_current_item 'next' end, { buffer = buf, desc = 'Next item' })
    vim.keymap.set('n', 'k', function() MiniStarter.update_current_item 'prev' end, { buffer = buf, desc = 'Previous item' })
  end,
})

-- ... and there is more!
--  Check out: https://github.com/nvim-mini/mini.nvim
