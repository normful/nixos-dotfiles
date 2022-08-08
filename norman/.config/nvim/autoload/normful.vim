" vim: nowrap ts=4 sw=4 sts=4 et

function! normful#SetTabSettings()
    let l:tabstop = 1 * input('set tabstop = softtabstop = shiftwidth = ')
    if l:tabstop > 0
        let &l:sts = l:tabstop
        let &l:ts = l:tabstop
        let &l:sw = l:tabstop
    endif

    call normful#PrintTabSettings()
endfunction

function! normful#PrintTabSettings()
    try
        echohl ModeMsg
        echon ' tabstop='.&l:ts
        echon ' shiftwidth='.&l:sw
        echon ' softtabstop='.&l:sts
        if &l:et
            echon ' expandtab'
        else
            echon ' noexpandtab'
        endif
    finally
        echohl None
    endtry
endfunction

function! normful#StripTrailingWhitespace()
    " Preparation - save last search and cursor position
    let _s=@/
    let l = line(".")
    let c = col(".")
    " Strip trailing white space
    %s/\s\+$//e
    " Clean up: restore previous search history and cursor position
    let @/=_s
    call cursor(l, c)
endfunction

function! normful#WordFrequency() range
  let all = split(join(getline(a:firstline, a:lastline)), '\A\+')
  let frequencies = {}
  for word in all
    let frequencies[word] = get(frequencies, word, 0) + 1
  endfor
  new
  setlocal buftype=nofile bufhidden=hide noswapfile tabstop=20
  for [key,value] in items(frequencies)
    call append('$', key."\t".value)
  endfor
  sort i
endfunction

function! normful#ConfigureJankoVimTestProjectRoot()
    if (&ft == 'go')
        " For Go files, vim-test's built-in ginkgo logic already has the right
        " folder set. We don't need to set g:test#project_root
        return
    endif

    if (&ft == 'typescript' || &ft == 'typescriptreact')
        " g:test#project_root is a setting in https://github.com/vim-test/vim-test
        " projectroot#guess() is a function from https://github.com/dbakker/vim-projectroot
        let g:test#project_root = projectroot#guess(expand('%:p'))
        return
    endif

    if (&ft == 'javascript')
        let g:test#project_root = projectroot#guess(expand('%:p'))
        return
    endif
endfunction

function! normful#TerminalNoNumber()
    if &buftype == 'terminal'
        setlocal nonumber
    else
        set number
    endif
endfunction

" From https://github.com/hneutr/dotfiles
" When opening vim from within vim (eg, from a terminal split):
" - open it as a split
"	- call the autocommand that says we entered a window
" - close the terminal
function normful#SplitWithoutNesting()
    if !empty($NVIM_LISTEN_ADDRESS) && $NVIM_LISTEN_ADDRESS !=# v:servername
        " start a job with the source vim instance
        let g:receiver = jobstart(['nc', '-U', $NVIM_LISTEN_ADDRESS], {'rpc': v:true})

        " get the filename of the newly opened buffer
        let g:filename = fnameescape(expand('%:p'))

        " wipeout the buffer
        noautocmd bwipeout

        " open the buffer in the source vim instance
        call rpcrequest(g:receiver, "nvim_command", "edit ".g:filename)

        " call the autocommand to enter windows
        call rpcrequest(g:receiver, "nvim_command", "doautocmd BufWinEnter")

        " quit this secondary instance of vim
        quitall
    endif
endfunction

function! normful#OpenTerminal()
  belowright term
  startinsert
endfunction

function! normful#GitBlame()
  " fugitive command
  Git blame
endfunction
