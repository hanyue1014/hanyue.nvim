-- ============================================================
-- COMMANDS
-- My own :Commands, the ones vim doesn't already ship
--
-- ============================================================

-- [[ :CopyPath ]]
-- Put the current file's path on the clipboard.
--
--   :CopyPath        C:\dev\apps_proc\eagle\atfwd\atfwd.c
--   :CopyPath rel    apps_proc\eagle\atfwd\atfwd.c
--   :CopyPath name   atfwd.c
--   :CopyPath dir    C:\dev\apps_proc\eagle\atfwd
--
-- To only *see* the path there's no need for any of this, vim already has
-- `1<C-g>`. Plain `<C-g>` (or `:file`) prints the short name, and any
-- count in front of it prints the full path instead. This command exists
-- for the copying part.
--
-- NOTE: I have no idea how this is done, Claude did the heavy lifting
local forms = {
  full = ':p',
  rel = ':.',
  name = ':t',
  dir = ':p:h',
}

-- Separate list because the order of a table's keys is unspecified and
-- the completion menu should stay in a sensible order.
local form_names = { 'full', 'rel', 'name', 'dir' }

vim.api.nvim_create_user_command('CopyPath', function(opts)
  local form = opts.args ~= '' and opts.args or 'full'
  local modifier = forms[form]
  if not modifier then
    vim.notify(('CopyPath: no such form %q, expected one of %s'):format(form, table.concat(form_names, ', ')), vim.log.levels.ERROR)
    return
  end

  local path = vim.fn.expand('%' .. modifier)
  if path == '' then
    vim.notify('CopyPath: this buffer has no file behind it', vim.log.levels.WARN)
    return
  end

  -- The + register explicitly rather than the unnamed one, so this still
  -- reaches the system clipboard if I ever drop `clipboard=unnamedplus`.
  -- Over SSH this goes through the OSC 52 provider set up in options.lua.
  vim.fn.setreg('+', path)
  vim.notify(path)
end, {
  nargs = '?',
  complete = function(lead)
    return vim.tbl_filter(function(name) return name:find(lead, 1, true) == 1 end, form_names)
  end,
  desc = 'Copy the current file path to the clipboard',
})
