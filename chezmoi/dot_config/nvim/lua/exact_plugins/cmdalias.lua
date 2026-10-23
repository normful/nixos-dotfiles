return {
  'coot/cmdalias_vim',
  dependencies = {
    { 'coot/CRDispatcher', lazy = false },
  },
  lazy = false,
  config = function()
    local alias_definitions = {
      { 'Vsp', 'vsp' },
      { 'Vps', 'vsp' },
      { 'vps', 'vsp' },
      { 'Sp', 'sp' },
      { 'W!', 'w!' },
      { 'w', 'w!' },
      { 'W', 'w!' },
      { 'Q!', 'q!' },
      { 'Wq!', 'wq!' },
      { 'WQ!', 'wq!' },
      { 'Gbl', 'NormfulGitBlame' },
      { 'N', 'Neorg' },
      { 'ch', 'checkhealth' },
      { 'term', 'ToggleNvchadTerminal' },
      { 'ter', 'ToggleNvchadTerminal' },
      { 'te', 'ToggleNvchadTerminal' },
    }

    local augroup_id = vim.api.nvim_create_augroup('CmdAliases', { clear = true })

    for _, def in ipairs(alias_definitions) do
      local alias = def[1]
      local original_command = def[2]
      vim.api.nvim_create_autocmd('VimEnter', {
        group = augroup_id,
        pattern = '*', -- Apply globally on VimEnter
        command = string.format('CmdAlias %s %s', alias, original_command),
        desc = string.format('Define %s as alias for %s', alias, original_command),
      })
    end
  end,
}
