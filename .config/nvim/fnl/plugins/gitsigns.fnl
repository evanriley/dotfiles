(local {: autoload} (require :nfnl.module))
(local nvim (autoload :nvim))

[{1 :lewis6991/gitsigns.nvim
  :event "BufReadPre"
  :config (fn []
            (let [gitsigns (require :gitsigns)]
              (gitsigns.setup {
                               :current_line_blame false
                               :attach_to_untracked false})))}]
                               
              
            
