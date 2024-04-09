-- [[ Basic Autocommands ]]
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('evan-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  desc = 'Use `q` to close the float opened by Oil.nvim',
  pattern = 'oil',
  callback = function()
    vim.api.nvim_buf_set_keymap(0, 'n', 'q', '<cmd>close!<CR>', { silent = true, noremap = true })
  end,
})

vim.api.nvim_create_autocmd({ 'BufEnter' }, {
  callback = function(event)
    local title = 'vim'
    if event.file ~= '' then
      title = string.format('vim: %s', vim.fs.basename(event.file))
    end

    vim.fn.system { 'wezterm', 'cli', 'set-tab-title', title }
  end,
})

vim.api.nvim_create_autocmd({ 'VimLeave' }, {
  callback = function()
    -- Setting title to empty string causes wezterm to revert to its default behavior of setting the tab title automatically
    vim.fn.system { 'wezterm', 'cli', 'set-tab-title', '' }
  end,
})

-- Clojure/Conjure
vim.api.nvim_create_autocmd('BufNewFile', {
  desc = 'Conjure Log disable LSP diagnostics',
  pattern = { 'conjure-log-*' },
  callback = function()
    vim.diagnostic.disable(0)
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  desc = 'Lisp style line comment',
  pattern = { 'clojure' },
  callback = function()
    vim.bo.commentstring = ';; %s'
  end,
})
