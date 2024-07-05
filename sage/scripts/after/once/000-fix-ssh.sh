# For alpine you have to restart ssh otherwise it errors out
# Maybe its just me
service_restart "sshd"

## Finally the message to tell to exit then log back in
print_success "Restart shell to see changes!"