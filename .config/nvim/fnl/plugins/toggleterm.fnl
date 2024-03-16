(local {: autoload} (require :nfnl.module))
(local nvim (autoload :nvim))

[{1 :akinsho/toggleterm.nvim
  :lazy false
  :config (fn []
            (let [toggleterm (require :toggleterm)]
              (toggleterm.setup {:open_mapping "<C-t>"
                                 :direction "float"
                                 :insert_mappings true
                                 :shade_terminals true
                                 :float_opts {
                                              :border "single"
                                              :width 250
                                              :height 40
                                              :winblend 0}
                                 :size (fn size [term]
                                         (if
                                           (= term.direction "horizontal")
                                           15
                                           (= term.direction "vertical")
                                           (* vim.o.columns 0.4)))})))}]
                                     
