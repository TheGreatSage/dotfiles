#!/usr/bin/env sh

#######################################
# Iterates through a config folder and puts
# all it's files in the correct place
#
# Arguments:
#   $1: config directory
# Outputs:
#   Exits if arguments are wrong
#   Files are copied to $HOME
#   Folders are copied to $HOME/.config
install_configs() {
    local configs_dir
    local home=""
    if [ "$#" -gt 0 ]; then
        configs_dir="${1}"
        shift
        if [ "$#" -gt 0 ]; then
            home="${1}"
        fi
    else
        print_error "[install_configs] Wrong arguments"
        exit 1
    fi

    # We want to save the starting dir to cd back after we are done
    local _starting_dir
    _starting_dir="$(pwd)"
    cd "${configs_dir}" || (print_error "[install_configs] cd failed: ${configs_dir}" && exit 1)

    # Always do files first
    # I have to use a tmp file because piping creates a new shell
    local _file_loop
    _file_loop="$(sagedot_tmp)"
    find -L . ! -name . ! -name "$(printf "*\n*")" -prune -type f >"${_file_loop}"
    while IFS= read -r file; do
        local _fname
        _fname="$(basename "${file}")"
        configs_file "${file}" "${HOME}"
    done <"${_file_loop}"

    # Do directories second
    # I have to use a tmp file because piping creates a new shell
    local _dir_loop
    _dir_loop="$(sagedot_tmp)"
    find -L . ! -name . ! -name "$(printf "*\n*")" -prune -type d >"${_dir_loop}"
    while IFS= read -r dir; do
        local _dname
        _dname="$(basename "${dir}")"
        if [ -z "${home}" ]; then
            configs_folder "${dir}"
        else
            configs_folder "${dir}" "${home}" "${home}"
        fi
    done <"${_dir_loop}"

    cd "${_starting_dir}" || (print_error "[install_configs] cd failed: ${_starting_dir}" && exit 1)
    return
}

#######################################
# Iterates through a scripts folder and
# runs ones that meet the run critera
#
# Arguments:
#   $1: scripts directory
# Outputs:
#   Exits if arguments are wrong
#   Runs arbitrary scripts
install_scripts() {
    local scripts_dir
    if [ "$#" -gt 0 ]; then
        scripts_dir=${1}
    else
        print_error "[install_scripts] Wrong arguments!"
        exit 1
    fi

    local _starting_dir
    _starting_dir="$(pwd)"

    cd "${scripts_dir}" || (print_error "[install_scripts] cd failed: ${scripts_dir}" && exit 1)

    local run_always
    run_always="./always"
    if [ -d "${run_always}" ]; then
        scripts_folder "${run_always}" "always"
    fi

    local run_once
    run_once="./once"
    if [ -d "${run_once}" ]; then
        scripts_folder "${run_once}" "once"
    fi

    local run_change
    run_change="./onchange"
    if [ -d "${run_change}" ]; then
        scripts_folder "${run_change}" "change"
    fi
    run_change="./change"
    if [ -d "${run_change}" ]; then
        scripts_folder "${run_change}" "change"
    fi

    cd "${_starting_dir}" || (print_error "[install_scripts] cd failed: ${_starting_dir}" && exit 1)
}

#######################################
# Install everything in a profile
#
# Arguments:
#   $1: profile
# Outputs:
#   Exits if arguments are wrong
#   Installs packages
#   Runs scripts
#   Moves config files
sagedot_install() {
    local profile
    if [ "$#" -gt 0 ]; then
        profile=${1}
    else
        print_error "[install] Wrong arguments!"
        exit 1
    fi

    profile_exists "${profile}"

    local profile_dir
    profile_dir="${SAGEDOT_HOME}/${profile}"

    profile_update "${profile}"

    print_notice "Starting install for '${profile}'"

    packages_list "${profile_dir}"

    local scripts
    scripts="${profile_dir}/scripts"
    sagedot_scripts_change 1 "scripts"
    print_debug "Checking for before scripts"
    if [ -d "${scripts}" ]; then
        install_scripts "${scripts}"
    fi

    scripts="${profile_dir}/scripts/before"
    sagedot_scripts_change 1 "scripts/before"
    if [ -d "${scripts}" ]; then
        install_scripts "${scripts}"
    fi

    local configs_found=false
    local configs
    configs="${profile_dir}/configs"
    print_debug "Checking for config files"
    if [ -d "${configs}" ]; then
        configs_found=true
        install_configs "${configs}"
    fi

    local home
    home="${profile_dir}/home"
    if [ -d "${home}" ]; then
        configs_found=true
        install_configs "${home}" "${HOME}"
    fi

    if [ "${configs_found}" = false ]; then
        print_notice "[install] No configs found in profile '${profile}'"
    fi

    print_debug "Checking for after scripts"
    scripts="${profile_dir}/scripts/after"
    sagedot_scripts_change 0 "scripts/after"
    if [ -d "${scripts}" ]; then
        install_scripts "${scripts}"
    fi

    print_success "Profile '${profile}' installed successfully!"
}
