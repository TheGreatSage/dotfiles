#!/usr/bin/env sh

#######################################
# A simple check to see if chsh is installed or not
#
alpine_chsh() {
    if ! has chsh; then
        print_info "Package: 'shadow' is needed to change shell!"
        check_install shadow
    fi
}
