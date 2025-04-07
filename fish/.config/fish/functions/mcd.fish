function mcd --description "Creates a configuration directory in nixos-dotfiles, copies existing config files, and updates the stow/unstow Makefile targets"
    set -l tool_name "$argv[1]"

    if test -z "$tool_name"
        echo "Error: Please provide a directory name as an argument."
        return 1
    end

    set -l dotfiles_path ~/code/nixos-dotfiles
    set -l tool_config_dir "$dotfiles_path/$tool_name/.config/$tool_name"
    set -l source_config_dir ~/.config/$tool_name

    cd $dotfiles_path

    # Create the configuration directory
    mkdir -p "$tool_config_dir"
    cd $tool_config_dir

    touch "$tool_config_dir/.gitkeep"
    echo "Created configuration directory: $tool_config_dir"

    # Check if there are files in the source directory
    if test -d "$source_config_dir" && count (find "$source_config_dir" -type f) > /dev/null
        # Copy files recursively from source to target
        echo "Copying existing configuration files from $source_config_dir to $tool_config_dir"
        cp -rv "$source_config_dir/"* "$tool_config_dir/"
    else
        echo "No existing configuration files to copy from $source_config_dir"
    end

    set -l makefile_path "$dotfiles_path/Makefile"

    # Check if Makefile exists
    if not test -f $makefile_path
        echo "Error: Makefile not found"
        return 1
    end

    # Create temporary file
    set -l temp_file (mktemp)

    # Variables to track modification status
    set -l stow_modified false
    set -l unstow_modified false

    # Read the Makefile line by line
    while read -l line
        if string match -qr "^\tstow .* -S " $line && not $stow_modified
            # This is the stow command line - append the new tool
            echo "$line $tool_name" >> $temp_file
            set stow_modified true
        else if string match -qr "^\tstow .* -D " $line && not $unstow_modified
            # This is the unstow command line - append the new tool
            echo "$line $tool_name" >> $temp_file
            set unstow_modified true
        else
            # Any other line - keep as is
            echo $line >> $temp_file
        end
    end < $makefile_path

    # Check if both targets were modified
    if not $stow_modified || not $unstow_modified
        echo "Error: Could not find both stow and unstow targets in Makefile"
        rm $temp_file
        return 1
    end

    # Move the temporary file to the Makefile
    mv $temp_file $makefile_path

    echo "Added '$tool_name' to stow and unstow targets in Makefile"
end
