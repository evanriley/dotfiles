return {
  {
    'webhooked/kanso.nvim',
    priority = 1000, -- Make sure to load this before all the other start plugins.
    lazy = false,
    config = function()
      require('kanso').setup {
        disableItalics = true,
        background = {
          dark = "zen",
          light = "pearl"
        }
      }
    end,
    init = function()
      vim.cmd 'colorscheme kanso'
    end,
  },
}
