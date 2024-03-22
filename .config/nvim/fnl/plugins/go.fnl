(local {: autoload} (require :nfnl.module))
(local nvim (autoload :nvim))

[{1 :fatih/vim-go
  :lazy true
  :build ":GoInstallBinaries"
  :ft [:go]
  :init (fn []
          (set nvim.g.go_def_mapping_enabled 0))}]
