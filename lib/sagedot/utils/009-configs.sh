#!/usr/bin/env sh

#######################################
# Copies a config file to the correct place
# Backs them up if they already exist
#
# Arguments:
#   $1: file
#   $2: [directory] - defaults to $HOME
# Outputs:
#   Exits if arguments are wrong
#   The config file is copied over to the correct place
configs_file() {
    local file
    local dir="${HOME}"
    if [ "$#" -gt 0 ]; then
        file=${1}
        shift
        if [ "$#" -gt 0 ]; then
            dir="${1}"
        fi
    else
        print_error "[configs_file] Wrong arguments!"
        exit 1
    fi
    if [ ! -f "${file}" ]; then
        print_warning "[configs_file] Not a file: ${file}"
        return
    fi
    local _fname
    _fname="$(basename "${file}")"
    local _real
    _real="${dir}/${_fname}"
    if [ -f "${_real}" ]; then
        local curr
        local _sha_file
        local _sha_curr
        curr="$(realpath "${_real}")"
        _sha_file="$(sagedot_hash "${file}")"
        _sha_curr="$(sagedot_hash "${curr}")"
        if [ "${_sha_file}" = "${_sha_curr}" ]; then
            print_default "[configs_file] File is current: ${file}"
        else
            print_info "[configs_file] Config file is different: ${file}"
            backups_check
            backup_file "${curr}" "${_sha_curr}"
            cp "${file}" "${curr}"
        fi
    else
        print_default "[configs_file] New file: ${file}"
        local _esacpe
        _escape="$(printf "%s" "${_fname}" | sed -e 's/[\/&]/\\&/g')"
        local _folder
        _folder="$(echo "${_real}" | sed 's/\/'"${_escape}"'$//')"
        mkdir -p "${_folder}"
        cp "${file}" "${_real}"
    fi
}

#######################################
# Iterates through a config folder and puts
# all it's files in $HOME/.config
#
# Arguments:
#   $1: file
#   $2: [directory] - defaults to $HOME/.config
#   $3: [base directory] - defaults to $HOME/.config
# Outputs:
#   Exits if arguments are wrong
#   The config file is copied over to the correct place
configs_folder() {
    local folder
    local base="${HOME}/.config"
    local bdir="${HOME}/.config"
    if [ "$#" -gt 0 ]; then
        folder=${1}
        shift
        if [ "$#" -gt 0 ]; then
            base="${1}"
            shift
            if [ "$#" -gt 0 ]; then
                bdir="${1}"
            fi
        fi
    else
        print_error "[configs_folder] Wrong arguments!"
        exit 1
    fi

    # print_info "Folder: $folder"

    local _folder_name
    _folder_name="$(basename "${folder}")"

    if [ "${base}" = "${bdir}" ]; then
        base="${base}/${_folder_name}"
    fi

    log_debug "[configs_folder]: Folder: ${_folder_name}"

    if [ ! -d "${folder}" ]; then
        log_warning "[configs_folder] Not a directory: ${folder}"
        return 1
    fi

    # Save the starting dir to come cd back to it
    local _start_dir
    _start_dir="$(pwd)"

    # cd into the folder
    cd "${folder}" || (log_error "[configs_folder] cd failed: ${folder}" && exit 1)

    # Do files first
    # I have to use a tmp file because piping creates a new shell
    local _file_loop
    _file_loop="$(sagedot_tmp)"
    find -L . ! -name . ! -name "$(printf "*\n*")" -prune -type f >"${_file_loop}"
    while IFS= read -r file; do
        local _fname
        _fname="$(basename "${file}")"
        configs_file "${file}" "${base}"
    done <"${_file_loop}"

    ## Do dirs second
    # I have to use a tmp file because piping creates a new shell
    local _dir_loop
    _dir_loop="$(sagedot_tmp)"
    find -L . ! -name . ! -name "$(printf "*\n*")" -prune -type d >"${_dir_loop}"
    while IFS= read -r dir; do
        local _dname
        _dname="$(basename "${dir}")"
        local _pwd
        _pwd="$(pwd)"
        configs_folder "${_pwd}/${_dname}" "${base}/${_dname}" "${bdir}"
    done <"${_dir_loop}"

    cd "${_start_dir}" || (log_error "[configs_folder] cd failed: ${_start_dir}" && exit 1)
}
