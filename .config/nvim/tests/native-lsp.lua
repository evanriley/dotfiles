local function fail(err) print(err); vim.cmd('cquit 1') end
local function later(ms, f) vim.defer_fn(function() local ok,e=pcall(f); if not ok then fail(e) end end,ms) end
MiniSnippets.config.snippets = {}
vim.bo.filetype='text'
local id=vim.lsp.start({name='native-completion-test',cmd=function(dispatchers)
  local closing=false
  return {
    request=function(method,params,cb,reply)
      if method=='initialize' then cb(nil,{capabilities={completionProvider={}}})
      elseif method=='textDocument/completion' then cb(nil,{{label='foobar', insertText='foobar(${1:value})$0',insertTextFormat=2,
        additionalTextEdits={{range={start={line=0,character=0},['end']={line=0,character=0}},newText='import foobar\n'}}}})
      else cb(nil,nil) end
      if reply then reply(1) end
      return true,1
    end,
    notify=function(method) if method=='exit' then closing=true;dispatchers.on_exit(0,0) end return true end,
    is_closing=function() return closing end, terminate=function() closing=true end,
  }
end})
assert(id)
vim.api.nvim_buf_set_lines(0,0,-1,false,{'// header',''})
vim.api.nvim_win_set_cursor(0,{2,0})
later(300,function()
 vim.api.nvim_input('ifoo')
 later(700,function()
   assert(vim.fn.pumvisible()==1,'no LSP completion menu')
   vim.api.nvim_input('<Tab><CR>')
   later(300,function()
     local lines=vim.api.nvim_buf_get_lines(0,0,-1,false)
     assert(lines[1]=='import foobar' and lines[3]=='foobar(value)',vim.inspect(lines))
     assert(vim.snippet.active())
     print('PASS native completion acceptance applies import edits and expands LSP snippet')
     vim.cmd('qa!')
   end)
 end)
end)
