return {
  {
    'Olical/conjure',
    dependencies = {
      'clojure-vim/vim-jack-in',
      'tpope/vim-dispatch',
      'radenling/vim-dispatch-neovim',
    },
    ft = { 'clojure', 'fennel' },
    config = function(_, opts)
      require('conjure.main').main()
      require('conjure.mapping')['on-filetype']()
    end,
    init = function()
      vim.g['conjure#extract#context_header_lines'] = 100
      vim.g['conjure#eval#comment_prefix'] = ';; '
      -- Defer the setting of conjure#client#clojure#nrepl#connection#auto_repl#cmd
      vim.api.nvim_create_autocmd('FileType', {
        desc = 'Wait until a clojure file is opened to set this.', -- Look, I don't know what I'm doing but I do know that this works...
        pattern = { 'clojure' },
        callback = function()
          vim.g['conjure#client#clojure#nrepl#connection#auto_repl#cmd'] = vim.fn['jack_in#clj_cmd']()
        end,
      })
      vim.g['conjure#client#clojure#nrepl#connection#auto_repl#enabled'] = true
      vim.g['conjure#client#clojure#nrepl#eval#auto_require'] = true
    end,
  },
}
