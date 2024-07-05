#!/usr/bin/env sh

#######################################
# Simple wrapper around chsh
#
# Arguments:
#   $1: name of shell
sagedot_chsh() {
    if [ "$#" -lt 1 ]; then
        log_warning "[sagedot_chsh] called with wrong arguments!"
        return
    fi
    local distro
    distro=$(which_distro)
    if [ "${distro}" = "alpine" ]; then
        alpine_chsh
    fi

    if ! has "chsh"; then
        print_error "chsh not installed change shell manually!"
        return
    fi
    local _cmd
    set +e
    _cmd="$(command -v "${1}")"
    set -e
    if [ -z "${_cmd}" ]; then
        print_warning "Could not switch shell, ${1} not found!"
        return
    fi
    print_notice "Changing shell to ${1}"
    local who
    who="$(whoami)"
    local _sudo
    _sudo="$(which_sudo)"
    ${_sudo} chsh -s "${_cmd}" "${who}"
    return
}
