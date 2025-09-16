function t --description 'Run eza in tree mode (to replace tree)'
    eza --tree --classify=auto --color=always --almost-all --long --no-permissions --bytes --no-user --total-size $argv
end
