return {
  'alker0/chezmoi.vim',
  lazy = false,
  init = function()
    vim.g['chezmoi#use_tmp_buffer'] = true
    vim.g['chezmoi#source_dir_path'] = '~/code/nixos-dotfiles/chezmoi'
  end,
}
