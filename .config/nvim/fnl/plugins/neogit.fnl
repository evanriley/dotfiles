(local {: autoload} (require :nfnl.module))
(local nvim (autoload :nvim))

[{1 :NeogitOrg/neogit
  :dependencies [:nvim-lua/plenary.nvim
                 :nvim-telescope/telescope.nvim
                 :sindrets/diffview.nvim
                 :ibhagwan/fzf-lua]
  :cmd "Neogit"
  :config true}]
