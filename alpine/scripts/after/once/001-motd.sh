change_motd() {
    _sudo=$(which_sudo)
    # Hard code path cause it's easier
    # TODO: make a current profile variable
    ${_sudo} mv "${SAGEDOT_HOME}"/alpine/scripts/after/once/motd /etc/motd
}

change_motd