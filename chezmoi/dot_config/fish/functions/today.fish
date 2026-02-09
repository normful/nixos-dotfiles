function today --description 'Navigate to alcove and manage today'\''s daily note'
    set -l original_dir (pwd)

    if test ! -d ~/code/alcove
        echo "Directory ~/code/alcove does not exist" >&2
        return 1
    end

    cd ~/code/alcove

    set -l output (env PAGER=cat zk list todays_daily 2>&1)

    if echo $output | string match -q "*Found 0 note*"
        zk start_today
    else
        zk edit todays_daily
    end

    cd $original_dir
end
