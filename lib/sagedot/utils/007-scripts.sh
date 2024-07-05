#!/usr/bin/env sh

# SAGEDOT_SCRIPTS_BEFORE
# Used to tell the database if it is before or after the configs
# WARNING: DO NOT SET THIS MANUALLY unless you know what your doing
SAGEDOT_SCRIPTS_BEFORE=1
# SAGEDOT_SCRIPTS_FOLDER
# Used to tell the database what folder the scripts are ing
# WARNING: DO NOT SET THIS MANUALLY unless you know what your doing
SAGEDOT_SCRIPTS_FOLDER=""

#######################################
# Change the SAGEDOT_SCRIPTS_* Globals
#
# Globals:
#   SAGEDOT_SCRIPTS_BEFORE
#   SAGEDOT_SCRIPTS_FOLDER
# Arguments:
#   $1: 0/1 - after/before
#   $2: scripts folder
# Outputs:
#   Exits if arguments are wrong
#   Changes SAGEDOT_SCRIPTS_ variables based on arguments
# WARNING:
#   This does no checks against the arguments to see if they are valid!
sagedot_scripts_change() {
    if [ "$#" -lt 2 ]; then
        print_error "[sagedot_scripts_change] Wrong arguments!"
        exit 1
    fi
    SAGEDOT_SCRIPTS_BEFORE="${1}"
    SAGEDOT_SCRIPTS_FOLDER="${2}"
}

#######################################
# Run a file once
#
# Globals:
#   SAGEDOT_CURRENT_PROFILE
#   SAGEDOT_RUNTIME
#   SAGEDOT_SCRIPTS_BEFORE
#   SAGEDOT_SCRIPTS_FOLDER
# Arguments:
#   $1: file
# Outputs:
#   Exits if arguments are wrong
#   Exits if SAGEDOT_CURRENT_PROFILE is invalid
#   Updates the database if a script was ran
#   Runs an arbitrary script
script_file_once() {
    if [ "$#" -lt 1 ]; then
        print_error "[script_file_once] Called with wrong arguments!"
        exit 1
    fi
    if [ "${SAGEDOT_CURRENT_PROFILE}" -eq 0 ]; then
        print_error "[script_file_once] Current profile not set!"
        exit 1
    fi
    if [ -z "${SAGEDOT_SCRIPTS_FOLDER}" ]; then
        log_warning "[script_file_once] SAGEDOT_SCRIPTS_FOLDER not set!"
        return
    fi
    local file
    file="${1}"
    if [ ! -f "${file}" ]; then
        print_error "[script_file_once] ${file} is not a file"
        return
    fi
    file="$(realpath "${file}")"
    local base
    base="$(basename "${file}")"

    local sql
    sql="
    SELECT (date) FROM run_once
    WHERE name = '${base}' AND profile = ${SAGEDOT_CURRENT_PROFILE} AND folder = '${SAGEDOT_SCRIPTS_FOLDER}' AND before = ${SAGEDOT_SCRIPTS_BEFORE};
    "
    local _res
    _res="$(sqlite_run "${sql}")"
    if [ -z "${_res}" ]; then
        log_info "[script_file_once] Running: ${base}"
        sql="
        INSERT INTO run_once (profile, before, folder, name, file, date)
        VALUES (${SAGEDOT_CURRENT_PROFILE}, ${SAGEDOT_SCRIPTS_BEFORE}, '${SAGEDOT_SCRIPTS_FOLDER}', '${base}', '${file}', '${SAGEDOT_RUNTIME}');
        "
        set +e
        # shellcheck source=/dev/null
        . "${file}"
        set -e
        _res="$(sqlite_run "${sql}")"
    else
        log_debug "[script_file_once] Already ran: ${base}"
    fi
}

