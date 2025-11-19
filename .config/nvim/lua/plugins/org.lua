return {
  {
    'nvim-orgmode/orgmode',
    event = 'VeryLazy',
    ft = { 'org' },
    config = function()
      require('orgmode').setup {
        org_agenda_files = '~/Sync/brain/**/*',
        org_default_notes_file = '~/Sync/brain/refile.org',
      }
    end,
  },
  {
    'akinsho/org-bullets.nvim',
    dependencies = { 'nvim-orgmode/orgmode' },
    opts = {},
  },
  {
    'lukas-reineke/headlines.nvim',
    dependencies = 'nvim-treesitter/nvim-treesitter',
    config = true,
    ft = { 'org' },
  },
  {
    'chipsenkbeil/org-roam.nvim',
    tag = '0.1.1',
    dependencies = {
      {
        'nvim-orgmode/orgmode',
      },
    },
    config = function()
      require('org-roam').setup {
        directory = '~/Sync/brain/roam',
      }
    end,
  },
}
