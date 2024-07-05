#!/usr/bin/env sh

#######################################
# Loads alpine setup files into source
#
setup_alpine() {
    for ALPINE in "${SAGEDOT_HOME}"/lib/sagedot/alpine/???-*.sh; do
        log_debug "${ALPINE}"
        # shellcheck source=/dev/null
        . "${ALPINE}"
    done
}

#######################################
# A simple check to run setup file for different distros
# [2024-07-24] Only alpine needs extra work
#
setup_distros() {
    local distro
    distro=$(which_distro)
    if [ "${distro}" = "alpine" ]; then
        setup_alpine
    fi
}

setup_distros
