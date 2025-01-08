function t --description 'Run eza in tree mode'
    eza --tree --classify=auto --color=always --icons=always --almost-all --git-ignore --long --no-permissions --bytes --no-user --no-time --total-size $argv
end
