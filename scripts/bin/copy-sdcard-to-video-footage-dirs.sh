#!/run/current-system/sw/bin/bash

# --- Script Globals & Configuration ---
DEFAULT_SOURCE_DIR="/Volumes/extreme512/DCIM/Camera01"
DEST_BASE_DIR="$HOME/Videos/Raw-Footage"
DEFAULT_DESC_WORD="Footage"
MIN_RSYNC_MAJOR=3
MIN_RSYNC_MINOR=1

# Bash & Rsync Version Info (populated by checks)
BASH_MAJOR_VERSION=0
RSYNC_MAJOR=0
RSYNC_MINOR=0
RSYNC_PATCH=""

# Data structures populated during script execution
declare -A date_info
declare -a unique_sorted_yyyymmdd_dates
declare -a files_to_copy_source_paths
declare -a files_to_copy_target_dates
declare -a files_to_copy_filenames
declare -a files_to_copy_dest_paths

# --- Colors for output ---
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
CYAN=$(tput setaf 6)
MAGENTA=$(tput setaf 5)
NC=$(tput sgr0)

# --- Logging Helper Functions ---
_log_base() {
    local color="$1"
    shift
    local prefix="$1"
    shift
    echo -e "${color}[${prefix}]${NC} $*"
}
log_info() { _log_base "$BLUE" "INFO" "$@"; }
log_success() { _log_base "$GREEN" "SUCCESS" "$@"; }
log_warning() { _log_base "$YELLOW" "WARNING" "$@"; }
log_error() { _log_base "$RED" "ERROR" "$@" >&2; }
log_plan() { _log_base "$CYAN" "PLAN" "$@"; }
log_dryrun() { _log_base "$MAGENTA" "DRY RUN" "$@"; }

# --- Prerequisite Check Functions ---
check_bash_version() {
    BASH_MAJOR_VERSION=${BASH_VERSINFO[0]}
    if ((BASH_MAJOR_VERSION < 4)); then
        log_error "This script requires Bash version 4.0 or higher. Found: $BASH_VERSION"
        exit 1
    fi
}

