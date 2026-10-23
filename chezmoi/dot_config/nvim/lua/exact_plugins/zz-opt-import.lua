-- Imports the non-essential plugin specs from lua/opt-plugins.
--
-- This lives in a spec file rather than as an entry in `require('lazy').setup`
-- because Nix-built machines (cyan) get their init from
-- packages/neovim/initLazyAndNvChad.lua through the customRC string baked at
-- build time, so anything added to init.lua would not take effect until a
-- darwin-rebuild switch. A spec file is read at runtime on every machine.
--
-- Why a separate directory at all: `lua/plugins` is `exact_` in the chezmoi
-- source, so it prunes targets with no source entry. Chezmoi still counts an
-- IGNORED source file as a source child, which is why moving the non-essential
-- specs out of `lua/plugins` (instead of ignoring them inside it) is what
-- actually removes them from an exe.dev VM that applied the full config
-- earlier.
--
-- exe.dev VMs do not deploy lua/opt-plugins (see chezmoi/.chezmoiignore), and
-- lazy reports "No specs found for module" for an import of an absent
-- directory, hence the cond guard.
return {
  {
    import = 'opt-plugins',
    cond = function()
      return vim.uv.fs_stat(vim.fn.stdpath('config') .. '/lua/opt-plugins') ~= nil
    end,
  },
}
