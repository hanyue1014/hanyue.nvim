-- ============================================================
-- NEOVIDE
-- GUI only settings, ignored by terminal nvim
--
-- Neovide sets `vim.g.neovide` before it loads this config, so the
-- guard below is what keeps all of this out of the terminal.
-- ============================================================

if not vim.g.neovide then return end

-- [[ Font ]]
-- Ligatures are on by default in neovide, so FiraCode's arrows, != and ==
-- just work with nothing set here. Turning them *off* would mean `-calt` in
-- neovide's TOML config file, since guifont has no font feature syntax,
-- only `#e-` antialiasing and `#h-` hinting.
--
-- The `h12` is the point size. Bump it to h13 if this ends up too small.
vim.o.guifont = 'FiraCode Nerd Font:h12'

-- [[ Cursor particles ]]
-- A single mode can be a plain string, but a list combines them, so this
-- gets railgun's particle trail plus ripple's ring.
--
-- The six modes split into two families, going by which option controls
-- their lifetime:
--   particle emitters   railgun, torpedo, pixiedust
--   highlight effects   sonicboom, ripple, wireframe
--
-- That split is worth knowing when tweaking: `particle_lifetime` tunes the
-- railgun half, `particle_highlight_lifetime` tunes the ripple half, and
-- `particle_phase` and `particle_curl` only do anything for railgun.
--
-- Empty string for no effect at all.
vim.g.neovide_cursor_vfx_mode = { 'railgun', 'ripple' }

-- ------------------------------------------------------------
-- Suggestions, left off until I decide I want them
-- ------------------------------------------------------------

-- Window transparency. This is the neovide equivalent of the terminal
-- opacity that catppuccin's `transparent_background` relies on. Without it
-- neovide just draws an opaque window and the transparent theme does nothing.
--
-- NOTE: this used to be called `neovide_transparency`. Older blog posts and
-- dotfiles still use that name, it's `neovide_opacity` now.
-- vim.g.neovide_opacity = 0.9

-- A little breathing room around the edges, in pixels.
vim.g.neovide_padding_top = 12
vim.g.neovide_padding_bottom = 0 -- no padding bottom since it's always occupied by the command line anyways
vim.g.neovide_padding_left = 8
vim.g.neovide_padding_right = 8

-- Get the mouse pointer out of the way while typing.
-- vim.g.neovide_hide_mouse_when_typing = true

-- Zoom without touching the font definition. Handy for screen sharing.
-- vim.g.neovide_scale_factor = 1.0
--
-- With keymaps, since that's the only way it's actually useful:
-- local function scale(delta)
--   return function() vim.g.neovide_scale_factor = vim.g.neovide_scale_factor * delta end
-- end
-- vim.keymap.set('n', '<C-=>', scale(1.1), { desc = 'Neovide zoom in' })
-- vim.keymap.set('n', '<C-->', scale(1 / 1.1), { desc = 'Neovide zoom out' })
-- vim.keymap.set('n', '<C-0>', function() vim.g.neovide_scale_factor = 1.0 end, { desc = 'Neovide zoom reset' })

-- Animation feel. Lower is snappier, 0 disables. Defaults are
-- 0.150 for the cursor, 1.0 trail, 0.3 for scrolling.
-- vim.g.neovide_cursor_animation_length = 0.05
-- vim.g.neovide_cursor_trail_size = 0.6
-- vim.g.neovide_scroll_animation_length = 0.2

-- Match the monitor instead of the default 60, if the display is faster.
-- vim.g.neovide_refresh_rate = 144

-- Start maximised or fullscreen.
-- vim.g.neovide_fullscreen = true

-- Window size is remembered between launches already, this is on by
-- default, listed here only so I don't go looking for it later.
-- vim.g.neovide_remember_window_size = true
