local gh = require('config.pack').gh

-- ============================================================
-- NEO-TREE
-- File explorer, [F]ile [E]xplorer on <leader>fe
-- ============================================================

-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim
--
-- Adapted from `lua/kickstart/plugins/neo-tree.lua`, which is already
-- written for vim.pack. The changes here are the <leader>fe binding so it
-- joins the rest of the [F]ind prefix, opening on the right, showing
-- everything by default, and the no nerd font fallback below.
--
-- plenary is already pulled in by telescope, but listing it again is
-- harmless and keeps this file standalone if telescope ever goes away.
vim.pack.add {
  { src = gh 'nvim-neo-tree/neo-tree.nvim', version = vim.version.range '*' },
  gh 'nvim-lua/plenary.nvim',
  gh 'MunifTanjim/nui.nvim',
}

-- `Neotree toggle` closes it again from anywhere, including from inside the
-- tree itself, so one key does both jobs and no extra window mapping needed.
vim.keymap.set('n', '<leader>fe', '<Cmd>Neotree toggle<CR>', { desc = '[F]ile [E]xplorer', silent = true })

-- Neo-tree's own defaults are already Nerd Font glyphs, and its file icon
-- provider calls `require('nvim-web-devicons')` at render time, which
-- mini.lua mocks onto mini.icons. So with a Nerd Font I want neo-tree's
-- defaults untouched: folder glyphs from neo-tree, per filetype file icons
-- from mini.icons. That's what the empty table below means.
--
-- Without a Nerd Font all of that renders as tofu boxes, so fall back to
-- plain ASCII instead. Flip `vim.g.have_nerd_font` in `config/options.lua`
-- and this table stops applying.
local ascii_icons = {
  icon = {
    folder_closed = '+',
    folder_open = '-',
    folder_empty = 'o',
    -- A space means "no icon". Putting a glyph in `default` would land tofu
    -- on every single file row.
    default = ' ',
  },
  git_status = {
    symbols = {
      added = 'A',
      modified = 'M',
      deleted = 'D',
      renamed = 'R',
      untracked = '?',
      ignored = 'I',
      unstaged = 'U',
      staged = 'S',
      conflict = 'C',
    },
  },
}

-- [[ Keys worth remembering inside the tree ]]
-- These are neo-tree's own defaults, not set here, listed so I stop looking
-- them up. `?` inside the tree shows the full list.
--
--   H       toggle hidden, this is the one that hides dotfiles and
--           gitignored files again after the config below shows them
--   .       set the current directory as the tree root
--   <bs>    go up a directory
--   /       fuzzy find within the tree
--   a d r c m   add, delete, rename, copy, move
--   [g ]g   jump to previous / next git modified file
--   i       show file details
--   o       order by, then c/d/g/m/n/s/t for created, diagnostics, git,
--           modified, name, size, type
require('neo-tree').setup {
  -- Empty table = keep neo-tree's Nerd Font defaults, see the note above.
  default_component_configs = vim.g.have_nerd_font and {} or ascii_icons,
  window = {
    -- On the right, so the tree doesn't shove my code sideways every time
    -- it opens and closes.
    position = 'right',
  },
  filesystem = {
    -- Finds and focuses the current file in the tree whenever I switch
    -- buffers. It only moves the cursor, the rest of the tree stays exactly
    -- as it was, and the root is untouched (that's `bind_to_cwd` and the
    -- `.` key, not this).
    --
    -- `leave_dirs_open = false` is neo-tree's default and means directories
    -- that got auto expanded to reveal a file collapse again afterwards.
    -- Set it true if the tree feels like it keeps forgetting where I was.
    follow_current_file = { enabled = true },
    -- Show everything by default, dotfiles and gitignored included. This is
    -- a config repo, plenty of what I care about is hidden by one rule or
    -- the other. Press H inside the tree to hide them again.
    filtered_items = {
      visible = true,
      hide_dotfiles = false,
      hide_gitignored = false,
    },
  },
  -- Close the tree the moment a file is opened from it, which is what makes
  -- the window picker question go away: <CR> opens the file, the tree gets out
  -- of the way, and the cursor is already where I want it. No target window to
  -- pick, no <leader>wl afterwards. <leader>fe brings the tree back.
  --
  -- There's no boolean for this. `close_if_last_window` is a different thing
  -- (it stops the tree being left alone in a tab). The event handler is how
  -- neo-tree itself documents it, commented out in its own defaults.lua under
  -- the label "auto close".
  --
  -- `file_opened` is fired by neo-tree's open commands rather than a key, so
  -- this covers <CR>, o, S, s and t alike.
  event_handlers = {
    {
      event = 'file_opened',
      handler = function() require('neo-tree.command').execute { action = 'close' } end,
    },
  },
}
