#######################################
# Restart a system service, supports systemctl and rc-service
#
# Arguments:
#   $1: service
#   $2: start|stop|restart|status|enable|disable
# Outputs:
#   Exits if arguments are wrong
#   Prints status using print_commands
service_manager() {
    if [ "$#" -lt 2 ]; then
        print_error "[service_manager] Wrong arguments!"
        exit 1
    fi
    local service
    service="${1}"
    local _cmd
    _cmd="${2}"
    local info
    info="Unkown"
    local enable
    enable=""
    case "${_cmd}" in
    start)
        info="Starting:"
        ;;
    stop)
        info="Stopping:"
        ;;
    restart)
        info="Restarting:"
        ;;
    status)
        info="Status:"
        ;;
    enable)
        enable="add"
        info="Enabling:"
        ;;
    disable)
        enable="del"
        info="Disabling:"
        ;;
    *)
        print_warning "[service_manager] ${_cmd} is not a valid option!"
        ;;
    esac

    local _sudo
    _sudo="$(which_sudo)"

    if [ -z "${enable}" ]; then
        if has systemctl; then
            print_notice "${info} ${service}"
            set +e
            ${_sudo} systemctl "${_cmd}" "${service}"
            set -e
            return
        elif has rc-service; then
            print_notice "${info} ${service}"
            set +e
            ${_sudo} rc-service "${service}" "${_cmd}"
            set -e
            return
        fi
    else
        if has systemctl; then
            print_notice "${info} ${service}"
            set +e
            ${_sudo} systemctl "${_cmd}" "${service}"
            set -e
            return
        elif has rc-update; then
            print_notice "${info} ${service}"
            set +e
            ${_sudo} rc-update "${enable}" "${service}"
            set -e
            return
        fi
    fi
    print_warning "No supported service manager for: ${service}"
    return
}

#######################################
# Stop a service
#
# Arguments:
#   $1: service
# Outputs:
#   Exits if arguments are wrong
#   Returns 1 if failed
#   Returns 0 if command ran
service_stop() {
    if [ "$#" -eq 0 ]; then
        print_error "[service_stop] Wrong arguments!"
        exit 1
    fi
    local service
    service="${1}"

    service_manager "${service}" stop
}

#######################################
# Start a service
#
# Arguments:
#   $1: service
# Outputs:
#   Exits if arguments are wrong
service_start() {
    if [ "$#" -eq 0 ]; then
        print_error "[service_start] Wrong arguments!"
        exit 1
    fi
    local service
    service="${1}"

    service_manager "${service}" start
}

#######################################
# Check status of a service
#
# Arguments:
#   $1: service
# Outputs:
#   Exits if arguments are wrong
service_restart() {
    if [ "$#" -eq 0 ]; then
        print_error "[service_restart] Wrong arguments!"
        exit 1
    fi
    local service
    service="${1}"

    service_manager "${service}" restart
}

#######################################
# Check status of a service
#
# Arguments:
#   $1: service
# Outputs:
#   Exits if arguments are wrong
service_status() {
    if [ "$#" -eq 0 ]; then
        print_error "[service_status] Wrong arguments!"
        exit 1
    fi
    local service
    service="${1}"

    service_manager "${service}" status
}

#######################################
# Enable a service
#
# Arguments:
#   $1: service
# Outputs:
#   Exits if arguments are wrong
service_enable() {
    if [ "$#" -eq 0 ]; then
        print_error "[service_enable] Wrong arguments!"
        exit 1
    fi
    local service
    service="${1}"

    service_manager "${service}" enable
}

#######################################
# Disable a service
#
# Arguments:
#   $1: service
# Outputs:
#   Exits if arguments are wrong
service_disable() {
    if [ "$#" -eq 0 ]; then
        print_error "[service_disable] Wrong arguments!"
        exit 1
    fi
    local service
    service="${1}"

    service_manager "${service}" disable
}
