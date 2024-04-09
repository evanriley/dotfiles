return {
  {
    'Olical/conjure',
    ft = { 'clojure', 'fennel' },
    config = function(_, opts)
      require('conjure.main').main()
      require('conjure.mapping')['on-filetype']()
    end,
    init = function()
      -- vim.g['conjure#log#hud#width'] = 1
      -- vim.g['conjure#log#hud#enabled'] = false
      -- vim.g['conjure#log#hud#anchor'] = 'SE'
      -- vim.g['conjure#log#botright'] = true
      -- vim.g['conjure#extract#context_header_lines'] = 100
      -- vim.g['conjure#eval#comment_prefix'] = ';; '
      -- vim.g['conjure#client#clojure#nrepl#connection#auto_repl#enabled'] = false
      -- vim.g['conjure#client#clojure#nrepl#connection#auto_repl#hidden'] = true
      -- vim.g['conjure#client#clojure#nrepl#connection#auto_repl#cmd'] = nil
      -- vim.g['conjure#client#clojure#nrepl#eval#auto_require'] = false
      -- vim.g['conjure#client#clojure#nrepl#test#runner'] = 'kaocha'
    end,
  },
}
