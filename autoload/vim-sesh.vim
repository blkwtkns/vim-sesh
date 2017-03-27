" =============================================================================
" Filename: plugin/vim-sesh.vim
" Author: blkwtkns
" =============================================================================

if exists('g:loaded_vimsesh') || v:version < 700
  finish
endif
let g:loaded_vimsesh = 1

" let s:save_cpo = &cpo
" set cpo&vim
"

" Restore and save sessions.
" if argc() == 0
  " autocmd VimEnter * call RestoreSession()
"   autocmd VimLeave * call SaveSession()
" end

"
" let &cpo = s:save_cpo
" unlet s:save_cpo
