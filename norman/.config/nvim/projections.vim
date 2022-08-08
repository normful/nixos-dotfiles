" NeoBundle 'tpope/vim-projectionist' {{{1

let g:projectionist_heuristics = {
      \ "main.ts": {
      \   "*.ts": {"type": "source", "alternate": "{file|dirname}/__tests__/{basename}_test.ts"},
      \   "**/__tests__/*_test.ts": {"type": "test", "alternate": "{}.ts"},
      \   "**/__snapshots__/*.snap": {"type": "test", "alternate": "{file|dirname|dirname}/{basename}"},
      \ },
      \
      \ "some_file_in_a_root_dir_that_triggers_the_following_rules": {
      \   "*.blahblah": {"type": "source",  "alternate": "{}_test.blahblah"},
      \ }}
