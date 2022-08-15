{ pkgs, nixpkgs }:

let
  # See https://gitlab.com/liketechnik/nixos-files/-/blob/master/profiles/neovim/customization.nix

  normful-monokai = pkgs.vimUtils.buildVimPluginFrom2Nix {
    pname = "normful-monokai";
    version = "2022-04-25";
    src = pkgs.fetchFromGitHub {
      owner = "normful";
      repo = "monokai.nvim";
      rev = "cbec48006118debd61884e1e4d3641244af1ccd5";
      sha256 = "sha256-y2oKie1IMrt/KnPOoYelJM2pWHeiIcjweEMDPvSFiRM=";
    };
  };

  telescope-bookmarks-nvim = pkgs.vimUtils.buildVimPluginFrom2Nix {
    pname = "telescope-bookmarks-nvim";
    version = "2022-08-14";
    src = pkgs.fetchFromGitHub {
      owner = "dhruvmanila";
      repo = "telescope-bookmarks.nvim";
      rev = "b657e119cfbaf0f0b6a1de37edbd2383ed384eed";
      sha256 = "sha256-JpQbh73YoLkjZcz5VvMIhAcprye77Gke7N3C3eUTzpg=";
    };
  };

  coot-cmdalias-vim = pkgs.vimUtils.buildVimPluginFrom2Nix {
    pname = "coot-cmdalias-vim";
    version = "2014-08-07";
    src = pkgs.fetchFromGitHub {
      owner = "coot";
      repo = "cmdalias_vim";
      rev = "de14c3930a81428060e033d2c4d9ca507bab0c01";
      sha256 = "sha256-1ak1VBZ279MGmlsH9tBrknUeF1oSEKSTmUoF8kg1LhM=";
    };
  };

  coot-crdispatcher-vim = pkgs.vimUtils.buildVimPluginFrom2Nix {
    pname = "coot-crdispatcher-vim";
    version = "2020-09-24";
    src = pkgs.fetchFromGitHub {
      owner = "coot";
      repo = "CRDispatcher";
      rev = "79ce64696e069dc966eb2d51c7336c95af516cc9";
      sha256 = "sha256-yAGdI/mDAZV9mXDKctFoaWqAD3PSw9+n6UWYioIz8xg=";
    };
  };
in

{
  # See https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/editors/neovim/utils.nix

  customRC = pkgs.callPackage ./vimrc.nix {};

  packages.neovimPlugins = with pkgs.vimPlugins; {
    start = [ 
      # Lua utilities
      plenary-nvim

      # My colorschema
      normful-monokai

      # File tree browser
      nvim-tree-lua

      # Treesitter
      (nvim-treesitter.withPlugins
        (_: builtins.filter
          (x: x.pname != "tree-sitter-markdown-grammar")
          pkgs.tree-sitter.allGrammars))
      playground
      nvim-treesitter-textobjects

      # Telescope
      telescope-nvim
      telescope-zoxide
      telescope-fzy-native-nvim
      telescope-bookmarks-nvim
      popup-nvim

      # LSP config
      nvim-lspconfig

      # Viewer and finder for LSP symbols and tags
      vista-vim

      # Async run
      asyncrun-vim

      # Delete all the buffers except the current/named buffer
      BufOnly-vim

      # Make an alias to a command where the alias is any sequence
      coot-cmdalias-vim
      coot-crdispatcher-vim

      # Comments
      tcomment_vim

      # Enhanced . repeat
      vim-repeat

      # Git
      vim-fugitive
      git-messenger-vim
      gitsigns-nvim

      # Automatically inserts ends like `endif` and `endfunction`
      vim-endwise

      # Language-specific matching text (extends %)
      vim-matchup

      # Substitution and Typo Correction
      vim-abolish

      # Projections
      vim-projectionist

      # Nix
      vim-nix

      # Markdown
      vim-markdown

      # PlantUML
      plantuml-syntax

      # JSON
      jdaddy-vim

      # Golang
      vim-go

      # Ruby
      vim-ruby
      vim-rails

      # Python
      python-syntax

      # GraphQL
      vim-graphql

      # Open browser
      open-browser-vim
      open-browser-github-vim
    ];

    opt = [ ];
  };
}
