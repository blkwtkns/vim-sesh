# vim-sesh

## Need feedback!
I really wanted an easy and intuitive way to create, save, and restore vim sessions. I wanted it to be integrated with git and branching if git is involved. I also wanted to the ability to create default sessions or personally named sessions. And instead of having session files litered throughout my projects, I wanted my sessions to be in one place (as is the norm with vim session users), which would also give me the ability to even version the sessions so that others can easily pull them and remotely see specific branch projects. 

I'm trying to build on optionality, and I need edge case input as well, so any input or suggestions are welcomed. The code isn't the prettiest yet, but refactoring will come (this is my first plugin, please be brutal).

## Features
Break down to come, unitl then check out the code, it's pretty small

* Use `let g:sesh_directory` to set session destination (Default 0; Not functional yet)
    Neovim default: $HOME/nvim.local/sessions
    Vim default: $HOME/.vim/sessions
* Use `let g:sesh_autocmds` to enable autocommands (Default 0; Not functional yet)
* Utilize versioning of sessions with `let g:sesh_versioning = 1` (Default 0)
    This creates a directory '.vimsessions' in the root of the repo

### TODO:
* session pruning
* restore default state
* capability to create session directory in git repo
* trigger session save on commit
* navigate through sessions per commit
* on commit, add to buffer list all files not already opened, before creating session

## Acknowledgements 
Many thanks to itchyny!
His functions at: https://github.com/itchyny/vim-gitbranch allowed me to strip out all dependencies (though technically I'm still dependent on his logic!)

The rest is pretty much logic from here: http://vim.wikia.com/wiki/Go_away_and_come_back that I then bent to my will.

# Cheers!
