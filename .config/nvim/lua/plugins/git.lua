return {
  {
    'lewis6991/gitsigns.nvim',
    opts = {},
  },
  {
    'NeogitOrg/neogit',
    dependencies = {
      'nvim-lua/plenary.nvim', -- required
      'sindrets/diffview.nvim', -- optional - Diff integration
      'ibhagwan/fzf-lua',
    },
    keys = {
      {
        '<leader>gg',
        '<cmd>Neogit<CR>',
      },
    },
  },
}
