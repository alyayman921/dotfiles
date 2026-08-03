function! buf_utils#GoToBuffer(count, direction) abort
  if a:count == 0
    if a:direction ==# 'forward'
      bnext
    elseif a:direction ==# 'backward'
      bprevious
    else
      echoerr 'Bad argument ' a:direction
    endif
    return
  endif
  " Check the validity of buffer number.
  if index(s:GetBufNums(), a:count) == -1
    " Using `lua vim.notify('invalid bufnr: ' .. a:count)` won't work, because
    " we are essentially mixing Lua and vim script. We need to make sure that
    " args inside vim.notify() are valid vim values. The conversion from vim
    " value to lua value will be done by Nvim. See also https://github.com/neovim/neovim/pull/11338.
    call v:lua.vim.notify('Invalid bufnr: ' . a:count, 4, {'title': 'nvim-config'})
    return
  endif

  " Do not use {count} for gB (it is less useful)
  if a:direction ==# 'forward'
    silent execute('buffer' . a:count)
  endif
endfunction

" Go to the {count}-th listed buffer (by buffer list order, not bufnr).
function! buf_utils#GoToNthBuffer(count) abort
  let l:nums = s:GetBufNums()
  if a:count < 1 || a:count > len(l:nums)
    call v:lua.vim.notify('Invalid buffer index: ' . a:count, 4, {'title': 'nvim-config'})
    return
  endif
  silent execute('buffer ' . l:nums[a:count - 1])
endfunction

function! s:GetBufNums() abort
  return map(copy(getbufinfo({'buflisted':1})), 'v:val.bufnr')
endfunction
