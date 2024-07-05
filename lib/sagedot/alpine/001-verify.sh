#!/usr/bin/env sh

#######################################
# Set the repositories to edge
#
# TODO: Ask before making changes
# TODO: Ask to add testing
# Globals:
#   SAGEDOT_HOME
# Outputs:
#   Notifies if before running the repositories to edge
verify_repositories() {
    local _diff
    set +e
    _diff="$(diff "${SAGEDOT_HOME}"/lib/sagedot/alpine/repositories /etc/apk/repositories)"
    set -e
    local _sudo
    _sudo=$(which_sudo)
    if [ -n "${_diff}" ]; then
        print_info "Setting repositories to edge"
        ${_sudo} cp -f "${SAGEDOT_HOME}"/lib/sagedot/alpine/repositories /etc/apk/repositories
        alpine_update
    fi
}

verify_repositories
