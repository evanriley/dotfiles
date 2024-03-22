(local {: autoload} (require :nfnl.module))
(local nvim (autoload :nvim))

[{1 :kylechui/nvim-surround
  :version "*"
  :event "VeryLazy"
  :config (fn []
            (let [nvim-surround (require :nvim-surround)]
              (nvim-surround.setup {})))}]
