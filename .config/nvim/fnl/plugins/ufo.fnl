(local {: autoload} (require :nfnl.module))
(local nvim (autoload :nvim))

[{1 :kevinhwang91/nvim-ufo
  :dependencies [:kevinhwang91/promise-async]
  :event ["BufReadPost" "BufNewFile"]
  :config (fn []
            (let [ufo (require :ufo)]
              (ufo.setup {
                          :provider_selector (fn [bufnr filetype buftype]
                                               [ "treesitter" "indent"])})))
  :init (fn []
          (nvim.set_keymap :n :zR "<cmd>lua require'ufo'.openAllFolds()<CR>" {:noremap true})
          (nvim.set_keymap :x :zM "<cmd>lua require'ufo'.closeAllFolds()<CR>" {:noremap true}))}]
