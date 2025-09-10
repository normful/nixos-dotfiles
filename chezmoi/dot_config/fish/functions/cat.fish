function cat --description 'Replaces cat with bat'
    type -fq bat
    and command bat $argv
    or  command cat $argv
end
