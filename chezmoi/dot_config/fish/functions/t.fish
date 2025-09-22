function t --description 'print file tree'
    tree -s -h -D --timefmt='%Y-%m-%d %H:%M' $argv
end
