[{1 :nvim-treesitter/nvim-treesitter
  :dependencies [:windwp/nvim-ts-autotag
                 :nvim-treesitter/nvim-treesitter-textobjects
                 :JoosepAlviste/nvim-ts-context-commentstring
                 :nvim-treesitter/nvim-treesitter-context
                 :RRethy/nvim-treesitter-endwise
                 :hiphish/rainbow-delimiters.nvim]
  :build ":TSUpdate"
  :config (fn []
            (let [treesitter (require :nvim-treesitter.configs)]
              (treesitter.setup {:highlight {:enable true}
                                 :indent {:enable true}
                                 :ensure_installed :all
                                 :autotag {:enable true}
                                 :endwise {:enable true}}))
            (let [treesitter-context (require :treesitter-context)]
              (treesitter-context.setup {:enable true}))
            (let [ts-treesitter-context (require :ts_context_commentstring)]
              (ts-treesitter-context.setup {:enable_autocmd false})))}]
