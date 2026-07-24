function fish_git_prompt --description 'Show git branch with abbreviated path segments'
    set -l branch (command git symbolic-ref --short HEAD 2>/dev/null)
    or return

    # Split branch into path segments
    set -l segments (string split / -- $branch)

    # Count segments
    set -l count (count $segments)

    # Build abbreviated path from all but the last segment
    set -l result ""
    for i in (seq 1 (math $count - 1))
        set -l seg $segments[$i]
        set result $result(string sub -l 1 -- $seg)/
    end

    # Append last segment (fully intact)
    set -l last_segment $segments[$count]

    # Truncate last segment if too long
    if test (string length $last_segment) -gt 20
        set last_segment (string sub -l 20 -- $last_segment)…
    end

    echo " ($result$last_segment)"
end
