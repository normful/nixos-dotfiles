function fish_prompt --description 'Write out the prompt'
    set -l last_status $status
    set -l normal (set_color normal)
    set -l status_color (set_color brgreen)
    set -l cwd_color (set_color $fish_color_cwd)
    set -l vcs_color (set_color brpurple)
    set -l prompt_status ""

    # Color the prompt differently when we're root
    set -l suffix ' >'
    if functions -q fish_is_root_user; and fish_is_root_user
        if set -q fish_color_cwd_root
            set cwd_color (set_color $fish_color_cwd_root)
        end
        set suffix ' #'
    end

    # Color the prompt in red on error
    if test $last_status -ne 0
        set status_color (set_color $fish_color_error)
        set prompt_status $status_color "[" $last_status "]" $normal
    end

    set -l current_hostname (prompt_hostname)
    set -l hostname_color (set_color EAB308) # gold for non-cyan hosts
    if test "$current_hostname" = "cyan"
        set hostname_color (set_color cyan)
    end

    echo -s $hostname_color $current_hostname $normal ' ' $cwd_color (prompt_pwd --full-length-dirs=2 --dir-length=1) $vcs_color (fish_git_prompt) $normal $prompt_status $status_color $suffix $normal ' '
end
