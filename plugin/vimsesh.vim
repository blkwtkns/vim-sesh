" =============================================================================
" Filename: plugin/vim-sesh.vim
" Author: blkwtkns
" =============================================================================

if exists('g:loaded_vimsesh') || &cp
  finish
end

" let s:save_cpo = &cpo
" set cpo&vim

if !exists('g:session_directory')
  if executable('nvim')
    let g:session_directory = expand($HOME.'/nvim.local/sessions')
  else

    if !isdirectory($HOME.'/.vim/sessions')
      call mkdir($HOME.'/.vim/sessions')
    end

    let g:session_directory = expand($HOME.'/.vim/sessions')
  end
end


if !exists('g:session_meta')
  let g:session_meta = g:session_directory.'/'.'.metaseshrc'
end


let g:session_options = ['']
let g:session_sourced = 0

" Make metasesh file
if !filereadable(g:session_meta)
  call system('touch ' . g:session_meta)
end

if filereadable(''. g:session_meta) && match(readfile(expand("".g:session_meta)),"text")
  let g:sesh_option_check = readfile(expand("".g:session_meta), 'b')
  if len(g:sesh_option_check) > 0 && g:sesh_option_check[0] != ''
    let g:session_options[0] = g:sesh_option_check[0]
    let g:session_sourced = 1
  end
end

" Add logic for session deletion
" Add logic for restore options to default

aug PluginSession
  au!
  au VimEnter * if expand('<afile>') == "" | call RestoreSession()
  au VimLeave * call SaveSession()
  au VimLeave * call DoRedir(g:session_options)
aug END


let g:loaded_vimsesh = 1

" let &cpo = s:save_cpo
" unlet s:save_cpo
