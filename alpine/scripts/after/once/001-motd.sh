change_motd() {
    _sudo=$(which_sudo)
    # Clears motd
    ${_sudo} true > /etc/motd

    { 
        ${_sudo} printf "%s\n\n" "Welcome!"
        ${_sudo} printf "%s\n" "Default pacakges shoulda been setup."
        ${_sudo} printf "%s\n\n" "You are good to start setting thigs up."
        ${_sudo} printf "%s\n" "Don't break stuff to bad!"
    } >> /etc/motd
}