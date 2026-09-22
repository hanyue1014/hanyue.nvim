local gh = require('config.pack').gh

-- ============================================================
-- LSP
-- LSP keymaps, server configuration, Mason tools installations
-- ============================================================

-- [[ LSP Configuration ]]
-- Brief aside: **What is LSP?**
--
-- LSP is an initialism you've probably heard, but might not understand what it is.
--
-- LSP stands for Language Server Protocol. It's a protocol that helps editors
-- and language tooling communicate in a standardized fashion.
--
-- In general, you have a "server" which is some tool built to understand a particular
-- language (such as `gopls`, `lua_ls`, `rust_analyzer`, etc.). These Language Servers
-- (sometimes called LSP servers, but that's kind of like ATM Machine) are standalone
-- processes that communicate with some "client" - in this case, Neovim!
--
-- LSP provides Neovim with features like:
--  - Go to definition
--  - Find references
--  - Autocompletion
--  - Symbol Search
--  - and more!
--
-- Thus, Language Servers are external tools that must be installed separately from
-- Neovim. This is where `mason` and related plugins come into play.
--
-- If you're wondering about lsp vs treesitter, you can check out the wonderfully
-- and elegantly composed help section, `:help lsp-vs-treesitter`

-- Useful status updates for LSP.
vim.pack.add { gh 'j-hui/fidget.nvim' }
require('fidget').setup {}

--  This function gets run when an LSP attaches to a particular buffer.
--    That is to say, every time a new file is opened that is associated with
--    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
--    function will be executed to configure the current buffer
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
  callback = function(event)
    -- NOTE: Remember that Lua is a real programming language, and as such it is possible
    -- to define small helper and utility functions so you don't have to repeat yourself.
    --
    -- In this case, we create a function that lets us more easily define mappings specific
    -- for LSP related items. It sets the mode, buffer and description for us each time.
    local map = function(keys, func, desc, mode)
      mode = mode or 'n'
      vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
    end

    -- Rename the variable under your cursor.
    --  Most Language Servers support renaming across files, etc.
    map('grn', vim.lsp.buf.rename, '[R]e[n]ame')

    -- Execute a code action, usually your cursor needs to be on top of an error
    -- or a suggestion from your LSP for this to activate.
    map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })

    -- Same two actions again under <leader>l, the same way `grf` and
    -- `<leader>lf` both format. `gr*` is the fast one, `<leader>l*` is the
    -- one which-key shows me when I've forgotten the letter.
    map('<leader>lr', vim.lsp.buf.rename, '[L]anguage: [R]ename')
    map('<leader>la', vim.lsp.buf.code_action, '[L]anguage: Code [A]ction', { 'n', 'x' })

    -- WARN: This is not Goto Definition, this is Goto Declaration.
    --  For example, in C this would take you to the header.
    map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

    -- The following two autocommands are used to highlight references of the
    -- word under your cursor when your cursor rests there for a little while.
    --    See `:help CursorHold` for information about when this is executed
    --
    -- When you move your cursor, the highlights will be cleared (the second autocommand).
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client and client:supports_method('textDocument/documentHighlight', event.buf) then
      local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
      vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.document_highlight,
      })

      vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.clear_references,
      })

      vim.api.nvim_create_autocmd('LspDetach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
        callback = function(event2)
          vim.lsp.buf.clear_references()
          vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
        end,
      })
    end

    -- The following code creates a keymap to toggle inlay hints in your
    -- code, if the language server you are using supports them
    --
    -- This may be unwanted, since they displace some of your code
    if client and client:supports_method('textDocument/inlayHint', event.buf) then
      map('<leader>th', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end, '[T]oggle Inlay [H]ints')
    end
  end,
})

