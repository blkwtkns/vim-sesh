" =============================================================================
" vim-sesh - Simple project/workspace management
" Maintainer:	blkwtkns <iamssoblake@gmail.com>
" Version:	0.1.0
" Location:	plugin/vimsesh.vim
" Website:	https://github.com/blkwtkns/vim-sesh =============================================================================
if exists("g:loaded_vimsesh") || &cp
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

" TODO: allow optionality for sessions to be kept in actual project
fun! vimsesh#FindSession(...)
  let l:name = getcwd()
  " Check if located within a repo
  if !isdirectory(".git")
    let l:name = substitute(finddir(".git", ".;"), "/.git", "", "")
  end

  if l:name != ""
    let l:name = matchstr(l:name, ".*", strridx(l:name, "/") + 1)
    let l:branch = vimsesh#Gbranch_name()
    let l:dir = l:name . "/" . l:branch
    if a:0 == 0
      let l:name = l:name . '-' . l:branch
      let l:info = [l:dir, l:branch, l:name]
      return l:info
    else 
      let l:name = a:1
    end
  else
    let l:name = getcwd()
    let l:name = matchstr(l:name, ".*", strridx(l:name, "/") + 1)
    let l:dir = l:name
    if a:0 != 0 
      let l:name = a:1
    end
  end
  let l:info = [l:dir, l:name]
  return l:info
endfun

fun! vimsesh#RestoreSession(...)
  if a:0 == 0 || a:1 == ""
      let l:choice = confirm("Restore which session:", "&Default\n&Last\n&Cancel", 0)
    " end

    if l:choice == 1
      let l:info = vimsesh#FindSession()
    end

    if l:choice == 2 && g:session_options[0] != ''
      execute 'source ' . $HOME . "/nvim.local/sessions/" . g:session_options[0]
      return
    end

    if l:choice == 2 && g:session_options[0] == ''
      return
    end

    if l:choice == 3
      return
    end
  else
    let l:arglen = len(a:1)

    if strpart(a:1, l:arglen - 4) == '.vim'
      let l:param = strpart(a:1, 0, l:arglen - 4)
    else
      let l:param = a:1
    end
    let l:info = vimsesh#FindSession(l:param)
  end

  if len(l:info) > 2
    let l:name = l:info[0] . '/' . l:info[2] . '.vim'
  else
    let l:name = l:info[0] . '/' . l:info[1] . '.vim'
  end

  if filereadable($HOME . "/nvim.local/sessions/" . l:name)
    %bwipeout
    let g:session_options[0] = l:name
    execute 'source ' . $HOME . "/nvim.local/sessions/" . l:name
  else
    echo 'No session found'
  end
endfun

fun! vimsesh#CreateSession(info)
    if !isdirectory($HOME . "/nvim.local/sessions/" . a:info[0])
      call mkdir($HOME . "/nvim.local/sessions/" . a:info[0], "p")
    endif
  if len(a:info) > 2
    return a:info[0] . '/' . a:info[2] . '.vim'
  else
    return a:info[0] . '/' . a:info[1] . '.vim'
  end
endfun

fun! vimsesh#SaveSession(...)
  if a:0 == 0 || a:1 == ""
    let l:current = confirm("Save session as:", "&Current\n&Default\n&Exit", 0)
    echo l:current

    if g:session_options[0] != '' && l:current == 1
      if(argc() > 0)
        execute 'argd *'
      end
      execute 'mksession! ' . $HOME . '/nvim.local/sessions/' . g:session_options[0]
      return
    end

    if g:session_options[0] == '' && l:current == 1
      return
    end

    if l:current == 2
      let l:arg = ""
      let l:info = vimsesh#FindSession()
    end

    if l:current == 3
      return
    end
  else
    let l:arglen = len(a:1)

    if strpart(a:1, l:arglen - 4) == '.vim'
      let l:param = strpart(a:1, 0, l:arglen - 4)
    else
      let l:param = a:1
    end
    let l:info = vimsesh#FindSession(l:param)
  end

  if len(l:info) > 2
    let l:name = l:info[0] . '/' . l:info[2] . '.vim'
  else
    let l:name = l:info[0] . '/' . l:info[1] . '.vim'
  end

  if filereadable($HOME . "/nvim.local/sessions/" . l:name)
    let l:choice = confirm("Overwrite session?", "&Yes\n&No", 2)
    if l:choice == 1
      let l:name = vimsesh#CreateSession(l:info)
    else
      return
    end
  else
    let l:name = vimsesh#CreateSession(l:info)
  end

  if l:name != ""
    " TODO: Need to save args first, then restore if deleted
    if(argc() > 0)
      execute 'argd *'
    end
    let g:session_options[0] = l:name
    execute 'mksession! ' . $HOME . '/nvim.local/sessions/' . l:name
  else
    echo 'Session save halted'
  end
