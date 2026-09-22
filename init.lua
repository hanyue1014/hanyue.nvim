--[[

=====================================================================
=====================================================================
========                                    .-----.          ========
========         .----------------------.   | === |          ========
========         |.-""""""""""""""""""-.|   |-----|          ========
========         ||                    ||   | === |          ========
========         ||    HANYUE.NVIM     ||   |-----|          ========
========         ||  (KICKSTART.NVIM)  ||   | === |          ========
========         ||                    ||   |-----|          ========
========         ||:Tutor              ||   |:::::|          ========
========         |'-..................-'|   |____o|          ========
========         `"")----------------(""`   ___________      ========
========        /::::::::::|  |::::::::::\  \ no mouse \     ========
========       /:::========|  |==hjkl==:::\  \ required \    ========
========      '""""""""""""'  '""""""""""""'  '""""""""""'   ========
========                                                     ========
=====================================================================
=====================================================================

--]]

-- ============================================================
-- This used to be one very long file. It still reads top to
-- bottom in the same order, the actual code just moved out into:
--
--   lua/config/          plain neovim stuff, no plugins involved
--   lua/custom/plugins/  one file per plugin
--   lua/custom/init.lua  the loader that pulls that folder in
--
-- Each plugin file is self contained: it calls `vim.pack.add` for
-- whatever it needs, then that plugin's `setup()`. So to rip a
-- plugin out, just delete its file.
--
-- <leader>sn to fuzzy find your way around these files.
-- ============================================================

-- [[ Core ]]
-- Order matters for these three, so don't shuffle them:
--  1. options sets the leader key, which has to happen before any
--     plugin loads or the plugin picks up the wrong leader
--  2. indent is just the rest of options, split out because it is
--     the bit I keep coming back to edit
--  3. pack registers the build hooks that run when a plugin is
--     installed or updated, so it has to come before anything
--     calls `vim.pack.add`
require 'config.options'
require 'config.indent'
require 'config.pack'

-- These two only touch built-in neovim, no plugins involved, so
-- they can sit anywhere after the leader key is set.
require 'config.keymaps'
require 'config.autocmds'

-- GUI only. Returns immediately when nvim is running in a terminal,
-- so it costs nothing there.
require 'config.neovide'

-- [[ Plugins ]]
-- Loads every file in `lua/custom/plugins/`.
require 'custom'

-- ============================================================
-- OPTIONAL EXAMPLES / NEXT STEPS
-- kickstart.plugins.* examples
-- ============================================================

-- The following comments only work if you have downloaded the kickstart repo, not just copy pasted the
-- init.lua. If you want these files, they are in the repository, so you can just download them and
-- place them in the correct locations.

-- NOTE: Next step on your Neovim journey: Add/Configure additional plugins for Kickstart
--
--  Here are some example plugins that I've included in the Kickstart repository.
--  Uncomment any of the lines below to enable them (you will need to restart nvim).
--
-- require 'kickstart.plugins.debug'
-- require 'kickstart.plugins.indent_line'
-- require 'kickstart.plugins.lint'
-- require 'kickstart.plugins.autopairs'
-- require 'kickstart.plugins.neo-tree'

-- NOTE: You can add your own plugins, configuration, etc. in `lua/custom/plugins/*.lua`.
--
-- `custom` automatically loads files from that directory, but their order is
-- unspecified. If plugins depend on each other, keep them in the same file and
-- put their `vim.pack.add()` and `setup()` calls in the required order.

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
