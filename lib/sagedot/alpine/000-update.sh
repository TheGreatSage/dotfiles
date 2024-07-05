#!/usr/bin/env sh

#######################################
# Update alpine packages
#
alpine_update() {
    local _sudo
    _sudo=$(which_sudo)
    print_info "Updating"
    ${_sudo} apk update
    ${_sudo} apk upgrade
}
