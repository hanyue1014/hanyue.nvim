-- ============================================================
-- SOURCEKIT (Swift)
--
-- Three names for one thing:
--   sourcekit       nvim-lspconfig's name for the server, what `:LspInfo`
--                   and `vim.lsp.enable` use
--   sourcekit-lsp   the binary, ships with the Swift toolchain
--   Swift           the language. This file is the Swift LSP setup.
--
-- Lives here instead of the `servers` table in plugins/lsp.lua because
-- everything in that table goes to mason, and mason has no package for it.
-- Install Swift (swift.org/install), restart nvim, and it turns on by itself.
--
-- swift.org's Neovim guide writes the whole config by hand, because the guide
-- doesn't use nvim-lspconfig. nvim-lspconfig's `lsp/sourcekit.lua` already has
-- the same cmd and capabilities (didChangeWatchedFiles, diagnostic), so the
-- only change below is who gets the C files.
--
-- [[ C files ]]
-- sourcekit-lsp handles C, C++ and Objective-C too (it runs the toolchain's
-- own clangd underneath), with the build settings from the Swift project.
-- So C files are split by where they live:
--   inside a Swift project   sourcekit, it knows the module maps and targets
--                            that the Swift side imports the C code through
--   anywhere else            clangd, as always
-- Never both on one file. Without Swift installed this file stops at the
-- check below, and clangd keeps every C file like before.
-- ============================================================

if vim.fn.executable 'sourcekit-lsp' == 0 then return end

-- What makes it a Swift project: anything sourcekit-lsp gets C build settings
-- from. compile_commands.json and .git aren't in here, plain C projects have
-- those too.
local function in_swift_project(bufnr)
  return vim.fs.root(bufnr, function(name)
    return name == 'Package.swift' or name == 'buildServer.json' or name == '.bsp' or name:match '%.xcodeproj$' ~= nil or name:match '%.xcworkspace$' ~= nil
  end) ~= nil
end

local upstream_root_dir = vim.lsp.config.sourcekit.root_dir

-- Upstream's filetypes already include c, cpp, objc and objcpp, so only the
-- root needs changing: Swift files always start it, C files only inside a
-- Swift project. Not calling on_dir is how a root_dir says "not this buffer".
-- Both go through upstream's root, so a package's .swift and .c files share
-- one server.
vim.lsp.config('sourcekit', {
  root_dir = function(bufnr, on_dir)
    if vim.bo[bufnr].filetype ~= 'swift' and not in_swift_project(bufnr) then return end
    upstream_root_dir(bufnr, on_dir)
  end,
})

-- And clangd steps aside in exactly those files. Setting root_dir makes
-- Neovim ignore clangd's root_markers, so they're looked up here by hand to
-- find the same root as before.
local clangd_root_markers = vim.lsp.config.clangd.root_markers

vim.lsp.config('clangd', {
  root_dir = function(bufnr, on_dir)
    if in_swift_project(bufnr) then return end
    on_dir(vim.fs.root(bufnr, clangd_root_markers))
  end,
})

vim.lsp.enable 'sourcekit'
