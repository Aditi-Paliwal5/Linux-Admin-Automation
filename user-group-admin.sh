
#!/bin/bash

set -u

BASE_DIR="/opt/linux-admin-task"
ADD_CSV="$BASE_DIR/add-user-db.csv"
DELETE_USER_CSV="$BASE_DIR/delete-user-db.csv"
DELETE_GROUP_CSV="$BASE_DIR/delete-group-db.csv"
LOG_FILE="$BASE_DIR/user-group-admin.log"

# Root access is required for user and group administration.
if [[ $EUID -ne 0 ]]; then
    echo "ERROR: Run this script with sudo or as root."
    exit 1
fi

# Write messages to both terminal and log file.
log() {
    echo "$(date '+%F %T') - $*" | tee -a "$LOG_FILE"
}

# Confirm that the requested CSV exists.
check_file() {
    if [[ ! -r "$1" ]]; then
        log "ERROR: Cannot read file: $1"
        return 1
    fi
}

add_users() {
    check_file "$ADD_CSV" || return 1

    while IFS=, read -r user group || [[ -n "${user:-}" ]]; do
        # Skip the CSV header and blank lines.
        [[ "${user:-}" == "User" ]] && continue
        [[ -z "${user//[[:space:]]/}" ]] && continue

        # Remove accidental spaces around CSV fields.
        user="${user//[[:space:]]/}"
        group="${group//[[:space:]]/}"

        # Reject invalid account names and group names.
        if [[ ! "$user" =~ ^[a-z_][a-z0-9_-]*[$]?$ ||
              ! "$group" =~ ^[a-z_][a-z0-9_-]*[$]?$ ]]; then
            log "ERROR: Invalid user/group entry: $user,$group"
            continue
        fi

        # Create the group only if it does not exist.
        if getent group "$group" > /dev/null; then
            log "Group already exists: $group"
        elif groupadd "$group"; then
            log "Group created: $group"
        else
            log "ERROR: Could not create group: $group"
            continue
        fi

        # Create a user with the specified primary group.
        if id "$user" > /dev/null 2>&1; then
            log "User already exists; skipped: $user"
        elif useradd -m -g "$group" "$user"; then
            log "User created: $user; primary group: $group"
        else
            log "ERROR: Could not create user: $user"
        fi
    done < "$ADD_CSV"
}

delete_users() {
    check_file "$DELETE_USER_CSV" || return 1

    while IFS=, read -r user; do
        [[ "${user:-}" == "User" ]] && continue
        [[ -z "${user//[[:space:]]/}" ]] && continue

        user="${user//[[:space:]]/}"

        if [[ ! "$user" =~ ^[a-z_][a-z0-9_-]*[$]?$ ]]; then
            log "ERROR: Invalid username: $user"
        elif id "$user" > /dev/null 2>&1; then
            if userdel "$user"; then
                log "User deleted; home directory retained if present: $user"
            else
                log "ERROR: Could not delete user: $user"
            fi
        else
            log "User does not exist; skipped: $user"
        fi
    done < "$DELETE_USER_CSV"
}

delete_groups() {
    check_file "$DELETE_GROUP_CSV" || return 1

    while IFS=, read -r group; do
        [[ "${group:-}" == "Group" ]] && continue
        [[ -z "${group//[[:space:]]/}" ]] && continue

        group="${group//[[:space:]]/}"

        if [[ ! "$group" =~ ^[a-z_][a-z0-9_-]*[$]?$ ]]; then
            log "ERROR: Invalid group name: $group"
            continue
        fi

        group_info=$(getent group "$group") || {
            log "Group does not exist; skipped: $group"
            continue
        }

        gid=$(echo "$group_info" | cut -d: -f3)

        # Do not delete a group used as a primary group.
        members=$(awk -F: -v gid="$gid" '$4 == gid {print $1}' /etc/passwd)

        if [[ -n "$members" ]]; then
            log "SKIPPED: $group is a primary group for: $members"
            continue
        fi

        if groupdel "$group"; then
            log "Group deleted: $group"
        else
            log "ERROR: Could not delete group: $group"
        fi
    done < "$DELETE_GROUP_CSV"
}

list_users_groups() {
    echo "========== LOCAL USER ACCOUNTS =========="
    getent passwd | awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}'

    echo
    echo "========== GROUPS =========="
    getent group
}

case "${1:-}" in
    add-users)
        add_users
        ;;
    delete-users)
        delete_users
        ;;
    delete-groups)
        delete_groups
        ;;
    list)
        list_users_groups
        ;;
    *)
        echo "Usage: sudo $0 {add-users|delete-users|delete-groups|list}"
        exit 1
        ;;
esac

