function yesterday --description 'Navigate to alcove and manage yesterday\'s daily note (fast via daily binary)'
    set -l original_dir (pwd)

    if test ! -d ~/code/alcove
        echo "Directory ~/code/alcove does not exist" >&2
        return 1
    end

    cd ~/code/alcove

    # Fast path via `daily` (~14-22ms vs `zk list yesterdays_daily` ~2.6s). Never creates.
    set -l out (zk yesterday 2>&1)
    set -l code $status

    if test $code -ne 0
        set_color purple
        echo "No daily note found for yesterday."
        set_color yellow
        echo "Recent daily notes:"
        set_color normal
        echo
        # `zk recent` is the daily binary's `recent` alias (~21ms) vs `zk list dailies` (~2.5s)
        zk recent
        cd $original_dir
        return 1
    end

    set -l note_path (echo $out | cut -f1 | string trim)
    if test -z "$note_path"
        echo "Failed to parse yesterday's note path: $out" >&2
        cd $original_dir
        return 1
    end

    if test -f "$note_path"
        if set -q EDITOR
            $EDITOR "$note_path"
        else
            nvim "$note_path"
        end
    else
        # Fallback to zk filter if path stale
        zk edit yesterdays_daily
    end

    cd $original_dir
end