check_rsync_version() {
    local rsync_version_string
    rsync_version_string=$(rsync --version 2>/dev/null | head -n 1)

    if [[ -z "$rsync_version_string" ]]; then
        log_error "rsync command not found or failed to execute."
        return 1
    fi

    if [[ "$rsync_version_string" =~ rsync\ +version\ +([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
        RSYNC_MAJOR="${BASH_REMATCH[1]}"
        RSYNC_MINOR="${BASH_REMATCH[2]}"
        RSYNC_PATCH="${BASH_REMATCH[3]}"
    else
        log_error "Could not parse rsync version from: $rsync_version_string"
        return 1
    fi

    if ! ((${RSYNC_MAJOR} > ${MIN_RSYNC_MAJOR} || \
          (${RSYNC_MAJOR} == ${MIN_RSYNC_MAJOR} && ${RSYNC_MINOR} >= ${MIN_RSYNC_MINOR}))); then
        log_error "This script requires rsync version ${MIN_RSYNC_MAJOR}.${MIN_RSYNC_MINOR}.0 or higher."
        log_error "Found rsync version: ${RSYNC_MAJOR}.${RSYNC_MINOR}.${RSYNC_PATCH}"
        return 1
    fi
    return 0
}

# --- Phase 1: Scanning, Planning & Prompting Helper Functions ---
_get_all_yyyymmdd_from_source_filenames() {
    local source_dir="$1"
    local -a all_dates_found=()
    local -a temp_files=()

    mapfile -d $'\0' -t temp_files < <(
        find "$source_dir" -maxdepth 1 -type f -print0
    )

    if [ ${#temp_files[@]} -eq 0 ]; then
        log_warning "No files found in source: $source_dir"
        return 1
    fi

    for filepath in "${temp_files[@]}"; do
        local filename
        filename=$(basename "$filepath")
        if [[ "$filename" =~ ^[A-Z]+_([0-9]{8})_.* ]]; then
            all_dates_found+=("${BASH_REMATCH[1]}")
        fi
    done

    if ((${#all_dates_found[@]} > 0)); then
        mapfile -t unique_sorted_yyyymmdd_dates < <(
            printf "%s\n" "${all_dates_found[@]}" | sort -u
        )
    fi
    return 0
}

_prompt_for_date_descriptions() {
    if ((${#unique_sorted_yyyymmdd_dates[@]} == 0 )); then
        return
    fi

    log_info "Gathering descriptions for unique dates (chronological order):"
    for date_yyyymmdd in "${unique_sorted_yyyymmdd_dates[@]}"; do
        local year month day formatted_date_key target_folder_path description short_desc dest_subdir_name
        local -a existing_folders_for_date

        year="${date_yyyymmdd:0:4}"
        month="${date_yyyymmdd:4:2}"
        day="${date_yyyymmdd:6:2}"
        formatted_date_key="$year-$month-$day"

        date_info["${formatted_date_key}_files_to_copy_count"]=0
        date_info["${formatted_date_key}_files_to_skip_count"]=0

        shopt -s nullglob
        existing_folders_for_date=("$DEST_BASE_DIR/${formatted_date_key}_"*)
        shopt -u nullglob

        if [ ${#existing_folders_for_date[@]} -gt 0 ] && [ -d "${existing_folders_for_date[0]}" ]; then
            target_folder_path="${existing_folders_for_date[0]}"
            description="$(basename "$target_folder_path" | sed "s/^${formatted_date_key}_//")"
            log_info "Date $formatted_date_key: Using existing folder '$(basename "$target_folder_path")' (Desc: '$description')"
            date_info["${formatted_date_key}_path"]="$target_folder_path"
            date_info["${formatted_date_key}_status"]="existing"
            date_info["${formatted_date_key}_desc"]="$description"
        else
            read -r -p "${YELLOW}Enter Short-Description for date $formatted_date_key (or press Enter for '$DEFAULT_DESC_WORD'): ${NC}" short_desc
            if [ -z "$short_desc" ]; then
                short_desc="$DEFAULT_DESC_WORD"
            fi
            dest_subdir_name="${formatted_date_key}_${short_desc}"
            target_folder_path="$DEST_BASE_DIR/$dest_subdir_name"
            date_info["${formatted_date_key}_path"]="$target_folder_path"
            date_info["${formatted_date_key}_status"]="new_proposed"
            date_info["${formatted_date_key}_desc"]="$short_desc"
        fi
    done
    echo
}

_build_file_copy_lists_and_counts() {
    local source_dir="$1"
    local -a sorted_source_files=()

    mapfile -d $'\0' -t sorted_source_files < <(
        find "$source_dir" -maxdepth 1 -type f -print0 | sort -zV
    )

    if [ ${#sorted_source_files[@]} -eq 0 ]; then
        return
    fi

    log_info "Analyzing files and preparing copy plan..."
    for filepath in "${sorted_source_files[@]}"; do
        local filename date_yyyymmdd_file year_file month_file day_file formatted_date_file_key dest_folder_path dest_full_path
        filename=$(basename "$filepath")

        if [[ "$filename" =~ ^[A-Z]+_([0-9]{8})_.* ]]; then
            date_yyyymmdd_file="${BASH_REMATCH[1]}"
            year_file="${date_yyyymmdd_file:0:4}"
            month_file="${date_yyyymmdd_file:4:2}"
            day_file="${date_yyyymmdd_file:6:2}"
            formatted_date_file_key="$year_file-$month_file-$day_file"

            if [[ -z "${date_info[${formatted_date_file_key}_path]}" ]]; then
                log_error "CRITICAL: Date $formatted_date_file_key for '$filename' not processed. Logic error. Skipping."
                continue
            fi

            dest_folder_path="${date_info[${formatted_date_file_key}_path]}"
            dest_full_path="${dest_folder_path}/${filename}"

            files_to_copy_source_paths+=("$filepath")
            files_to_copy_target_dates+=("$formatted_date_file_key")
            files_to_copy_filenames+=("$filename")
            files_to_copy_dest_paths+=("$dest_full_path")

            if [ -e "$dest_full_path" ]; then
                ((date_info[${formatted_date_file_key}_files_to_skip_count]++))
            else
                ((date_info[${formatted_date_file_key}_files_to_copy_count]++))
            fi
        else
            log_warning "File '$filename' in source does not match YYYYMMDD pattern. Skipping."
        fi
    done

    if [ ${#files_to_copy_source_paths[@]} -eq 0 ] && [ ${#sorted_source_files[@]} -gt 0 ]; then
        log_warning "No files matching pattern found for copy plan, though other files exist."
    fi
    echo
}

# --- Phase 2: Plan Display Function ---
display_copy_plan() {
    log_info "Review the plan:"
    echo "--------------------------------------------------"
    log_plan "Destination Folders (chronological order of dates):"

    for date_yyyymmdd_key_plan in "${unique_sorted_yyyymmdd_dates[@]}"; do
        local formatted_date_plan_key copy_count skip_count folder_path folder_status folder_desc folder_action_msg

        formatted_date_plan_key="${date_yyyymmdd_key_plan:0:4}-${date_yyyymmdd_key_plan:4:2}-${date_yyyymmdd_key_plan:6:2}"
        copy_count="${date_info[${formatted_date_plan_key}_files_to_copy_count]}"
        skip_count="${date_info[${formatted_date_plan_key}_files_to_skip_count]}"

        if (( copy_count == 0 && skip_count == 0 )); then
            continue
        fi

        folder_path="${date_info[${formatted_date_plan_key}_path]}"
        folder_status="${date_info[${formatted_date_plan_key}_status]}"
        folder_desc="${date_info[${formatted_date_plan_key}_desc]}"
        folder_action_msg=""

        if [[ "$folder_status" == "new_proposed" ]]; then
            if [ -d "$folder_path" ]; then
                folder_action_msg="Use existing folder"
                date_info["${formatted_date_plan_key}_status"]="existing_by_user_input" # Update status
            else
                folder_action_msg="${GREEN}Create new folder${NC}"
            fi
        elif [[ "$folder_status" == "existing" || "$folder_status" == "existing_by_user_input" ]]; then
            folder_action_msg="Use existing folder"
        fi

        log_plan "  - $folder_action_msg: '$folder_path' (Desc: '$folder_desc')"
        log_plan "    Files to copy: $copy_count, Files to skip (exist): $skip_count"
    done
    echo

    log_plan "Total files to process: ${#files_to_copy_source_paths[@]}"
    local total_to_copy=0
    local total_to_skip=0

    for date_key in "${!date_info[@]}"; do
        if [[ "$date_key" == *"_files_to_copy_count" ]]; then
            total_to_copy=$((total_to_copy + date_info[$date_key]))
        elif [[ "$date_key" == *"_files_to_skip_count" ]]; then
            total_to_skip=$((total_to_skip + date_info[$date_key]))
        fi
    done

    log_plan "Overall: ${GREEN}$total_to_copy files will be copied${NC}, ${YELLOW}$total_to_skip files will be skipped (already exist)${NC}."
    echo "--------------------------------------------------"
}

# --- Phase 3: Execution Helper Functions ---
_create_target_folders() {
    log_info "Creating destination folders (chronological order)..."
    local -a created_folders_this_run=()

    for date_yyyymmdd_key_exec in "${unique_sorted_yyyymmdd_dates[@]}"; do
        local formatted_date_exec_key copy_count skip_count folder_path folder_status is_handled
        formatted_date_exec_key="${date_yyyymmdd_key_exec:0:4}-${date_yyyymmdd_key_exec:4:2}-${date_yyyymmdd_key_exec:6:2}"
        copy_count="${date_info[${formatted_date_exec_key}_files_to_copy_count]}"
        skip_count="${date_info[${formatted_date_exec_key}_files_to_skip_count]}"

        if (( copy_count == 0 && skip_count == 0 )); then
            continue
        fi

        folder_path="${date_info[${formatted_date_exec_key}_path]}"
        folder_status="${date_info[${formatted_date_exec_key}_status]}"

        is_handled=0
        for cf_path in "${created_folders_this_run[@]}"; do
            if [[ "$cf_path" == "$folder_path" ]]; then
                is_handled=1
                break
            fi
        done
        if [[ $is_handled -eq 1 ]]; then
            continue
        fi

        local create_it=0
        # Determine if folder should be created based on status and existence
        if [[ "$folder_status" == "new_proposed" ]] && [ ! -d "$folder_path" ]; then
            create_it=1
        elif [[ "$folder_status" == "existing_by_user_input" ]] && [ ! -d "$folder_path" ]; then
            create_it=1
        fi

        if [[ $create_it -eq 1 ]]; then
            log_info "Creating folder: $folder_path"
            mkdir -p "$folder_path"
            if [ $? -ne 0 ]; then
                log_error "Failed to create: $folder_path."
            else
                log_success "Created: $folder_path"
                created_folders_this_run+=("$folder_path")
            fi
        elif [ -d "$folder_path" ]; then
            # Folder already exists and we are not trying to create it, or it was already handled.
            # Add to list of folders that are confirmed to exist for rsync.
            created_folders_this_run+=("$folder_path")
        fi
    done
    echo
}

_perform_rsync_batches() {
    local -A rsync_groups
    local num_planned_to_copy_total=0
    local num_planned_to_skip_total=0
    local num_failed_batches_total=0

    for date_key in "${!date_info[@]}"; do
        if [[ "$date_key" == *"_files_to_copy_count" ]]; then
            num_planned_to_copy_total=$((num_planned_to_copy_total + date_info[$date_key]))
        elif [[ "$date_key" == *"_files_to_skip_count" ]]; then
            num_planned_to_skip_total=$((num_planned_to_skip_total + date_info[$date_key]))
        fi
    done

    log_info "Preparing files for batched rsync..."
    for i in "${!files_to_copy_source_paths[@]}"; do
        local src_path date_key dest_folder_path
        src_path="${files_to_copy_source_paths[$i]}"
        date_key="${files_to_copy_target_dates[$i]}"
        dest_folder_path="${date_info[${date_key}_path]}"

        if [ -d "$dest_folder_path" ]; then
            rsync_groups["$dest_folder_path"]+="${src_path}"$'\n'
        else
            log_warning "Dest folder '$dest_folder_path' for '$(basename "$src_path")' not valid. Skipping."
        fi
    done

    log_info "Starting rsync operations..."
    for dest_folder in "${!rsync_groups[@]}"; do
        local -a sf_this_dest
        local rsync_exit_code

        IFS=$'\n' read -r -d '' -a sf_this_dest < <(printf '%s' "${rsync_groups[$dest_folder]}" && printf '\0')

        if [ ${#sf_this_dest[@]} -eq 0 ]; then
            continue
        fi

        log_info "Rsync: ${#sf_this_dest[@]} file(s) to '$dest_folder/'"
        log_info "Rsync progress for '$dest_folder/' will appear below:"

        rsync -a --progress --ignore-existing "${sf_this_dest[@]}" "$dest_folder/"
        rsync_exit_code=$?

        # Add a newline for cleaner separation after rsync's potentially multi-line progress
        echo

        if [ $rsync_exit_code -eq 0 ]; then
            log_success "Rsync batch to '$dest_folder/' completed successfully."
        else
            log_error "Rsync failed (exit code $rsync_exit_code) for batch to '$dest_folder'."
            log_error "Check rsync output above for details."
            ((num_failed_batches_total++))
        fi
    done
    echo

    log_info "Final Summary of rsync operations (based on pre-flight plan):"
    log_success "Files planned for copy: $num_planned_to_copy_total"
    log_warning "Files planned to be skipped (pre-existing): $num_planned_to_skip_total"

    if [ $num_failed_batches_total -gt 0 ]; then
        log_error "Rsync batches with errors: $num_failed_batches_total (some files in these batches may not have been processed as planned)"
    else
        log_success "All rsync batches appeared to complete without error codes."
    fi
}

execute_dry_run_operations() {
    log_info "Starting Dry Run..."
    log_dryrun "Base destination: $DEST_BASE_DIR (checked by mkdir -p)"
    echo

    log_dryrun "Destination folders actions:"
    local -a dry_run_folders_handled=()

    for date_yyyymmdd_key_exec in "${unique_sorted_yyyymmdd_dates[@]}"; do
        local formatted_date_exec_key copy_count skip_count folder_path folder_status is_handled
        formatted_date_exec_key="${date_yyyymmdd_key_exec:0:4}-${date_yyyymmdd_key_exec:4:2}-${date_yyyymmdd_key_exec:6:2}"
        copy_count="${date_info[${formatted_date_exec_key}_files_to_copy_count]}"
        skip_count="${date_info[${formatted_date_exec_key}_files_to_skip_count]}"

        if (( copy_count == 0 && skip_count == 0 )); then
            continue
        fi

        folder_path="${date_info[${formatted_date_exec_key}_path]}"
        folder_status="${date_info[${formatted_date_exec_key}_status]}"

        is_handled=0
        for df_path in "${dry_run_folders_handled[@]}"; do
            if [[ "$df_path" == "$folder_path" ]]; then
                is_handled=1
                break
            fi
        done
        if [[ $is_handled -eq 1 ]]; then
            continue
        fi

        # Determine the dry-run action message based on status and existence
        local log_would_create=0
        if [[ "$folder_status" == "new_proposed" ]] && [ ! -d "$folder_path" ]; then
            log_would_create=1
        elif [[ "$folder_status" == "existing_by_user_input" ]] && [ ! -d "$folder_path" ]; then
            log_would_create=1
        fi

        if [[ $log_would_create -eq 1 ]]; then
            log_dryrun "  - Would create: $folder_path"
            dry_run_folders_handled+=("$folder_path")
        elif [ -d "$folder_path" ]; then
            log_dryrun "  - Would use existing: $folder_path"
            dry_run_folders_handled+=("$folder_path")
        else
            local exists_as_dir_str="no"
            if [ -d "$folder_path" ]; then # This condition will be false if we reach here
                exists_as_dir_str="yes"
            elif [ -f "$folder_path" ]; then
                 exists_as_dir_str="no (path is a file)"
            elif [ -e "$folder_path" ]; then
                 exists_as_dir_str="no (path exists but not as a directory)"
            fi
            log_dryrun "  - Path status unclear: $folder_path (status: $folder_status, exists as dir: $exists_as_dir_str)"
        fi
    done
    echo

    log_dryrun "Rsync operations (simulated):"
    local -A dry_run_rsync_groups

    for i in "${!files_to_copy_source_paths[@]}"; do
        local src_path date_key dest_folder_path
        src_path="${files_to_copy_source_paths[$i]}"
        date_key="${files_to_copy_target_dates[$i]}"
        dest_folder_path="${date_info[${date_key}_path]}"
        dry_run_rsync_groups["$dest_folder_path"]+="${src_path}"$'\n'
    done

    for dest_folder in "${!dry_run_rsync_groups[@]}"; do
        local -a sf_this_dest
        local rsync_dry_run_output

        IFS=$'\n' read -r -d '' -a sf_this_dest < <(printf '%s' "${dry_run_rsync_groups[$dest_folder]}" && printf '\0')
        if [ ${#sf_this_dest[@]} -eq 0 ]; then
            continue
        fi

        log_dryrun "  Would attempt rsync for ${#sf_this_dest[@]} file(s) to '$dest_folder/'"
        # Dry run rsync still captures its output to display it clearly.
        rsync_dry_run_output=$(rsync -avnih --ignore-existing "${sf_this_dest[@]}" "$dest_folder/" 2>&1)
        echo "$rsync_dry_run_output" | sed "s/^/${MAGENTA}    [rsync-dry-run]${NC} /"
    done
    echo
    log_info "Dry Run finished."
    echo "--------------------------------------------------"
}

execute_actual_copy_operations() {
    log_info "Starting actual copy operations..."
    mkdir -p "$DEST_BASE_DIR"
    if [ $? -ne 0 ]; then
        log_error "Could not create base dest dir. Aborting."
        return 1
    fi

    _create_target_folders
    _perform_rsync_batches
    return 0
}

# --- Main User Interaction and Script Flow ---
prompt_user_action_loop() {
    while true; do
        display_copy_plan
        echo

        local action_choice
        read -r -p "${YELLOW}Choose action: (P)roceed, (D)ry Run, (A)bort? [P/d/a]: ${NC}" action_choice

        case "$action_choice" in
            [Pp]* )
                echo
                execute_actual_copy_operations
                break
                ;;
            [Dd]* )
                echo
                execute_dry_run_operations
                ;;
            [Aa]* )
                log_info "Operation aborted by user."
                exit 0
                ;;
            * )
                log_warning "Invalid choice. Please enter P, D, or A."
                ;;
        esac
        echo # For spacing before next prompt or after dry run
    done
}

main() {
    check_bash_version
    if ! check_rsync_version; then
        exit 1
    fi

    local source_dir_arg="${1:-$DEFAULT_SOURCE_DIR}"
    if [ ! -d "$source_dir_arg" ]; then
        log_error "Source directory '$source_dir_arg' not found."
        exit 1
    fi

    log_info "Using source directory: $source_dir_arg"
    log_info "Using base destination directory: $DEST_BASE_DIR"
    log_info "Detected rsync version: ${RSYNC_MAJOR}.${RSYNC_MINOR}.${RSYNC_PATCH}"
    echo

    log_info "Phase 1: Scanning files, gathering descriptions, and preparing plan..."
    if ! _get_all_yyyymmdd_from_source_filenames "$source_dir_arg"; then
        # _get_all_yyyymmdd_from_source_filenames logs warnings if no files found.
        # Exiting 0 here is intentional if no processable files.
        exit 0
    fi

    if ((${#unique_sorted_yyyymmdd_dates[@]} == 0 )); then
        log_warning "No files matching date pattern found in source."
        exit 0
    fi

    _prompt_for_date_descriptions
    _build_file_copy_lists_and_counts "$source_dir_arg"

    if [ ${#files_to_copy_source_paths[@]} -eq 0 ]; then
        log_info "No files eligible for copying after analysis."
        exit 0
    fi

    prompt_user_action_loop
    log_info "Script finished."
}

main "$@"
