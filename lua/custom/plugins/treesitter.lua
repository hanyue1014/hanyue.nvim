local gh = require('config.pack').gh

-- ============================================================
-- TREESITTER
-- Parser installation, syntax highlighting, folds, indentation
-- ============================================================

-- [[ Configure Treesitter ]]
--  Used to highlight, edit, and navigate code
--
--  See `:help nvim-treesitter-intro`

-- NOTE: You can also specify a branch or a specific commit
vim.pack.add { { src = gh 'nvim-treesitter/nvim-treesitter', version = 'main' } }

-- Ensure basic parsers are installed
--
-- NOTE: the `main` branch builds these with the tree-sitter CLI. If it's
-- missing you get no parsers at all and highlighting quietly falls back to
-- vim's old regex syntax, so if a file looks unusually plain run
-- `:checkhealth nvim-treesitter` first. lsp.lua has mason install the CLI
-- when it isn't already on PATH.
local parsers = { 'bash', 'c', 'cpp', 'odin', 'zig', 'java', 'python', 'make', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc' }

-- [[ Making the parser build find a compiler on Windows ]]
--
-- The tree-sitter CLI compiles parsers through Rust's `cc` crate, and the
-- Windows build of the CLI targets MSVC, so it shells out to `cl.exe`. The
-- README's choco line installs mingw (gcc) and no MSVC at all, so every
-- parser dies with:
--
--   Failed to execute the C compiler with the following command:
--   "cl.exe" "-nologo" "-MD" ...
--   Error: program not found
--
-- `cc` honours the CC environment variable, and it picks GNU style flags
-- whenever the compiler isn't named like cl.exe, so pointing CC at gcc is
-- all it takes. Verified: same parser fails bare, builds fine with CC=gcc.
--
-- Guarded three ways so this only fires where it's actually the fix. It
-- leaves alone any machine with real MSVC build tools, anything that isn't
-- Windows, and any CC I've deliberately set myself.
if vim.fn.has 'win32' == 1 and (vim.env.CC or '') == '' and vim.fn.executable 'cl' == 0 and vim.fn.executable 'gcc' == 1 then
  vim.env.CC = 'gcc'
end

local function install_parsers() require('nvim-treesitter').install(parsers) end

-- On a brand new machine mason is still downloading the tree-sitter CLI in
-- the background while this file runs, so calling install() straight away
-- throws a red ENOENT about 'tree-sitter'. It sorts itself out on the next
-- launch, but it's an alarming first impression for no reason, so wait until
-- the CLI actually exists.
--
-- The check runs on VimEnter rather than right here, because mason is what
-- puts its own bin folder on PATH, and the load order of this folder is
-- unspecified, so lsp.lua may not have run yet at this point.
vim.api.nvim_create_autocmd('VimEnter', {
  once = true,
  callback = function()
    if vim.fn.executable 'tree-sitter' == 1 then
      install_parsers()
      return
    end

    -- mason-tool-installer fires this once its whole queue is done, which is
    -- the point where tree-sitter-cli is really on disk.
    vim.api.nvim_create_autocmd('User', {
      pattern = 'MasonToolsUpdateCompleted',
      once = true,
      callback = function() vim.schedule(install_parsers) end,
    })
  end,
})

---@param buf integer
---@param language string
local function treesitter_try_attach(buf, language)
  -- Check if a parser exists and load it
  if not vim.treesitter.language.add(language) then return end

  -- Check if the buffer is valid (might not be after install completes)
  if not vim.api.nvim_buf_is_valid(buf) then return end

  -- Enable syntax highlighting and other treesitter features
  vim.treesitter.start(buf, language)

  -- NOTE: treesitter folds are not set up here. Kickstart sets `vim.wo` in
  -- this callback, but fold options are window local and this runs on
  -- FileType, where the current window isn't reliably the one showing `buf`.
  -- They're set globally in `lua/config/options.lua` instead, which every
  -- window then inherits. `vim.treesitter.foldexpr()` handles the no parser
  -- case on its own, so nothing needs to happen per buffer.

  -- Check if treesitter indentation is available for this language, and if so enable it
  -- in case there is no indent query, the indentexpr will fallback to the vim's built in one
  local has_indent_query = vim.treesitter.query.get(language, 'indents') ~= nil

  -- Enable treesitter based indentation
  if has_indent_query then vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()" end
end

local available_parsers = require('nvim-treesitter').get_available()
vim.api.nvim_create_autocmd('FileType', {
  callback = function(args)
    local buf, filetype = args.buf, args.match

    local language = vim.treesitter.language.get_lang(filetype)
    if not language then return end

    local installed_parsers = require('nvim-treesitter').get_installed 'parsers'

    if vim.tbl_contains(installed_parsers, language) then
      -- Enable the parser if it is already installed
      treesitter_try_attach(buf, language)
    elseif vim.tbl_contains(available_parsers, language) then
      -- If a parser is available in `nvim-treesitter`, auto-install it and enable it after the installation is done
      require('nvim-treesitter').install(language):await(function() treesitter_try_attach(buf, language) end)
    else
      -- Try to enable treesitter features in case the parser exists but is not available from `nvim-treesitter`
      treesitter_try_attach(buf, language)
    end
  end,
})
