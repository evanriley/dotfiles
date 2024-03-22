(local {: autoload} (require :nfnl.module))
(local nvim (autoload :nvim))

[{1 :phaazon/hop.nvim
  :lazy true
  :event "BufReadPost"
  :enabled false
  :config (fn []
            (let [hop (require :hop)]
              (hop.setup {:teasing false})))
  :init (fn []
          (nvim.set_keymap :n :s "<cmd>lua require'hop'.hint_char1()<cr>" {:noremap true})
          (nvim.set_keymap :x :s "<cmd>lua require'hop'.hint_char1()<cr>" {:noremap true})
          (nvim.set_keymap :o :x "<cmd>lua require'hop'.hint_char1()<cr>" {:noremap true})
          (nvim.set_keymap :n :S "<cmd>lua require'hop'.hint_lines()<cr>" {:noremap true})
          (nvim.set_keymap :o :X "<cmd>lua require'hop'.hint_lines()<cr>" {:noremap true})
          (nvim.set_keymap :x :SS "<cmd>lua require'hop'.hint_lines()<cr>" {:noremap true})
          (nvim.set_keymap :n :<C-s> "<cmd>lua require'hop'.hint_char2()<cr>" {:noremap true})
          (nvim.set_keymap :x :<C-s> "<cmd>lua require'hop'.hint_char2()<cr>" {:noremap true})
          (nvim.set_keymap :o :<C-x> "<cmd>lua require'hop'.hint_char2()<cr>" {:noremap true}))}]
