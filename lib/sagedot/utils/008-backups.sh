#!/usr/bin/env sh

# SAGEDOT_BACKUP_CREATED
# Used to track if a backup has been created
# WARNING: DO NOT SET THIS MANUALLY only set in `backups_create`
# NOTICE: Gets marked `readonly` after calling `backups_create`
SAGEDOT_BACKUP_CREATED=false
# SAGEDOT_BACKUP_ID
# The database ID of the current backup
# 0 is unset
# WARNING: DO NOT SET THIS MANUALLY only set in `backups_create`
# NOTICE: Gets marked `readonly` after calling `backups_create`
SAGEDOT_BACKUP_ID=0

#######################################
# Check to see if backups have been initialized
#
# Globals
#   SAGEDOT_CURRENT_PROFILE
#   SAGEDOT_BACKUP_CREATED
#   SAGEDOT_BACKUP_ID
#   SAGEDOT_RUNTIME
# Outputs:
#   Exits if SAGEDOT_CURRENT_PROFILE is invalid
#   Exits if SAGEDOT_BACKUP_ID is invalid
backups_check() {
    if [ "${SAGEDOT_CURRENT_PROFILE}" -eq 0 ]; then
        print_error "[backups_check] Current profile not set!"
        exit 1
    fi
    if [ "${SAGEDOT_BACKUP_CREATED}" = true ]; then
        if [ "${SAGEDOT_BACKUP_ID}" -eq 0 ]; then
            print_error "[backups_check] SAGEDOT_BACKUP_ID was not set!"
            exit 1
        fi
        return
    fi
    local sql
    local _res
    sql="
    SELECT (date) FROM backups
    WHERE date = '${SAGEDOT_RUNTIME}' AND profile = ${SAGEDOT_CURRENT_PROFILE};
    "
    _res="$(sqlite_run "${sql}")"
    if [ -z "${_res}" ]; then
        backups_create
    fi
}

#######################################
# Create the backups folder and initialize the database
#
# Globals
#   SAGEDOT_CURRENT_PROFILE
#   SAGEDOT_BACKUP_CREATED
#   SAGEDOT_BACKUP_ID
#   SAGEDOT_RUNTIME
#   SAGEDOT_RUNTIME_FOLDER
#   SAGEDOT_CURRENT_PROFILE_DIR
# Outputs:
#   Exits if SAGEDOT_CURRENT_PROFILE is invalid
#   Sets SAGEDOT_BACKUP_CREATED to TRUE
#   Sets SAGEDOT_BACKUP_ID to > 0
#   Creates a backup folder
#   Inserts a row in the backups table
backups_create() {
    if [ "${SAGEDOT_CURRENT_PROFILE}" -eq 0 ]; then
        print_error "[backups_create] Current profile not set!"
        exit 1
    fi
    local sql
    local _res
    sql="
    INSERT INTO backups (profile, date, folder)
    VALUES ('${SAGEDOT_CURRENT_PROFILE}', '${SAGEDOT_RUNTIME}', '${SAGEDOT_RUNTIME_FOLDER}');
    "
    _res="$(sqlite_run "${sql}")"
    SAGEDOT_BACKUP_CREATED=true
    readonly SAGEDOT_BACKUP_CREATED
    mkdir -p "${SAGEDOT_CURRENT_PROFILE_DIR}/backups/${SAGEDOT_RUNTIME_FOLDER}"
    sql="
    SELECT (id) FROM backups WHERE date = '${SAGEDOT_RUNTIME}' AND profile = ${SAGEDOT_CURRENT_PROFILE};
    "
    _res="$(sqlite_run "${sql}")"
    if [ -n "${_res}" ]; then
        SAGEDOT_BACKUP_ID="${_res}"
    fi
    readonly SAGEDOT_BACKUP_ID
    log_trace "[backups_create] SAGEDOT_BACKUP_ID=${_res}"
}

#######################################
# Backs up a single file
#
# Globals
#   SAGEDOT_BACKUP_CREATED
#   SAGEDOT_BACKUP_ID
#   SAGEDOT_CURRENT_PROFILE_DIR
#   SAGEDOT_RUNTIME_FOLDER
# Arguments:
#   $1: file
# Outputs:
#   Exits if arguments are wrong
#   Exits if SAGEDOT_CURRENT_PROFILE is invalid
#   Creates a backup folder
#   Inserts a row in the backups table
backup_file() {
    if [ "${SAGEDOT_BACKUP_CREATED}" = false ]; then
        print_error "backup_file: Called before creating backup!"
        exit 1
    fi
    if [ "${SAGEDOT_BACKUP_ID}" -eq 0 ]; then
        print_error "backup_file: SAGEDOT_BACKUP_ID not set!"
        exit 1
    fi
    if [ "$#" -lt 1 ]; then
        print_error "backup_file: Wrong arguments!"
        exit 1
    fi
    local file
    file="${1}"
    shift
    local hash
    if [ "$#" -lt 1 ]; then
        hash="$(sagedot_hash "${file}")"
    else
        hash="${1}"
    fi
    local escape
    local base
    base="$(basename "${file}")"
    # Escape the base just to be safe
    escape="$(printf "%s" "${base}" | sed -e 's/[\/&]/\\&/g')"
    # Folder path
    local folder
    folder="$(echo "${file}" | sed 's/\/'"${escape}"'$//')"
    # Set the folder we are moving to
    local backup_folder
    backup_folder="${SAGEDOT_CURRENT_PROFILE_DIR}/backups/${SAGEDOT_RUNTIME_FOLDER}/"
    # If folder is == $HOME then no change needed
    if [ "${folder}" != "${HOME}" ]; then
        # Escape home
        escape="$(printf "%s" "${HOME}/" | sed -e 's/[\/&]/\\&/g')"
        # remove home from folder
        folder="$(echo "${folder}" | sed 's/^'"${escape}"'//')"
        # If not we have to add it to the path
        backup_folder="${backup_folder}${folder}/"
        # Then create the folder for it
        mkdir -p "${backup_folder}"
    fi

    # Finally we move the old file to the backup
    mv "${file}" "${backup_folder}"

    local sql
    sql="
    INSERT INTO backup_files (backup, file, name, hash)
    VALUES (${SAGEDOT_BACKUP_ID}, '${file}', '${base}', '${hash}');
    "
    local _res
    _res="$(sqlite_run "${sql}")"
    print_default "Backed-up: ${file}"
    # log_debug "[backup_file] Backed-up: $file"
}
