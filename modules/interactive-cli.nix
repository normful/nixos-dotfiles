{
  config,
  lib,
  pkgs-pinned-unstable,
  ...
}:
{
  config = lib.mkIf config.my.enableInteractiveCli {
    environment.systemPackages = (
      with pkgs-pinned-unstable;
      [
        nix-output-monitor
        nvd

        chezmoi
        mise
        neovim

        #################################################################################
        # Basic utilities
        #################################################################################

        # https://www.gnu.org/software/coreutils/manual/html_node/index.html
        # https://www.mankier.com/package/coreutils-common
        coreutils-full

        # https://uutils.github.io/coreutils/docs/
        # uutils-coreutils-noprefix

        killall

        # https://www.gnu.org/software/sed/
        # https://www.mankier.com/1/sed
        gnused

        # rm replacement
        # https://github.com/MilesCranmer/rip2
        rip2

        # https://github.com/eth-p/bat-extras/blob/master/doc/batwatch.md
        bat-extras.batwatch

        # https://github.com/eth-p/bat-extras/blob/master/doc/batpipe.md
        bat-extras.batpipe

        #################################################################################
        # Shell history
        #################################################################################

        # hh
        hstr

        #################################################################################
        # View processes
        #################################################################################

        # https://github.com/dalance/procs#usage
        procs

        #################################################################################
        # Viewing files and directories
        #################################################################################

        # https://github.com/eza-community/eza
        eza

        # https://dystroy.org/broot/
        broot

        # https://github.com/bootandy/dust
        dust

        # https://github.com/Byron/dua-cli/
        dua

        # https://yazi-rs.github.io/docs/quick-start
        yazi

        #################################################################################
        # Navigating directories
        #################################################################################

        # https://github.com/ajeetdsouza/zoxide
        zoxide

        #################################################################################
        # Finding files
        #################################################################################

        # https://www.mankier.com/1/find
        # https://www.mankier.com/1/xargs
        findutils

        # https://github.com/sharkdp/fd
        fd

        # https://github.com/eth-p/bat-extras/blob/master/doc/batgrep.md
        bat-extras.batgrep

        # https://junegunn.github.io/fzf/
        fzf

        # https://github.com/BurntSushi/ripgrep/blob/master/GUIDE.md
        ripgrep

        # https://github.com/phiresky/ripgrep-all
        ripgrep-all

        # https://ugrep.com
        ugrep

        #################################################################################
        # View processes
        #################################################################################

        # https://htop.dev
        htop

        # https://github.com/dalance/procs#usage
        procs

        #################################################################################
        # Pagers
        #################################################################################

        # https://github.com/sharkdp/bat#how-to-use
        bat

        # https://github.com/dandavison/delta
        delta

        # https://github.com/lucc/nvimpager
        nvimpager

        # https://github.com/eth-p/bat-extras/blob/master/doc/prettybat.md
        bat-extras.prettybat

        # https://github.com/eth-p/bat-extras/blob/master/doc/batman.md
        bat-extras.batman

        #################################################################################
        # Diffs
        #################################################################################

        # https://www.gnu.org/software/diffutils/diffutils.html
        diffutils

        # https://difftastic.wilfred.me.uk
        difftastic

        #################################################################################
        # Git support tools
        #################################################################################

        git-lfs
      ]
    );

    environment.variables = {
      EDITOR = "nvim";
      GIT_EDITOR = "nvim";
    };

    programs.nh = {
      enable = true;
      flake = config.my.flakePath;
    };
  };
}
