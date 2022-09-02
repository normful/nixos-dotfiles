colorscheme monokai

if len(luaeval('vim.lsp.buf_get_clients()')) > 1
  setlocal omnifunc=v:lua.vim.lsp.omnifunc
endif

" Test Running {{{2
" NeoBundle 'normful/vim-test'

" TODO(norman): Configure later
" augroup janko_vim_test_mappings_augroup
"     autocmd!
"
"     " This function sets let g:test#project_root
"     autocmd FileType go,ruby,javascript,typescript,typescriptreact call normful#ConfigureJankoVimTestProjectRoot()
" augroup END

" Use <Tab> and <S-Tab> for navigate completion list:
inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

" Golang {{{2
" NeoBundle 'fatih/vim-go'
let g:go_version_warning = 0
let g:go_template_file = 'normans-vim-go-template.go'

" To learn how to use vim-go, watch and/or read:
" https://www.youtube.com/watch?v=7BqJ8dzygtU
" https://github.com/fatih/vim-go-tutorial
"
" To learn how to use vim-go with delve:
" https://twitter.com/fatih/status/978652722835656704

let g:go_doc_popup_window = 1

" formatting with goimports (which has a superset of gofmt functionality) {{{3
" let g:go_fmt_command = "goimports"
" let g:go_fmt_autosave = 0
" let g:go_fmt_options = "-tabwidth=4"

" autocomplete with gocode {{{3
let g:go_gocode_autobuild = 1
let g:go_gocode_unimported_packages = 1

" linting {{{3
let g:go_metalinter_autosave = 0
let g:go_metalinter_command = "--config=/Users/norman/.gometalinter.json"

" misc {{{3
let g:go_autodetect_gopath = 1
let g:go_test_prepend_name = 1
let g:go_fold_enable = ['block', 'import', 'varconst', 'package_comment']
let $GINKGO_EDITOR_INTEGRATION = "true"

" Use quickfix for all output, since ale uses locationlist for its output
let g:go_list_type = "quickfix"

" settings controlled by update time {{{3
" setting g:go_updatetime too low (e.g 10) causes screen artifacts
let g:go_updatetime = 1000
let g:go_auto_sameids = 0
let g:go_auto_type_info = 1
" let g:go_info_mode = 'gocode'

" highlighting {{{3
let g:go_highlight_array_whitespace_error    = 1
let g:go_highlight_build_constraints         = 1
let g:go_highlight_chan_whitespace_error     = 1
let g:go_highlight_extra_types               = 1
let g:go_highlight_fields                    = 1
let g:go_highlight_format_strings            = 1
let g:go_highlight_function_arguments        = 1
let g:go_highlight_function_calls            = 1
let g:go_highlight_functions                 = 1
let g:go_highlight_generate_tags             = 1
let g:go_highlight_operators                 = 1
let g:go_highlight_space_tab_error           = 1
let g:go_highlight_string_spellcheck         = 1
let g:go_highlight_trailing_whitespace_error = 1
let g:go_highlight_types                     = 1
let g:go_highlight_variable_assignments      = 0
let g:go_highlight_variable_declarations     = 0

" debugger windows {{{3
let g:go_debug_windows = {
    \ 'stack': 'botleft 70vnew',
    \ 'out':   'botright 10new',
    \ 'vars':  'leftabove 70vnew',
\ }

" general settings {{{3
augroup golang_augroup
    autocmd!
    autocmd BufNewFile,BufRead *.go setlocal noexpandtab tabstop=4 shiftwidth=4 softtabstop=4

    " Write the contents of the file, if it has been modified, on each
    " :next, :rewind, :last, :first, :previous, :stop, :suspend, :tag, :!,
    " :make, CTRL-] and CTRL-^ command; and when a :buffer, CTRL-O, CTRL-I,
    " '{A-Z0-9}, or `{A-Z0-9} command takes one to another file.
    autocmd BufNewFile,BufRead *.go setlocal autowrite

    autocmd BufNewFile,BufRead *.go command! -buffer -bar -nargs=* -range=0 A call go#alternate#Switch(<bang>1, 'edit')
augroup END

" key bindings {{{3
let g:go_def_mapping_enabled = 0

