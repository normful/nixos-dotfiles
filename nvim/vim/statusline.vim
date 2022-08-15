set statusline=%{StatuslineFilepath()}

" This adding the left/right separator.
" Everything in the statusline above here is on the left side,
" everything in the status line below here is on the right side
set statusline+=%=

set statusline+=%#ToolbarLine#
set statusline+=\ %#StatusLine#
set statusline+=\ %{AsyncRunStatuslineFragment()}

set statusline+=\ C%c    " cursor column
set statusline+=\ L%l/%L " cursor line/total lines
set statusline+=\ %P     " percent through file

function StatuslineFilepath() "{{{2
    return expand('%t')
endfunction

function AsyncRunStatuslineFragment() "{{{2
    if (&ft == 'typescript' || &ft == 'typescriptreact')
        return 'run:' . g:asyncrun_status
    endif
    return ''
endfunction
