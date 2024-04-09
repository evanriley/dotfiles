return {
  {
    'gpanders/nvim-parinfer',
    ft = { 'clojure' },
    init = function()
      vim.g.parinfer_force_balance = true
      vim.g.parinfer_comment_chars = ';;'
    end,
  },
}
