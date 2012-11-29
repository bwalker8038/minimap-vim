" vim:set ts=8 sts=2 sw=2 tw=0 et nowrap:
"
" minimap.vim - Autoload of minimap plugin for Vim.
"
" License: THE VIM LICENSE
"
" Copyright:
"   - (C) 2012 MURAOKA Taro (koron.kaoriya@gmail.com)

scriptencoding utf-8

let s:minimap_id = 'minimap'

function! minimap#_is_open(id)
  let servers = split(serverlist(), '\n', 0)
  return len(filter(servers, 'v:val ==? a:id')) > 0 ? 1 : 0
endfunction

function! minimap#_open(id)
  let args = [
        \ 'gvim',
        \ '--servername', a:id,
        \ ]
  silent execute '!start '.join(args, ' ')
endfunction

function! minimap#_wait(id)
  " FIXME: improve wait logic
  while minimap#_is_open(a:id) != 0
    sleep 100m
  endwhile
  sleep 500m
endfunction

function! minimap#_send(id)
  let data = { 
        \ 'path': substitute(expand('%:p'), '\\', '/', 'g'),
        \ 'line': line('.'),
        \ 'col': col('.'),
        \ 'start': line('w0'),
        \ 'end': line('w$'),
        \ }
  call remote_expr(a:id, 'minimap#_on_recv("' . string(data) . '")')
endfunction

function! minimap#_on_open()
  set guioptions= laststatus=0 cmdheight=1 nowrap
  set columns=80 foldcolumn=2
  set cursorline
  set guifont=MS_Gothic:h3:cSHIFTJIS
  hi clear CursorLine
  hi link CursorLine Cursor
  winpos 0 0
  set lines=999
endfunction

function! minimap#_on_recv(data)
  let data = eval(a:data)
  let path = data['path']
  let file = substitute(expand('%:p'), '\\', '/', 'g')
  if file !=# path
    execute 'view! ' . path
  endif
  if file ==# path
    let col = data['col']
    let start = data['start']
    let curr = data['line']
    let end = data['end']
    " TODO: ensure to show view range.
    call cursor(start, col)
    call cursor(end, col)
    " mark view range.
    let p1 = printf('\%%>%dl\%%<%dl', start - 1, curr)
    let p2 = printf('\%%>%dl\%%<%dl', curr, end + 1)
    let p2 = '\%>' . curr . 'l\%<' . end . 'l'
    execute printf('match Search /\(%s\|%s\).*/', p1, p2)
    " move cursor
    call cursor(curr, col)
    redraw!
  endif
endfunction

function! minimap#_set_autosync()
  augroup minimap_auto
    autocmd!
    autocmd CursorMoved * call minimap#_sync()
  augroup END
endfunction

function! minimap#_sync()
  if len(expand('%:p')) == 0
    return
  endif
  let id = s:minimap_id
  if minimap#_is_open(id) == 0
    call minimap#_open(id)
    call minimap#_wait(id)
    call minimap#_set_autosync()
    call foreground()
  endif
  call minimap#_send(id)
endfunction

function! minimap#sync()
  if len(expand('%:p')) == 0
    echohl Error
    echo 'Open a valid file then retry :MinimapSync'
    echohl None
    return
  endif
  call minimap#_sync()
endfunction
