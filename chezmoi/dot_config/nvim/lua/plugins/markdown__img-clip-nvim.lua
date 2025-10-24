return {
  'HakonHarnes/img-clip.nvim',
  ft = { 'asciidoc', 'html', 'markdown', 'md', 'org', 'plaintex', 'quarto', 'rmd', 'rst', 'tex', 'typst', 'vimwiki' },
  opts = {
    default = {
      drag_and_drop = {
        enabled = true,
        insert_mode = true,
      },

      relative_to_current_file = true,
      show_dir_path_in_prompt = true,

      download_images = true,
      copy_images = true,

      prompt_for_file_name = false,
      file_name = '%Y%m%d-%H%M%S',

      extension = 'jpg',

      -- Using a custom `process_cmd` (either here in `default` for
      -- all filetypes, or in filetype-specific config below)
      -- can result in various errors. I'm purposely avoiding it for now.
    },
    filetypes = {
      markdown = {
        dir_path = './images',
        template = '![$FILE_NAME]($FILE_PATH)',
        url_encode_path = true,
      },

      -- TODO: Actually try using these settings for typst and tex, and creating PDFs; I haven't yet

      typst = {
        dir_path = './figures',
        template = [[
          #align(center)[#image("$FILE_PATH", height: 80%)]
          ]],
      },

      tex = {
        dir_path = './figures',
        template = [[
    \begin{figure}[h]
      \centering
      \includegraphics[width=0.8\textwidth]{$FILE_PATH}
    \end{figure}
        ]],
      },
    },
  },
  keys = {
    { '<Leader>p', '<Cmd>PasteImage<CR>', desc = 'Paste image from system clipboard' },
  },
}
