# To create new aliases (not abbreviations):
# 1. `alias hello 'echo hello'`
# 2. `fs hello`

# `funced function_name` edits the file for the function.

if status is-interactive
    fish_vi_key_bindings

    set -x HISTFILE ~/.config/fish/hh.history
    set -x HSTR_CONFIG hicolor,prompt-bottom

    abbr --add c clear
    abbr --add q exit
    
    abbr --add l 'ls -lhAtr --color=always'
    
    abbr --add d dirh
    abbr --add nd nextd
    abbr --add pd prevd
    
    abbr --add utc 'date -u'
    
    abbr --add ag --position command --set-cursor=% 'rg --json % | delta'
    
    abbr --add g git
    abbr --add qg git
    abbr --add gl 'git l'
    abbr --add gs 'git s'
    
    abbr --add v nvim
    abbr --add vi nvim
    abbr --add nv nvim
    abbr --add vim nvim
    
    abbr --add em "nvim $HOME/code/nixos-dotfiles/macbook-pro-18-3-config.nix"
    
    abbr --add ek "nvim $HOME/code/nixos-dotfiles/kitty/.config/kitty/kitty.conf"
    abbr --add ef "nvim $HOME/code/nixos-dotfiles/fish/.config/fish/config.fish"
    abbr --add eb "nvim $HOME/code/nixos-dotfiles/fish/.config/fish/config.fish"
    abbr --add ev "nvim $HOME/code/nixos-dotfiles/nvim/nvim.nix"
    abbr --add eg "nvim $HOME/code/nixos-dotfiles/git/.gitconfig"

    abbr --add zs 'zola serve'

    source ~/.open_ai_api_key.fish

    fish_add_path --global "$HOME/code/dotfiles/bin"
end

function __should_na --on-event fish_prompt
    echo $history[1] | grep -Ev '(^hh$|^sd|^1.$)' >> ~/.config/fish/hh.history
end

# Fixes order of $PATH entries in fish shell
# Based on https://github.com/LnL7/nix-darwin/issues/122#issuecomment-1345383219
if test (uname) = Darwin
    fish_add_path --prepend --global "$HOME/.local/bin"
    fish_add_path --prepend --global "$HOME/bin"
    fish_add_path --prepend --global /run/current-system/sw/bin
    fish_add_path --prepend --global /nix/var/nix/profiles/default/bin
end
