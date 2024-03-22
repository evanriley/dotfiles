(local {: autoload} (require :nfnl.module))
(local nvim (autoload :nvim))

[{1 :kdheepak/lazygit.nvim 
  :dependencies [:nvim-lua/plenary.nvim]
  :cmd "LazyGit"
  :config (fn []
            (let [lazy (require :lazy)]
              (lazy.setup {})))
  :init (fn []
          (nvim.set_keymap :n :<leader>gg "<cmd>LazyGit<cr>" {:noremap true :silent true}))}]