#######################################
# Run a file if it has been changed
#
# Globals:
#   SAGEDOT_CURRENT_PROFILE
#   SAGEDOT_RUNTIME
#   SAGEDOT_SCRIPTS_BEFORE
#   SAGEDOT_SCRIPTS_FOLDER
# Arguments:
#   $1: file
# Outputs:
#   Exits if arguments are wrong
#   Exits SAGEDOT_CURRENT_PROFILE is invalid
#   Updates the database if a script was ran
#   Runs an arbitrary script
script_file_change() {
    if [ "$#" -lt 1 ]; then
        print_error "[script_file_change] Called with wrong arguments!"
        exit 1
    fi
    if [ "${SAGEDOT_CURRENT_PROFILE}" -eq 0 ]; then
        print_error "[script_file_change] Current profile not set!"
        exit 1
    fi
    if [ -z "${SAGEDOT_SCRIPTS_FOLDER}" ]; then
        log_warning "[script_file_change] SAGEDOT_SCRIPTS_FOLDER not set!"
        return
    fi
    local file
    file="${1}"
    if [ ! -f "${file}" ]; then
        print_error "[script_file_change] Not a file: ${file}"
        return
    fi
    file="$(realpath "${file}")"
    local base
    base="$(basename "${file}")"
    local file_hash
    file_hash="$(sagedot_hash "${file}")"
    local sql
    sql="
    SELECT (hash) FROM run_onchange
    WHERE name = '${base}' AND profile = '${SAGEDOT_CURRENT_PROFILE}' AND folder = '${SAGEDOT_SCRIPTS_FOLDER}' AND before = ${SAGEDOT_SCRIPTS_BEFORE}; 
    "
    local _res
    _res="$(sqlite_run "${sql}")"
    if [ -z "${_res}" ]; then
        log_info "[script_file_change] Running: ${base}"
        sql="
        INSERT INTO run_onchange (profile, before, folder, name, file, first_ran, last_ran, hash)
        VALUES (${SAGEDOT_CURRENT_PROFILE}, ${SAGEDOT_SCRIPTS_BEFORE}, '${SAGEDOT_SCRIPTS_FOLDER}', '${base}', '${file}', '${SAGEDOT_RUNTIME}', '${SAGEDOT_RUNTIME}', '${file_hash}');
        "
        set +e
        # shellcheck source=/dev/null
        . "${file}"
        set -e
        _res="$(sqlite_run "${sql}")"
    else
        if [ "${_res}" = "${file_hash}" ]; then
            log_debug "[script_file_change] Already ran: ${base}"
        else
            log_info "[script_file_change] Running: ${base}"
            sql="
            UPDATE run_onchange
            SET last_ran = '${SAGEDOT_RUNTIME}',
                hash = '${file_hash}',
                file = '${file}'
            WHERE name = '${base}' AND profile = '${SAGEDOT_CURRENT_PROFILE}' AND folder = '${SAGEDOT_SCRIPTS_FOLDER}' AND before = ${SAGEDOT_SCRIPTS_BEFORE};
            "
            set +e
            # shellcheck source=/dev/null
            . "${file}"
            set -e
            _res="$(sqlite_run "${sql}")"
        fi
    fi
}

#######################################
# Run a file always
#
# Globals:
#   SAGEDOT_CURRENT_PROFILE
# Arguments:
#   $1: file
# Outputs:
#   Exits if arguments are wrong
#   Exits if SAGEDOT_CURRENT_PROFILE is invalid
#   Runs an arbitrary script
script_file_always() {
    if [ "$#" -lt 1 ]; then
        print_error "[script_file_always] Called with wrong arguments!"
        exit 1
    fi
    if [ "${SAGEDOT_CURRENT_PROFILE}" -eq 0 ]; then
        print_error "[script_file_always] Current profile not set!"
        exit 1
    fi
    local file
    file="${1}"
    if [ ! -f "${file}" ]; then
        print_error "[script_file_always] ${file} is not a file!"
        return
    fi
    file="$(realpath "${file}")"
    local base
    base="$(basename "${file}")"
    log_info "[script_file_always] Running: ${base}"
    set +e
    # shellcheck source=/dev/null
    . "${file}"
    set -e
}

scripts_folder() {
    if [ "$#" -lt 2 ]; then
        print_error "[scripts_folder] Called with wrong arguments!"
        exit 1
    fi
    local scripts_dir
    local state="${2}"
    scripts_dir="${1}"
    if [ ! -d "${scripts_dir}" ]; then
        log_warning "[scripts_folder] Not a directory: ${scripts_dir}"
        return
    fi
    local _starting_dir
    _starting_dir="$(pwd)"

    cd "${scripts_dir}" || (log_error "[scripts_folder] cd failed: ${scripts_dir}" && exit 1)

    local _file_loop
    _file_loop="$(sagedot_tmp)"
    find -L . \( ! -path './*/*' -o -prune \) -name '*.sh' ! -name . ! -name "$(printf "*\n*")" -type f >"${_file_loop}"
    while IFS= read -r file; do
        case "${state}" in
        always)
            script_file_always "${file}"
            ;;
        once)
            script_file_once "${file}"
            ;;
        change)
            script_file_change "${file}"
            ;;
        esac

    done <"${_file_loop}"

    cd "${_starting_dir}" || (log_error "[scripts_folder] cd failed: ${_starting_dir}" && exit 1)
}
