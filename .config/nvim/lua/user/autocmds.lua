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
