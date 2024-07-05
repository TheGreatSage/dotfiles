#!/usr/bin/env sh

#######################################
# Filter packages against current distro and package manager
#
# Arguments:
#   pipe: package list
# Outputs:
#   Filtered list of valid packages
packages_filter() {
    local _distro
    local _pmg
    _distro="$(which_distro)"
    _pmg="$(which_pmg)"
    # 1: @other:package > removed
    # 2: @!pmg:package > removed
    # 3: @any:package > package
    # 5: #lines > removed
    while read -r line || [ -n "${line}" ]; do
        if [ -z "${line}" ]; then
            continue
        fi
        echo "${line}" |
            sed -n '/^[^@].*$/p; /^@!.*:.*$/p; /^@'"${_distro}"':.*$/p; /^@'"${_pmg}"':.*$/p' |
            sed '/^@!'"${_distro}"':.*$/d; /^@!'"${_pmg}"':.*$/d' |
            sed 's/@[^:]*://' |
            sed '/^#/d'
    done
}

#######################################
# Filter packages out packages that are installed
#
# Arguments:
#   pipe: package list
# Outputs:
#   Filtered list of not installed packages
packages_filter_installed() {
    while read -r line || [ -n "${line}" ]; do
        if [ -z "${line}" ]; then
            continue
        fi
        if ! is_installed "${line}"; then
            echo "${line}"
        fi
    done
}

#######################################
# Update packages in the database as installed
#
# Globals:
#   SAGEDOT_CURRENT_PROFILE
#   SAGEDOT_RUNTIME
# Arguments:
#   pipe: package list
# Outputs:
#   Inserts all packages into the databse
packages_mark() {
    while read -r line || [ -n "${line}" ]; do
        if [ -z "${line}" ]; then
            continue
        fi
        local sql
        local _res
        sql="SELECT (name) FROM packages WHERE profile = ${SAGEDOT_CURRENT_PROFILE} AND name = '${line}'"
        _res="$(sqlite_run "${sql}")"
        if [ -z "${_res}" ]; then
            sql="
            INSERT INTO packages (profile, name, date)
            VALUES (${SAGEDOT_CURRENT_PROFILE}, '${line}', '${SAGEDOT_RUNTIME}');
            "
            _res="$(sqlite_run "${sql}")"
        fi
    done
}

#######################################
# Find any *.list file in the provided directory
# and installs any packages not installed.
#
# Arguments:
#   $1: package list
# Outputs:
#   Exits if arguments are wrong
#   Installs arbitrary packages
packages_list() {
    local dir
    if [ "$#" -gt 0 ]; then
        dir=${1}
    else
        print_error "[packages_list] Wrong arguments!"
        exit 1
    fi
    local _pkg_loop
    _pkg_loop="$(sagedot_tmp)"
    local _needs
    find -L "${dir}" -name "*.list" ! -name . ! -name "$(printf "*\n*")" -prune -type f >"${_pkg_loop}"
    while IFS= read -r file; do
        print_info "Found package list: ${file}"
        _needs="$(packages_filter <"${file}" | packages_filter_installed)"
        local _pkgs
        _pkgs="$(echo "${_needs}" | tr '\n' ' ')"
        if [ -n "${_pkgs}" ]; then
            check_install "${_pkgs}"
            echo "${_needs}" | packages_mark
        fi
    done <"${_pkg_loop}"
}
