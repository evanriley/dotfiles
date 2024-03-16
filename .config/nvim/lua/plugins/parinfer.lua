-- [nfnl] Compiled from fnl/plugins/parinfer.fnl by https://github.com/Olical/nfnl, do not edit.
local _local_1_ = require("nfnl.module")
local autoload = _local_1_["autoload"]
local nvim = autoload("nvim")
return {{"eraserhd/parinfer-rust", lazy = true, build = "cargo build --release", ft = {"clojure", "scheme", "lisp", "timl", "fennel", "janet"}}}