endfun

fun! vimsesh#DoRedir(options)
  let g:metasesh_options = a:options
  call writefile(g:metasesh_options, expand(''.g:session_meta), "b")
endfun

fun! vimsesh#SeshComplete(ArgLead, CmdLine, CursorPos)
  " return a list
    let l:info = vimsesh#FindSession()
    return map(split(glob($HOME . '/nvim.local/sessions/' . l:info[0] . '/' .'*.vim'), "\n"), 'fnamemodify(v:val, ":t")')
endfun

" ====================================================================
" Git related functions
" ====================================================================
" Courtesy itchyny's vim-gitbranch - expand if fugitive dependency unwanted
fun! vimsesh#Gbranch_name() abort
  if get(b:, 'gitbranch_pwd', '') !=# expand('%:p:h') || !has_key(b:, 'gitbranch_path')
    call vimsesh#Gbranch_detect(expand('%:p:h'))
  end
  if has_key(b:, 'gitbranch_path') && filereadable(b:gitbranch_path)
    let l:branch = get(readfile(b:gitbranch_path), 0, '')
    if l:branch =~# '^ref: '
      return substitute(l:branch, '^ref: \%(refs/\%(heads/\|remotes/\|tags/\)\=\)\=', '', '')
    elseif l:branch =~# '^\x\{20\}'
      return l:branch[:6]
    end
  end
  return ''
endfun

fun! vimsesh#Gbranch_dir(path) abort
  let l:path = a:path
  let l:prev = ''
  while l:path !=# prev
    let l:dir = l:path . '/.git'
    let l:type = getftype(l:dir)
    if l:type ==# 'dir' && isdirectory(l:dir.'/objects') && isdirectory(l:dir.'/refs') && getfsize(l:dir.'/HEAD') > 10
      return l:dir
    elseif l:type ==# 'file'
      let l:reldir = get(readfile(l:dir), 0, '')
      if l:reldir =~# '^gitdir: '
        return simplify(l:path . '/' . l:reldir[8:])
      end
    end
    let l:prev = l:path
    let l:path = fnamemodify(l:path, ':h')
  endwhile
  return ''
endfun

fun! vimsesh#Gbranch_detect(path) abort
  unlet! b:gitbranch_path
  let b:gitbranch_pwd = expand('%:p:h')
  let l:dir = vimsesh#Gbranch_dir(a:path)
  if l:dir !=# ''
    let l:path = l:dir . '/HEAD'
    if filereadable(l:path)
      let b:gitbranch_path = l:path
    end
  end
endfun

" ====================================================================
" Global variables and setup
" ====================================================================
" This is a little dangerous right now...
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

" session file for persistent data
if !exists('g:session_meta')
  let g:session_meta = g:session_directory.'/'.'.metaseshrc'
end


let g:session_options = ['']
let g:session_sourced = 0

" Make metasesh file
if !filereadable(g:session_meta)
  call system('touch ' . g:session_meta)
end

" Auto command optionality
if !exists('g:session_autocmds')
  let g:session_autocmds = 1
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

" ====================================================================
" Commands
" ====================================================================
command! -nargs=* -complete=customlist,vimsesh#SeshComplete SaveSession call vimsesh#SaveSession(<f-args>)
command! -nargs=* -complete=customlist,vimsesh#SeshComplete RestoreSession call vimsesh#RestoreSession(<f-args>)

" ====================================================================
" Auto Commands
" ====================================================================
if g:session_autocmds == 1
  aug PluginSession
    au!
    au VimEnter * if expand('<afile>') == "" | call vimsesh#RestoreSession()
    au VimLeave * call vimsesh#SaveSession()
    au VimLeave * call vimsesh#DoRedir(g:session_options)
  aug END
end

let g:loaded_vimsesh = 1
