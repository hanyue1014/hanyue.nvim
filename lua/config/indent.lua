-- ============================================================
-- INDENTATION
-- Global tab width defaults plus the per-language overrides
--
-- Split out of options.lua because it is the one thing I actually
-- keep coming back to edit.
-- ============================================================

-- language based custom tab widths, compliments guess-indent in case of an empty new file ig
-- Global default: 4 spaces
vim.o.expandtab = true
vim.o.tabstop = 4
vim.o.softtabstop = 4
vim.o.shiftwidth = 4

local two_space = {
  'lua', 'yaml', 'json', 'jsonc', 'toml', 'html', 'css', 'scss',
  'javascript', 'typescript', 'markdown', 'sh', 'bash', 'zsh', 'xml',
}

local four_space = {
  'python', 'c', 'cpp', 'rust', 'java', 'bitbake', 'cmake', 'meson',
}

local hard_tab = {
  make = 8,      -- required by make, not a style choice
  go = 4,        -- gofmt mandates tabs
  dts = 8,       -- devicetree, kernel style
  kconfig = 8,
  gitconfig = 4,
}

-- These are buffer local (`vim.bo`) on purpose, so opening a lua file in one
-- split doesn't change the tab width of the python file in the other split.
local function set_indent(width, expand)
  vim.bo.expandtab = expand
  vim.bo.tabstop = width
  vim.bo.softtabstop = expand and width or 0
  vim.bo.shiftwidth = width
end

vim.api.nvim_create_autocmd('FileType', {
  pattern = two_space,
  callback = function() set_indent(2, true) end,
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = four_space,
  callback = function() set_indent(4, true) end,
})

for ft, width in pairs(hard_tab) do
  vim.api.nvim_create_autocmd('FileType', {
    pattern = ft,
    callback = function() set_indent(width, false) end,
  })
end
