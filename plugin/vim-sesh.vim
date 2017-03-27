" =============================================================================
" Filename: autoload/vim-sesh.vim
" Author: blkwtkns
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

" Test Caveat: -c can't be used because of the dependency
" This will be for restore function
fun! sesh#FindSession(...)
  let l:name = getcwd()
  " Check if located within a repo
  if !isdirectory(".git")
    let l:name = substitute(finddir(".git", ".;"), "/.git", "", "")
  end

  if l:name != "" && a:0 == 0
    let l:name = matchstr(l:name, ".*", strridx(l:name, "/") + 1)
    let l:dir = l:name
    " let l:branch = GitInfo()
    let l:branch = sesh#Gbranch_name()
    let l:name = l:name . '.' . l:branch
  else
    let l:name = getcwd()
    let l:name = matchstr(l:name, ".*", strridx(l:name, "/") + 1)
    let l:dir = l:name

    if a:1 != ""
      let l:name = a:1
    end
  end
    return l:dir . '/' . l:name . '.vim'
endfun

fun! sesh#RestoreSession(...)
  if a:0 == 0
    let l:name = sesh#FindSession()
  end
  if a:0 > 0 && a:1 != ""
    let l:name = sesh#FindSession(a:1)
  end

  if filereadable($HOME . "/nvim.local/sessions/" . l:name)
    execute 'source ' . $HOME . "/nvim.local/sessions/" . l:name
  else
    echo 'No session found'
  end
endfun


" This needs to be broken up into a couple more functions
" This is for save function
fun! sesh#CreateSession(...)
  let l:name = getcwd()
  " Check if located within a repo
  if !isdirectory(".git")
    let l:name = substitute(finddir(".git", ".;"), "/.git", "", "")
  end

  " Both sides of conditional create appropriate dir if not present
  " If pass first check, do git branch naming (if no name given)
  " If doesn't pass, do naming after directory or name given
  if l:name != "" && a:0 == 0
    let l:name = matchstr(l:name, ".*", strridx(l:name, "/") + 1)

    if !isdirectory($HOME . "/nvim.local/sessions/" . l:name)
      call mkdir($HOME . "/nvim.local/sessions/" . l:name, "p")
    endif

    let l:dir = l:name
    " let l:branch = GitInfo()
    let l:branch = sesh#Gbranch_name()
    let l:name = l:name . '.' . l:branch
  else
    let l:name = getcwd()
    let l:name = matchstr(l:name, ".*", strridx(l:name, "/") + 1)
    let l:dir = l:name

    if !isdirectory($HOME . "/nvim.local/sessions/" . l:name)
      call mkdir($HOME . "/nvim.local/sessions/" . l:name, "p")
    endif

    if a:1 != ""
      let l:name = a:1
    end
  end
    return l:dir . '/' . l:name . '.vim'
endfun

fun! sesh#SaveSession(...)
  if a:0 == 0 && !filereadable($HOME . "/nvim.local/sessions/" . sesh#FindSession())
    let l:name = sesh#CreateSession()
  elseif a:0 > 0 && a:1 != "" && !filereadable($HOME . "/nvim.local/sessions/" . sesh#FindSession(a:1))
    let l:name = sesh#CreateSession(a:1)
  else
    let l:name = ""
  end

  if l:name != ""
    execute 'mksession! ' . $HOME . '/nvim.local/sessions/' . l:name
  else
    echo 'Session already exists or Error occurred and this is a bad report'
  end
endfun

command! -nargs=? SaveSession call sesh#SaveSession(<f-args>)
command! -nargs=? RestoreSession call sesh#RestoreSession(<f-args>)

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


let &cpo = s:save_cpo
unlet s:save_cpo
