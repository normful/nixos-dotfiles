#!/bin/bash

# Script to sync configuration files from application subdirectories to chezmoi structure
# Copies all dotfiles and dotdirs from each subdir to ./chezmoi/dot_* structure

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# List of subdirectories to process
SUBDIRS=(
    "bat"
    "cargo"
    "claude"
    "fish"
    "ghostty"
    "git"
    "helix"
    "htop"
    "karabiner"
    "kitty"
    "lftp"
    "nvim"
    "procs"
    "scripts"
    "warp"
    "wezterm"
    "yazi"
)

# Base paths
CHEZMOI_DIR="./chezmoi"
CONFIG_DIR="$CHEZMOI_DIR/dot_config"

echo -e "${BLUE}Starting configuration sync to chezmoi structure${NC}"
echo "======================================================="

# Create base directories if they don't exist
mkdir -p "$CONFIG_DIR"

# Function to sync a single subdirectory
sync_subdir() {
    local subdir="$1"
    local source_dir="./$subdir"

    echo -e "\n${BLUE}Processing: $subdir${NC}"
    echo "-------------------"

    # Check if source directory exists
    if [[ ! -d "$source_dir" ]]; then
        echo -e "${YELLOW}⚠  Source directory '$source_dir' does not exist, skipping${NC}"
        return 0
    fi

    # Find all dotfiles and dotdirs in the subdirectory
    local found_items=0

    # Process all items starting with dot in the subdirectory
    for item in "$source_dir"/.*; do
        # Skip . and .. directories
        if [[ "$(basename "$item")" == "." || "$(basename "$item")" == ".." ]]; then
            continue
        fi

        # Skip if the glob didn't match anything
        if [[ ! -e "$item" ]]; then
            continue
        fi

        found_items=1
        local basename_item="$(basename "$item")"

        # Convert .something to dot_something
        local chezmoi_name="${basename_item/#./dot_}"
        local dest_path

        # Determine destination path based on the pattern
        if [[ "$basename_item" == ".config" ]]; then
            # Special case: .config directories - need to handle nested structure
            dest_path="$CONFIG_DIR/$subdir"
            echo -e "${GREEN}✓${NC} Processing .config directory: $item → $dest_path"
            
            # Create parent directory if needed
            mkdir -p "$(dirname "$dest_path")"
            
            # Remove destination first to ensure clean copy
            rm -rf "$dest_path"
            mkdir -p "$dest_path"
            
            # Check if there's a subdirectory with the same name as the parent
            local config_subdir="$item/$subdir"
            if [[ -d "$config_subdir" ]]; then
                # Copy contents of the nested subdir (e.g., fish/.config/fish/* → chezmoi/dot_config/fish/)
                echo -e "${GREEN}  └─${NC} Found nested $subdir directory, copying its contents"
                if ls "$config_subdir"/* > /dev/null 2>&1; then
                    cp -r "$config_subdir"/* "$dest_path"/
                fi
                # Also copy hidden files if they exist
                if ls "$config_subdir"/.* > /dev/null 2>&1; then
                    for hidden in "$config_subdir"/.*; do
                        if [[ "$(basename "$hidden")" != "." && "$(basename "$hidden")" != ".." ]]; then
                            cp -r "$hidden" "$dest_path"/
                        fi
                    done
                fi
            else
                # No nested subdir, copy all contents of .config
                echo -e "${GREEN}  └─${NC} No nested directory, copying all .config contents"
                if ls "$item"/* > /dev/null 2>&1; then
                    cp -r "$item"/* "$dest_path"/
                fi
                # Also copy hidden files if they exist
                if ls "$item"/.* > /dev/null 2>&1; then
                    for hidden in "$item"/.*; do
                        if [[ "$(basename "$hidden")" != "." && "$(basename "$hidden")" != ".." ]]; then
                            cp -r "$hidden" "$dest_path"/
                        fi
                    done
                fi
            fi
        else
            # Other dotfiles/dirs go to chezmoi root with dot_ prefix
            dest_path="$CHEZMOI_DIR/$chezmoi_name"
            echo -e "${GREEN}✓${NC} Copying: $item → $dest_path"
            
            # Create parent directory if needed
            mkdir -p "$(dirname "$dest_path")"

            # Copy the item (works for both files and directories)
            if [[ -d "$item" ]]; then
                # For directories, use cp -r and remove destination first to ensure clean copy
                rm -rf "$dest_path"
                cp -r "$item" "$dest_path"
            else
                # For files, direct copy
                cp "$item" "$dest_path"
            fi
        fi
    done

    if [[ $found_items -eq 0 ]]; then
        echo -e "${YELLOW}⚠  No dotfiles or dotdirs found in '$source_dir'${NC}"
    fi
}

# Process each subdirectory
for subdir in "${SUBDIRS[@]}"; do
    sync_subdir "$subdir"
done

echo -e "\n${GREEN}✅ Configuration sync completed!${NC}"
echo "======================================================="
echo -e "${BLUE}Summary:${NC}"
echo "• All dotfiles and dotdirs have been copied to $CHEZMOI_DIR"
echo "• .config directories → $CONFIG_DIR/<subdir>"
echo "• Other dotfiles/dirs → $CHEZMOI_DIR/dot_<name>"
