if status is-interactive
    set -x HISTFILE ~/.config/fish/hh.history
    set -x HSTR_CONFIG hicolor,prompt-bottom
end

function __should_na --on-event fish_prompt
   echo $history[1] | grep -Ev '(^hh$|^sd|^1.$)' >> ~/.config/fish/hh.history
end
