#!/usr/bin/env sh

#######################################
# Check if a directory name is valid
#
# Arguments:
#   $1: directory
# Outputs:
#   Exits if wrong arguments.
# 	Exits if directory is not valid
check_directory_name() {
    local dir
    if [ "$#" -gt 0 ]; then
        dir="${1}"
    else
        print_error "[check_directory_name] Wrong arguments!"
        exit 1
    fi
    if ! echo "${dir}" | grep "^[/.a-zA-Z0-9_-]*$" >/dev/null; then
        print_error "Current working directory '${dir}' has an invalid character. The directory you are in when you install a profile must have alpha numeric characters, with only dashes, dots or underscores."
        exit 1
    fi
}

#######################################
# Appends a file if content does not exist within
#
# Arguments:
#   $1: content
#   $2: file
# Outputs:
#   Add content to file if it wasn't in it.
append_file_if_not_exist() {
    local contents
    local target_file
    if [ "$#" -lt 2 ]; then
        print_warning "[append_file_if_not_exist] Wrong arguments!"
        return
    fi
    contents="${1}"
    target_file="${2}"
    if ! grep -q "${contents}" "${target_file}"; then
        echo "${contents}" >>"${target_file}"
    fi
}

#######################################
# Simple wrapper to hash a file
#
# Arguments:
#   $1: file
# Outputs:
#   Exits if arugments are wrong
#   Exits if $1 is not a file
#   Echos the hash of the inputted file
sagedot_hash() {
    if [ "$#" -lt 1 ]; then
        log_error "[sagedot_hash] Wrong arguments!"
        exit 1
    fi
    local file
    file="${1}"
    if [ ! -f "${file}" ]; then
        log_error "[sagedot_hash] Not a file: ${file}"
        exit 1
    fi
    sha256sum -b "${file}" | cut -d " " -f 1
}