-- Enable the following language servers
--  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
--  See `:help lsp-config` for information about keys and how to configure
--
-- Everything that ends up in this table gets two things for free at the bottom
-- of the file: mason installs it, and `vim.lsp.enable` turns it on. So adding a
-- language is a one line change.
--
-- These ones mason can install entirely on its own. It just downloads a
-- prebuilt binary, so they work on a bare machine with nothing set up.
--
-- Some languages (like rust) have entire language plugins that can be useful:
--    https://github.com/mrcjkb/rustaceanvim
--
-- But for many setups, the LSP (`rust_analyzer`) will work just fine
---@type table<string, vim.lsp.Config>
local servers = {
  clangd = {}, -- c, cpp
  ols = {}, -- odin
  rust_analyzer = {}, -- rust
  zls = {}, -- zig

  stylua = {}, -- Used to format Lua code

  -- Special Lua Config, as recommended by neovim help docs
  lua_ls = {
    on_init = function(client)
      client.server_capabilities.documentFormattingProvider = false -- Disable formatting (formatting is done by stylua)

      if client.workspace_folders then
        local path = client.workspace_folders[1].name
        if path ~= vim.fn.stdpath 'config' and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then return end
      end

      local current_settings = client.config.settings --[[@as lspconfig.settings.lua_ls]]
      client.config.settings.Lua = vim.tbl_deep_extend('force', current_settings.Lua, {
        runtime = {
          version = 'LuaJIT',
          path = { 'lua/?.lua', 'lua/?/init.lua' },
        },
        workspace = {
          checkThirdParty = false,
          -- NOTE: this is a lot slower and will cause issues when working on your own configuration.
          --  See https://github.com/neovim/nvim-lspconfig/issues/3189
          library = vim.api.nvim_get_runtime_file('', true),
        },
      })
    end,
    ---@type lspconfig.settings.lua_ls
    settings = {
      Lua = {
        format = { enable = false }, -- Disable formatting (formatting is done by stylua)
      },
    },
  },
}

-- [[ Servers that need something already on the system ]]
--
-- These can't just be downloaded. mason either builds them with the language's
-- own toolchain, or grabs them from that language's package registry, so if the
-- toolchain isn't there the install fails outright and mason-tool-installer
-- retries (and fails) on every single startup. jdtls is the odd one out: it
-- downloads fine, but won't actually start without a JDK.
--
-- I use this config on several machines that don't all have the same stuff
-- installed, so instead of commenting these in and out per machine, I only
-- register a server when its tool is actually on PATH. Install the toolchain,
-- restart nvim, and the server shows up on its own.
local needs_on_path = {
  gopls = 'go', -- mason runs `go install`
  pyright = 'npm', -- pulled from npm
  ruff = 'pip', -- pulled from pypi. NOTE: checking `pip` and not `python`
  -- on purpose, because Windows ships a fake python.exe that only opens the
  -- Microsoft Store, and that one would pass an executable check.
  jdtls = 'java', -- installs anywhere, needs a JDK 21+ to run
}

for server, tool in pairs(needs_on_path) do
  if vim.fn.executable(tool) == 1 then servers[server] = {} end
end

vim.pack.add {
  gh 'neovim/nvim-lspconfig',
  gh 'mason-org/mason.nvim',
  gh 'mason-org/mason-lspconfig.nvim',
  gh 'WhoIsSethDaniel/mason-tool-installer.nvim',
}

-- Automatically install LSPs and related tools to stdpath for Neovim
require('mason').setup {}

-- Translates between nvim-lspconfig server names and mason.nvim package names (e.g. lua_ls <-> lua-language-server)
require('mason-lspconfig').setup {
  automatic_enable = false, -- Change this to true if you want to automatically enable servers that are installed manually (e.g. via :Mason / :MasonInstall)
}

-- Ensure the servers and tools above are installed
--
-- To check the current status of installed tools and/or manually install
-- other tools, you can run
--    :Mason
--
-- You can press `g?` for help in this menu.
local ensure_installed = vim.tbl_keys(servers or {})
vim.list_extend(ensure_installed, {
  -- You can add other tools here that you want Mason to install
})

-- nvim-treesitter's `main` branch builds parsers with the tree-sitter CLI, and
-- without it there are no parsers at all, just vim's old regex highlighting.
-- The README says to install it yourself, which is fine on a machine where I
-- can, but I don't have sudo on all of them. mason installs into its own
-- folder under `stdpath('data')`, so it needs no admin rights and works on the
-- locked down boxes too.
--
-- Same PATH check as above, so on a machine where I already ran the README's
-- choco/apt line this does nothing and I don't end up with two copies.
--
-- NOTE: on a fresh machine mason fetches this in the background, so the
-- parsers only start building on the *second* nvim launch.
if vim.fn.executable 'tree-sitter' == 0 then table.insert(ensure_installed, 'tree-sitter-cli') end

require('mason-tool-installer').setup { ensure_installed = ensure_installed }

for name, server in pairs(servers) do
  vim.lsp.config(name, server)
  vim.lsp.enable(name)
end
