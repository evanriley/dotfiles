(local {: autoload} (require :nfnl.module))
(local nvim (autoload :nvim))

[{1 :eraserhd/parinfer-rust
  :lazy true
  :build "cargo build --release"
  :ft [:clojure :scheme :lisp :timl :fennel :janet]}]
