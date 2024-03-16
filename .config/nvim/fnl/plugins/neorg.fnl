(local {: autoload} (require :nfnl.module))
(local nvim (autoload :nvim))

[{1 :nvim-neorg/neorg
  :build ":Neorg sync-parsers"
  :lazy false
  :dependencies [:nvim-lua/plenary.nvim]
  :config (fn []
            (let [neorg (require :neorg)]
              (neorg.setup {:load
                            {:core.dirman {:config {:workspaces {:notes "~/Documents/Notes"}}}}})))}]
                                                      
                                                      
