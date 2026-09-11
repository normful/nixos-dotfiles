if status is-interactive
    if command -v chezmoi >/dev/null 2>&1
        abbr --add czadd 'chezmoi add'
        abbr --add cze   'chezmoi edit'
        abbr --add czd   'chezmoi diff'
        abbr --add cza   'chezmoi apply'
        abbr --add czs   'chezmoi status'
        abbr --add czi   'chezmoi init'
    end
end
