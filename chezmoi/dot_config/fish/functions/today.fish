function today --description 'Navigate to alcove and manage today\'s daily note (fast via daily binary)'
    set -l original_dir (pwd)

    if test ! -d ~/code/alcove
        echo "Directory ~/code/alcove does not exist" >&2
        return 1
    end

    cd ~/code/alcove

    # Fast path via `daily` (~20ms vs `zk list todays_daily` ~2.6s). 0-or-1 per day (JST).
    # `zk today` finds today or creates it via `zk new --group daily`; prints TSV path<TAB>title<TAB>created.
    set -l out (zk today 2>&1)
    set -l code $status

    if test $code -ne 0
        echo "Failed to get today's note: $out" >&2
        cd $original_dir
        return 1
    end

    set -l note_path (echo $out | cut -f1 | string trim)
    if test -z "$note_path"
        echo "Failed to parse today's note path: $out" >&2
        cd $original_dir
        return 1
    end

    if test -f "$note_path"
        # Use $EDITOR from .zk/config.toml (nvim) if set, else nvim
        if set -q EDITOR
            $EDITOR "$note_path"
        else
            nvim "$note_path"
        end
    else
        # Fallback: let zk handle opening (e.g. if DB lag, path from zk new may be relative)
        # Try via explicit path, then via filter
        if set -q EDITOR
            $EDITOR "$note_path" 2>/dev/null; or zk edit todays_daily
        else
            nvim "$note_path" 2>/dev/null; or zk edit todays_daily
        end
    end

    cd $original_dir
end
