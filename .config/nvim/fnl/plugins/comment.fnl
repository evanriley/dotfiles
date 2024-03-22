(local {: autoload} (require :nfnl.module))
(local nvim (autoload :nvim))

[{1 :numToStr/Comment.nvim
  :event "BufReadPost"
  :config (fn []
            (let [comment-nvim (require :Comment)]
              (comment-nvim.setup
                {:padding true
                 :sticky true
                 :toggler {:line "gcc"
                           :block "gbc"}
                 :opleader {:line "gc"
                            :block "gb"}
                 :mappings {:basic true
                            :extra true
                            :extended false}})))}]
