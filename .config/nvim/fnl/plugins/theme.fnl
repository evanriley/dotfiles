(local {: autoload} (require :nfnl.module))
(local nvim (autoload :nvim))

; Kanagawa Theme Settings
; [{1 :rebelot/kanagawa.nvim
;   :lazy false
;   :priority 1000
;   :name "kanagawa"
;   :config (fn []
;             (let [theme (require :kanagawa)]
;               (theme.setup {:undercurl false
;                             :theme "wave"
;                             :background {:dark "wave"
;                                          :light "lotus"}})
;               (vim.cmd "colorscheme kanagawa")))}]


; Gruvbox-baby Theme Settings
[{1 :ellisonleao/gruvbox.nvim
  :lazy false
  :priority 1000
  :name "gruvbox"
  :config (fn []
            (let [theme (require :gruvbox)]
              (theme.setup {
                            :terminal_colors true
                            :undrcurl false
                            :underline false
                            :transparent_mode true})
              (vim.cmd "colorscheme gruvbox")))}]
