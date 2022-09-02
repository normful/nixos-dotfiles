function t --description 'Run tree with colors and ignore typical big and irrelevant directories'
    tree -N -ashFC -I ".git|node_modules" $argv
end
