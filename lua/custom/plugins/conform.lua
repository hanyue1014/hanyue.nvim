local gh = require('config.pack').gh

-- ============================================================
-- CONFORM
-- Formatting, plus the <leader>f keymap
-- ============================================================

-- [[ Formatting ]]
vim.pack.add { gh 'stevearc/conform.nvim' }
require('conform').setup {
  notify_on_error = false,
  format_on_save = function(bufnr)
    -- You can specify filetypes to autoformat on save here:
    local enabled_filetypes = {
      -- lua = true,
      -- python = true,
    }
    if enabled_filetypes[vim.bo[bufnr].filetype] then
      return { timeout_ms = 500 }
    else
      return nil
    end
  end,
  default_format_opts = {
    lsp_format = 'fallback', -- Use external formatters if configured below, otherwise use LSP formatting. Set to `false` to disable LSP formatting entirely.
  },
  -- You can also specify external formatters in here.
  formatters_by_ft = {
    -- rust = { 'rustfmt' },
    -- Conform can also run multiple formatters sequentially
    -- python = { "isort", "black" },
    --
    -- You can use 'stop_after_first' to run the first available formatter from the list
    -- javascript = { "prettierd", "prettier", stop_after_first = true },
  },
}

-- Two ways into the same action on purpose.
--
-- `grf` sits with the rest of the LSP actions, next to Neovim's own `grn`,
-- `gra` and friends, which is where my hand already is after a code action.
-- `<leader>lf` is the discoverable one, it shows up when I hit <leader> and
-- wait for which-key.
--
-- NOTE: `<leader>f` used to be this. It is the [F]ind prefix now, and
-- formatting moved here so the two don't fight.
local function format() require('conform').format { async = true } end

vim.keymap.set({ 'n', 'v' }, 'grf', format, { desc = 'LSP: Format buffer' })
vim.keymap.set({ 'n', 'v' }, '<leader>lf', format, { desc = '[L]anguage: [F]ormat buffer' })
