function! text_obj#URL() abort
  if match(&runtimepath, 'vim-highlighturl') != -1
    " Note that we use https://github.com/itchyny/vim-highlighturl to get the URL pattern.
    let url_pattern = highlighturl#default_pattern()
  else
    let url_pattern = expand('<cfile>')
    " Since expand('<cfile>') also works for normal words, we need to check if
    " this is really URL using heuristics, e.g., URL length.
    if len(url_pattern) <= 10
      return
    endif
  endif

  " We need to find all possible URL on this line and their start, end index.
  " Then find where current cursor is, and decide if cursor is on one of the
  " URLs.
  let line_text = getline('.')
  let url_infos = []

  let [_url, _idx_start, _idx_end] = matchstrpos(line_text, url_pattern)
  while _url !=# ''
    let url_infos += [[_url, _idx_start+1, _idx_end]]
    let [_url, _idx_start, _idx_end] = matchstrpos(line_text, url_pattern, _idx_end)
  endwhile

  " echo url_infos
  " If no URL is found, do nothing.
  if len(url_infos) == 0
    return
  endif

  let [start_col, end_col] = [-1, -1]
  " If URL is found, find if cursor is on it.
  let [buf_num, cur_row, cur_col] = getcurpos()[0:2]
  for url_info in url_infos
    " echo url_info
    let [_url, _idx_start, _idx_end] = url_info
    if cur_col >= _idx_start && cur_col <= _idx_end
      let start_col = _idx_start
      let end_col = _idx_end
      break
    endif
  endfor

  " Cursor is not on a URL, do nothing.
  if start_col == -1
    return
  endif

  " Now set the '< and '> mark
  call setpos("'<", [buf_num, cur_row, start_col, 0])
  call setpos("'>", [buf_num, cur_row, end_col, 0])
  normal! gv
endfunction

function! text_obj#MdCodeBlock(type) abort
  " the parameter type specify whether it is inner text objects or around
  " text objects.

  " Move the cursor to the end of line in case that cursor is on the opening
  " of a code block. Actually, there are still issues if the cursor is on the
  " closing of a code block. In this case, the start row of code blocks would
  " be wrong. Unless we can match code blocks, it not easy to fix this.
  normal! $
  let start_row = searchpos('\s*```', 'bnW')[0]
  let end_row = searchpos('\s*```', 'nW')[0]

  let buf_num = bufnr()
  if a:type ==# 'i'
    let start_row += 1
    let end_row -= 1
  endif
  " echo a:type start_row end_row

  call setpos("'<", [buf_num, start_row, 1, 0])
  call setpos("'>", [buf_num, end_row, 1, 0])
  execute 'normal! `<V`>'
endfunction

function! text_obj#Buffer() abort
  let buf_num = bufnr()

  call setpos("'<", [buf_num, 1, 1, 0])
  call setpos("'>", [buf_num, line('$'), 1, 0])
  execute 'normal! `<V`>'
endfunction

" Select the content inside the nearest enclosing bracket pair ((), [], {}).
function! text_obj#AnyBracket() abort
  let pairs = [['(', ')'], ['\[', '\]'], ['{', '}']]
  let best = [0, 0, 0, 0] " open_ln, open_col, close_ln, close_col
  let best_len = 0

  " If the cursor is on an open/close bracket, nudge it so that the pair is found.
  let ch = getline('.')[col('.') - 1]
  if ch ==# '(' || ch ==# '[' || ch ==# '{'
    normal! l
  elseif ch ==# ')' || ch ==# ']' || ch ==# '}'
    normal! h
  endif

  for pair in pairs
    let open_pos = searchpairpos(pair[0], '', pair[1], 'bnW')
    if open_pos == [0, 0]
      continue
    endif
    let close_pos = searchpairpos(pair[0], '', pair[1], 'nW')
    if close_pos == [0, 0]
      continue
    endif
    let len = (close_pos[0] - open_pos[0]) * 10000 + (close_pos[1] - open_pos[1])
    if best_len == 0 || len < best_len
      let best_len = len
      let best = [open_pos[0], open_pos[1], close_pos[0], close_pos[1]]
    endif
  endfor

  if best_len == 0
    return
  endif

  let buf_num = bufnr()
  call setpos("'<", [buf_num, best[0], best[1] + 1, 0])
  call setpos("'>", [buf_num, best[2], best[3] - 1, 0])
  execute 'normal! `<v`>'
endfunction
