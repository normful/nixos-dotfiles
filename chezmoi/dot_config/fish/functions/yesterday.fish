function yesterday --description 'Navigate to alcove and manage yesterday'\''s daily note'
    set -l original_dir (pwd)

    if test ! -d ~/code/alcove
        echo "Directory ~/code/alcove does not exist" >&2
        return 1
    end

    cd ~/code/alcove

    set -l output (env PAGER=cat zk list yesterdays_daily 2>&1)

    if echo $output | string match -q "*Found 0 note*"
        set_color purple
        echo "No daily note found for yesterday."
        set_color yellow
        echo "Recent daily notes:"
        set_color normal
        echo
        zk list dailies
    else
        zk edit yesterdays_daily
    end

    cd $original_dir
end
