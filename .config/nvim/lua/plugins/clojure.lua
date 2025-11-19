return {
  {
    'gpanders/nvim-parinfer',
    ft = { 'clojure' },
    config = function()
      vim.g.parinfer_mode = 'indent'
      vim.g.parinfer_enabled = 1
      vim.g.parinfer_force_balance = true
    end,
  },
  {
    'Olical/conjure',
    ft = { 'clojure' },
  },
}
