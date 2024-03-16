
(local {: autoload} (require :nfnl.module))
(local nvim (autoload :nvim))

[{1 :pwntester/octo.nvim
  :dependencies [:nvim-lua/plenary.nvim
                 :nvim-telescope/telescope.nvim
                 :nvim-tree/nvim-web-devicons]
  :cmd "Octo"
  :config (fn []
            (let [octo (require :octo)]
              (octo.setup {})))}]
