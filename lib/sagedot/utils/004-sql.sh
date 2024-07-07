#!/usr/bin/env sh

#######################################
# Exit if sqlite is not available
#
# Outputs:
#   Exits if sqlite3 is not found
verify_sqlite() {
    if ! has sqlite3; then
        print_error "SQLite not installed!"
        exit 1
    fi
}

#######################################
# Run an sql statment against the sagedot file
#
# Arguments:
#   $1: sql statement
# Globals:
#   SAGEDOT_FILE
# Outputs:
#   Exits if arguments are wrong
#   Result of sqlite to stdout
sqlite_run() {
    local sql
    if [ "$#" -gt 0 ]; then
        sql="${1}"
    else
        log_error "[sqlite_run] Wrong arguments!"
        return
    fi
    sqlite3 "${SAGEDOT_FILE}" "${sql}"
}

#######################################
# Runs all migrations
#
# Globals:
#   SAGEDOT_HOME
sqlite_load_migrations() {
    for MIGRATE in "${SAGEDOT_HOME}"/lib/sagedot/migrations/???-*.sh; do
        # shellcheck source=/dev/null
        . "${MIGRATE}"
        log_trace "[sagedot] Migration: ${MIGRATE}"
    done
}


#######################################
# Returns the version number of the sagedot database
#
# Outputs
#   Version Number
sqlite_get_version() {
    local sql="
    SELECT name FROM sqlite_master WHERE type='table' AND name='sagedot';
    "
    local _res
    _res="$(sqlite_run "${sql}")"
    if [ -z "${_res}" ]; then
        echo "1.0.0"
        return
    fi
    sql="
    SELECT (value) FROM sagedot WHERE key = 'version';
    "
    _res="$(sqlite_run "${sql}")"
    if [ -z "${_res}" ]; then
        log_error "Could not get sagedot version!"
        exit 1
    fi
    echo "${_res}"
}

#######################################
# Migrate the databse to the current version
#
# Globals:
#   SAGEDOT_FILE
sqlite_sagedot() {
    if [ ! -f "${SAGEDOT_FILE}" ]; then
        touch "${SAGEDOT_FILE}"
    fi
    print_debug "Loading sagedot migrations."
    sqlite_load_migrations
    log_debug "Finshed sagedot migrations."
}