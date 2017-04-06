" =============================================================================
" Filename: autoload/vim-sesh.vim
" Author: blkwtkns
" =============================================================================
if exists('g:autoloaded_vimsesh') || &cp
  finish
end

" let s:save_cpo = &cpo
" set cpo&vim

" This will be for restore function
" Make this return name, branch, and directory
" TODO: Track current session, view .dotfiles, allow session directory
" placement, allow particular sessions to be kept in actual project
fun! sesh#FindSession(...)
  let l:name = getcwd()
  " Check if located within a repo
  if !isdirectory(".git")
    let l:name = substitute(finddir(".git", ".;"), "/.git", "", "")
  end

  if l:name != ""
    let l:name = matchstr(l:name, ".*", strridx(l:name, "/") + 1)
    let l:branch = sesh#Gbranch_name()
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

fun! sesh#RestoreSession(...)
  if a:0 == 0 || a:1 == ""
      let l:choice = confirm("Restore which session:", "&Default\n&Last\n&Cancel", 0)
    " end

    if l:choice == 1
      let l:info = sesh#FindSession()
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
    " TODO: TEST TEST TEST
    let l:arglen = len(a:1)

    if strpart(a:1, l:arglen - 4) == '.vim'
      let l:param = strpart(a:1, 0, l:arglen - 4)
    else
      let l:param = a:1
    end
    let l:info = sesh#FindSession(l:param)
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

fun! sesh#CreateSession(info)
    if !isdirectory($HOME . "/nvim.local/sessions/" . a:info[0])
      call mkdir($HOME . "/nvim.local/sessions/" . a:info[0], "p")
    endif
  if len(a:info) > 2
    return a:info[0] . '/' . a:info[2] . '.vim'
  else
    return a:info[0] . '/' . a:info[1] . '.vim'
  end
endfun

fun! sesh#SaveSession(...)
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
      let l:info = sesh#FindSession()
    end

    if l:current == 3
      return
    end
  else
    " TODO: TEST TEST TEST
    let l:arglen = len(a:1)

    if strpart(a:1, l:arglen - 4) == '.vim'
      let l:param = strpart(a:1, 0, l:arglen - 4)
    else
      let l:param = a:1
    end
    let l:info = sesh#FindSession(l:param)
  end

  if len(l:info) > 2
    let l:name = l:info[0] . '/' . l:info[2] . '.vim'
  else
    let l:name = l:info[0] . '/' . l:info[1] . '.vim'
  end

  if filereadable($HOME . "/nvim.local/sessions/" . l:name)
    let l:choice = confirm("Overwrite session?", "&Yes\n&No", 2)
    if l:choice == 1
      let l:name = sesh#CreateSession(l:info)
    else
      return
    end
  else
    let l:name = sesh#CreateSession(l:info)
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

fun! sesh#SeshComplete(ArgLead, CmdLine, CursorPos)
  " return ['one', 'two', 'three']
    let l:info = sesh#FindSession()
    return map(split(glob($HOME . '/nvim.local/sessions/' . l:info[0] . '/' .'*.vim'), "\n"), 'fnamemodify(v:val, ":t")')
endfun

command! -nargs=* -complete=customlist,sesh#SeshComplete SaveSession call sesh#SaveSession(<f-args>)
command! -nargs=* -complete=customlist,sesh#SeshComplete RestoreSession call sesh#RestoreSession(<f-args>)


" Courtesy itchyny's vim-gitbranch - expand if fugitive dependency unwanted
fun! sesh#Gbranch_name() abort
  if get(b:, 'gitbranch_pwd', '') !=# expand('%:p:h') || !has_key(b:, 'gitbranch_path')
    call sesh#Gbranch_detect(expand('%:p:h'))
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

fun! sesh#Gbranch_dir(path) abort
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

fun! sesh#Gbranch_detect(path) abort
  unlet! b:gitbranch_path
  let b:gitbranch_pwd = expand('%:p:h')
  let l:dir = sesh#Gbranch_dir(a:path)
  if l:dir !=# ''
    let l:path = l:dir . '/HEAD'
    if filereadable(l:path)
      let b:gitbranch_path = l:path
    end
  end
endfun

" command! GitBranch call Gbranch_name()

" Depends on fugitive plugin
" fun! sesh#GitInfo()
"   let l:git = fugitive#head()
"   if l:git != ''
"     return l:git
"   else
"     return ''
" endfun

" command! GitInfo call sesh#GitInfo()
" command! FindProj call sesh#FindSession()


" let &cpo = s:save_cpo
" unlet s:save_cpo

let g:autoloaded_vimsesh = 1
" vim:set et sw=2 ts=2 tw=78 fdm=marker