" Note: For commands that are thin wrappers around go guru,
" it helps to read http://golang.org/s/using-guru to understand how guru works
augroup golang_map_augroup
    autocmd!

    " :GoAutoTypeInfoToggle
    " This is helpful for browsing, but can mask lint messages.
    " It is currently configured to always start automatically,
    " so this shortcut is for toggling it off when you need to read all lint
    " messages.
    autocmd FileType go nnoremap <buffer> <leader>i :GoAutoTypeInfoToggle<CR>

    " :GoSameIdsAutoToggle
    autocmd FileType go nnoremap <buffer> <leader>si :GoSameIdsAutoToggle<CR>

    " :GoDef in this window
    "
    " Setting this to use <buffer> <leader> instead of only <leader>
    " causes this mapping to override the regular <leader>v mapping when
    " editing Go files.
    "
    " :GoDef will jump to the definition of the identifier under the cursor. When the identifier is a type, it jumps to the type declaration.
    " :GoDefType will jump to the type declaration of the identifier under the cursor, even when the identifier is a variable.
    "
    " autocmd FileType go nnoremap <buffer> <silent> <leader>v <Plug>(coc-definition)

    autocmd FileType go nnoremap <buffer> <leader>v :GoDef<CR>

    " autocmd FileType go nnoremap <buffer> <silent> <leader>vt <Plug>(coc-type-definition)

    " :GoDoc
    " autocmd FileType go nnoremap <buffer> <leader>d :GoDoc<CR>
    " Norman says: This sometimes works, sometimes takes forever. Disabling for now.

    " autocmd FileType go nnoremap <buffer> <silent> <leader>d :call <SID>coc_action_do_hover_show_documentation()<CR>

    " :GoCallees
    " This requires having the scope for go guru set up properly.
    " An autocmd that calls :GoGuruScope at the bottom of this file does that.
    " autocmd FileType go nnoremap <buffer> <leader>ce :GoCallees<CR>
    " autocmd FileType go nnoremap <buffer> <leader>lees :GoCallees<CR>
    " Norman says: this DOES NOT YET work with go modules

    " :GoCallers
    " This requires having the scope for go guru set up properly.
    " An autocmd that calls :GoGuruScope at the bottom of this file does that.
    " autocmd FileType go nnoremap <buffer> <leader>cr :GoCallers<CR>
    " autocmd FileType go nnoremap <buffer> <leader>lers :GoCallers<CR>
    " Norman says :GoCallers does not work with go modules
    " autocmd FileType go nnoremap <buffer> <silent> <leader>ler <Plug>(coc-references)
    " autocmd FileType go nnoremap <buffer> <silent> <leader>lers <Plug>(coc-references)

    " :GoCallstack
    " This requires having the scope for go guru set up properly.
    " An autocmd that calls :GoGuruScope at the bottom of this file does that.
    " autocmd FileType go nnoremap <buffer> <leader>cs :GoCallstack<CR>
    " Norman says: this DOES NOT YET work with go modules

    " :GoReferrers
    autocmd FileType go nnoremap <buffer> <leader>f :GoReferrers<CR>

    " autocmd FileType go nnoremap <buffer> <silent> <leader>f <Plug>(coc-references)
    " autocmd FileType go nnoremap <buffer> <silent> <leader>r <Plug>(coc-references)

    " :GoImplements
    " autocmd FileType go nnoremap <buffer> <leader>im :GoImplements<CR>
    " autocmd FileType go nnoremap <buffer> <silent> <leader>im <Plug>(coc-implementation)

    " :GoDeclsDir
    autocmd FileType go nnoremap <buffer> <leader>s :GoDeclsDir<CR>

    " :GoAlternate
    autocmd FileType go nnoremap <buffer> <leader>a    :GoAlternate!<CR>

    " :GoTest
    autocmd FileType go nnoremap <buffer> <leader>T    :GoTest<CR>

    " :Gingko current file
    autocmd FileType go nnoremap <buffer> <leader>t    :call RunCurrentGinkgoFile()<CR>

    " :GoCoverage and coverage toggle (pressing it again will clear the highlighting)
    autocmd FileType go nnoremap <buffer> <leader>cov  :GoCoverageToggle<CR>

    " :GoCoverageClear
    autocmd FileType go nnoremap <buffer> <leader>cc   :GoCoverageClear<CR>

    " :GoImport
    autocmd Filetype go nnoremap <buffer> <leader>imp :GoImport<Space>

    " :GoDebugBreakpoint
    " <F9>
    " You need to set breakpoints before calling :GoDebugStart
    autocmd FileType go nnoremap <buffer> <leader>db  :GoDebugBreakpoint<CR>

    " :GoDebugStart
    " After calling :GoDebugStart, you may need to call :GoDebugContinue to
    " start the process
    autocmd FileType go nnoremap <buffer> <leader>D   :GoDebugStart<CR>

    " :GoDebugTest
    autocmd FileType go nnoremap <buffer> <leader>dt  :GoDebugTest<CR>

    " :GoDebugStop
    autocmd FileType go,godebugstacktrace,godebugvariables,godebugoutput nnoremap <buffer> <leader>DS :GoDebugStop<CR>

    " DEBUGGER COMMANDS available after starting `dlv` with either
    " :GoDebugStart or :GoDebugText

    " :GoDebugNext (i.e. step over)
    " <F10>
    autocmd FileType go,godebugstacktrace,godebugvariables,godebugoutput nnoremap <buffer> <leader>dn  :GoDebugNext<CR>

    " :GoDebugStep
    " <F11>
    autocmd FileType go,godebugstacktrace,godebugvariables,godebugoutput nnoremap <buffer> <leader>ds  :GoDebugStep<CR>

    " :GoDebugContinue
    " <F5>
    autocmd FileType go,godebugstacktrace,godebugvariables,godebugoutput nnoremap <buffer> <leader>dc  :GoDebugContinue<CR>

    " :GoDebugStepOut
    autocmd FileType go,godebugstacktrace,godebugvariables,godebugoutput nnoremap <buffer> <leader>dso :GoDebugStepOut<CR>

    " Norman says: This DOES NOT YET work with go modules
    " :GoMetaLinter
    " autocmd FileType go nnoremap <buffer> <leader>L    :GoMetaLinter<CR>
    " autocmd FileType go nnoremap <buffer> <leader>ml   :GoMetaLinter<CR>

    " :GoBuild and :GoTestCompile
    autocmd FileType go nnoremap <buffer> <leader>B    :<C-u>call <SID>build_go_files()<CR>

    " :GoRename
    " autocmd FileType go nnoremap <buffer> <leader>re   :GoRename<CR>
    " autocmd FileType go nnoremap <buffer> <leader>re <Plug>(coc-rename)

    " :GoRun
    autocmd FileType go nnoremap <buffer> <leader>R    :GoRun<CR>
