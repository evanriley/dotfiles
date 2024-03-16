(local {: autoload} (require :nfnl.module))
(local nvim (autoload :nvim))
(local core (autoload :nfnl.core))

;space is reserved to be leader
(nvim.set_keymap :n :<space> :<nop> {:noremap true})

;remove search highlights with Esc
(nvim.set_keymap :n :<Esc> :<cmd>nohlsearch<CR> {:noremap true})

;better window navigation
(nvim.set_keymap :n :<C-h> :<C-w>h {:noremap true})
(nvim.set_keymap :n :<C-j> :<C-w>j {:noremap true})
(nvim.set_keymap :n :<C-k> :<C-w>k {:noremap true})
(nvim.set_keymap :n :<C-l> :<C-w>l {:noremap true})


;sets a nvim global options
(let [options
      {;tabs is space
       :expandtab true
       ;tab/indent size
       :tabstop 2
       :shiftwidth 2
       :softtabstop 2
       ;settings needed for compe autocompletion
       :completeopt "menuone,noselect"
       ;case insensitive search
       :ignorecase true
       ;smart search case
       :smartcase true
       ;shared clipboard with the system
       :clipboard "unnamedplus"
       ;show line numbers
       :number true
       ;make them relative
       :relativenumber true
       ;show line and column number
       :ruler true
       ;makes signcolumn always one column with signs and linenumber
       :signcolumn "number"
       ;don't create backup files
       :backup false
       ;allow for more space in the neovim command line for displaying messages
       :cmdheight 1
       ;allow `` to be visible in markdown files
       :conceallevel 0
       ;pop up menu height
       :pumheight 10
       ;force all horizontal splits to go below the current window.
       :splitbelow true
       ;force all vertical splits to go to the right of the current window.
       :splitright true
       ;display long lines as-is
       :wrap false
       ; make sure the background is set to dark
       :background "dark"
       ; required settings for nvim-ufo
       :foldcolumn "auto:1"
       :foldlevel 99
       :foldlevelstart 99}]
       
  (each [option value (pairs options)]
    (core.assoc nvim.o option value)))

{}
