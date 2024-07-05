#!/usr/bin/env sh

initialize() {
    local _distro
    local _pmg
    _distro="$(which_distro)"
    _pmg="$(which_pmg)"
    log_info "[init] Running on: ${_distro}"
    log_info "[init] Package Manager: ${_pmg}"

    if ! is_installed sqlite; then
        check_install "@!debian:sqlite" "@debian:sqlite3"
    fi

    if [ ! -f "${SAGEDOT_FILE}" ]; then
        touch "${SAGEDOT_FILE}"
        sqlite_sagedot
    fi
}

initialize
