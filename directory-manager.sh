
#!/bin/bash

set -u

BASE_DIR="/opt/linux-admin-task"
CSV_FILE="$BASE_DIR/directories.csv"
LOG_FILE="$BASE_DIR/directory-manager.log"

if [[ $EUID -ne 0 ]]; then
    echo "ERROR: Run this script with sudo or as root."
    exit 1
fi

log() {
    echo "$(date '+%F %T') - $*" | tee -a "$LOG_FILE"
}

if [[ ! -r "$CSV_FILE" ]]; then
    log "ERROR: Cannot read CSV: $CSV_FILE"
    exit 1
fi

while IFS=, read -r folder permission || [[ -n "${folder:-}" ]]; do

    # Skip the header and empty rows.
    [[ "${folder:-}" == "Folder" ]] && continue
    [[ -z "${folder//[[:space:]]/}" ]] && continue

    # Remove accidental spaces around fields.
    folder="${folder#"${folder%%[![:space:]]*}"}"
    folder="${folder%"${folder##*[![:space:]]}"}"
    permission="${permission//[[:space:]]/}"

    # Accept only absolute paths under /home.
    if [[ "$folder" != /home/* || "$folder" == *"/../"* ||
          "$folder" == */.. || "$folder" == *"//"* ]]; then
        log "ERROR: Invalid folder path: $folder"
        continue
    fi

    # Accept only three-digit octal permissions.
    if [[ ! "$permission" =~ ^[0-7]{3}$ ]]; then
        log "ERROR: Invalid permission for $folder: $permission"
        continue
    fi

    if [[ -d "$folder" ]]; then
        log "Directory already exists: $folder"
    elif [[ -e "$folder" ]]; then
        log "ERROR: Path exists but is not a directory: $folder"
        continue
    elif mkdir -p -- "$folder"; then
        log "Directory created: $folder"
    else
        log "ERROR: Could not create directory: $folder"
        continue
    fi

    if chmod "$permission" -- "$folder"; then
        log "Permission set to $permission on $folder"
    else
        log "ERROR: Could not set permissions on $folder"
    fi

done < "$CSV_FILE"

log "Directory management run completed."

