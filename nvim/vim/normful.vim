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
    " g:test#project_root is a setting in https://github.com/vim-test/vim-test
    " projectroot#guess() is a function from https://github.com/dbakker/vim-projectroot
    let g:test#project_root = projectroot#guess(expand('%:p'))
endfunction

function! normful#TerminalNoNumber()
    if &buftype == 'terminal'
        setlocal nonumber
    else
        set number
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
