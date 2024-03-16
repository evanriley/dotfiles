(local {: autoload} (require :nfnl.module))
(local nvim (autoload :nvim))

[{1 :zbirenbaum/copilot.lua
  :cmd "Copilot"
  :event "InsertEnter"
  :config (fn []
            (let [copilot (require :copilot)]
              (copilot.setup {:suggestion {:enabled false}
                              :panel {:enabled false}})))}]
