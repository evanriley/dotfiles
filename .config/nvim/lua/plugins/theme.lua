return {
  {
    'rebelot/kanagawa.nvim',
    priority = 1000, -- Make sure to load this before all the other start plugins.
    config = function()
      require('kanagawa').setup {
        undercurl = false,
        commentStyle = { italic = false },
        keywordStyle = { italic = false },
      }
    end,
    init = function()
      vim.cmd.colorscheme 'kanagawa'
    end,
  },
}
