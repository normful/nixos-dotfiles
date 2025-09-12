function rgjson --description "Search JSON files with fastgron and ripgrep"
    fastgron $argv[1] | rg $argv[2..-1]
end
