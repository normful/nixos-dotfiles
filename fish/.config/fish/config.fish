# To create new aliases (not abbreviations):
# 1. `alias hello 'echo hello'`
# 2. `fs hello`

# `funced function_name` edits the file for the function.

set -U fish_greeting ""

if status is-interactive
    set -g fish_key_bindings fish_vi_key_bindings
    set --export HISTFILE ~/.config/fish/hh.history
    set --export HSTR_CONFIG hicolor,prompt-bottom
    set --export TELEMETRY_ENABLED false

    abbr --add c clear
    abbr --add q exit

    abbr --add l 'eza --classify=auto --color=always --icons=always --almost-all --group-directories-first --long --binary --smart-group --header --mounts --octal-permissions --no-permissions --git --sort time'

    abbr --add man 'batman'
    abbr --add catp 'prettybat'

    abbr --add d dirh
    abbr --add nd nextd
    abbr --add pd prevd

    abbr --add utc 'date -u'

    abbr --add ag --position command --set-cursor=% 'rg --json % | delta'

    abbr --add g git
    abbr --add qg git
    abbr --add gl 'git l'
    abbr --add gs 'git s'

    abbr --add n "nvim"
    abbr --add v "nvim"

    abbr --add em "nvim $HOME/code/nixos-dotfiles/macbook-pro-18-3-config.nix"

    abbr --add ek "nvim $HOME/code/nixos-dotfiles/kitty/.config/kitty/kitty.conf"
    abbr --add et "nvim $HOME/code/nixos-dotfiles/ghostty/.config/ghostty/config"
    abbr --add ew "nvim $HOME/code/nixos-dotfiles/wezterm/.config/wezterm/wezterm.lua"

    abbr --add ef "nvim $HOME/code/nixos-dotfiles/fish/.config/fish/config.fish"
    abbr --add eb "nvim $HOME/code/nixos-dotfiles/fish/.config/fish/config.fish"
    abbr --add ev "nvim $HOME/code/nixos-dotfiles/nvim/nvim.nix"
    abbr --add eg "nvim $HOME/code/nixos-dotfiles/git/.gitconfig"

    abbr --add es 'exercism submit'
    abbr --add gt 'gleam test'

    abbr --add zs 'zola serve'

    abbr --add dua 'dua interactive'

    abbr --add p1start "infisical run --projectId=todo1 --project-config-dir todo2 --env=dev --silent -- todo3"

    abbr --add cf 'cargo fmt'
    abbr --add cl 'cargo clippy'
    abbr --add ck 'cargo check'

    abbr --add cb 'cargo build'
    abbr --add cbr 'cargo build --release'

    abbr --add cr 'cargo run'
    abbr --add crr 'cargo run --release'

    abbr --add ct 'cargo test'
    abbr --add ctn 'cargo test -- --nocapture'

    abbr --add cdo 'cargo doc --open'

    fish_add_path --global "$HOME/code/dotfiles/bin"
    fish_add_path --global "$HOME/.codeium/windsurf/bin"
    fish_add_path --global "$HOME/.cargo/bin"

    source "$HOME/.api_keys.fish"
end

function __should_na --on-event fish_prompt
    echo $history[1] | grep -Ev '(^hh$|^sd|^1.$)' >> ~/.config/fish/hh.history
end

# Fixes order of $PATH entries in fish shell when using nix-darwin
# Based on https://github.com/LnL7/nix-darwin/issues/122#issuecomment-1345383219
if test (uname) = Darwin
    fish_add_path --prepend --global "$HOME/.local/bin"
    fish_add_path --prepend --global "$HOME/bin"
    fish_add_path --prepend --global /run/current-system/sw/bin
    fish_add_path --prepend --global /nix/var/nix/profiles/default/bin
end