augroup END

" build_go_files is a custom function that builds or compiles the test file.
" It calls :GoBuild if its a Go file, or :GoTestCompile if it's a test file
function! s:build_go_files()
  let l:file = expand('%')
  if l:file =~# '^\f\+_test\.go$'
    call go#test#Test(0, 1)
  elseif l:file =~# '^\f\+\.go$'
    call go#cmd#Build(0)
  endif
endfunction

" CoffeeScript {{{2
augroup coffeescript_augroup
    autocmd!

    autocmd BufNewFile,BufReadPost *.coffee setl shiftwidth=2 expandtab
    autocmd FileType coffee setlocal dictionary+=$HOME/.vim/dict/node.dict

    " <leader>c to CoffeeCompile into scratch buffer
    autocmd FileType coffee map <leader>c :CoffeeCompile<CR>

    " <leader>r to CoffeeRun into scratch buffer
    autocmd FileType coffee map <leader>r :CoffeeRun<CR>

    " Visual select lines then <leader>c to CoffeeCompile selection into scratch buffer
    autocmd FileType coffee vnoremap <leader>c <esc>:'<,'>:CoffeeCompile<CR>

    " :C[n] jumps to line [n] in the CoffeeCompile scratch buffer
    autocmd FileType coffee command! -nargs=1 C CoffeeCompile | :<args>
augroup END

" Note: q closes CoffeeCompile scratch buffer

let g:coffee_compile_vert = 1
let g:coffee_watch_vert = 1
let g:coffee_run_vert = 1

" NeoBundle 'lukaszkorecki/CoffeeTags'
let g:CoffeeAutoTagIncludeVars=1

" Ruby {{{2

" NeoBundle 'vim-ruby/vim-ruby'
augroup rubycompl_augroup
    autocmd!
    autocmd FileType ruby,eruby let g:rubycomplete_buffer_loading = 1
    autocmd FileType ruby,eruby let g:rubycomplete_classes_in_global = 1
    autocmd FileType ruby,eruby let g:rubycomplete_rails = 1
augroup END

" NeoBundle 'tpope/vim-rails' {{{3
augroup rails_augroup
    autocmd!
    autocmd FileType ruby nnoremap <buffer> <leader>f  gf
    autocmd FileType ruby CmdAlias emo Emodel
    autocmd FileType ruby CmdAlias eco Econtroller
augroup END

augroup cd_augroup
    autocmd!
    " Changes the window-local current directory to its file's directory
    " (except when file is in /tmp)
    autocmd BufEnter * if expand("%:p:h") !~ '^/tmp' | silent! lcd %:p:h | endif
augroup END

augroup prev_line_pos_augroup
    autocmd!
    autocmd BufReadPost *
            \ if line("'\"") > 0 && line("'\"") <= line("$") |
            \     execute 'normal! g`"zvzz' |
            \ endif
augroup END

augroup yaml_augroup
    autocmd!
    autocmd FileType yaml,yml setlocal tabstop=2 softtabstop=2 shiftwidth=2
augroup END

augroup rst_augroup
    autocmd!
    autocmd FileType rst setlocal nospell
augroup END

augroup crontab_augroup
    autocmd!
    autocmd FileType crontab setlocal nobackup nowritebackup
augroup END

augroup ruby_augroup
    autocmd!
    autocmd FileType ruby setlocal tabstop=2 softtabstop=2 shiftwidth=2 nofoldenable
    autocmd BufNewFile,BufRead *_spec.rb setlocal foldenable foldlevelstart=1
augroup END

augroup puml_augroup
    autocmd!

    " Disable auto indenting
    autocmd FileType plantuml setlocal noautoindent nocindent nosmartindent indentexpr=""
    autocmd FileType plantuml setlocal tabstop=4 softtabstop=4 shiftwidth=4 nofoldenable expandtab
augroup END

augroup json_augroup
    autocmd!
    autocmd FileType json setlocal nofoldenable
augroup END

" Something earlier tends to override this to true. So always set this near the end
set nowrap
