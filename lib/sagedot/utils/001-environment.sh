#!/usr/bin/env sh

#######################################
# Check which distro is being used
# Only supports debian, arch, and alpine
#
# Outputs:
# 	Returns name of distro or nothing
which_distro() {
    if [ -f /etc/debian_version ]; then
        echo debian
        return
    elif [ -f /etc/arch-release ]; then
        echo arch
        return
    elif [ -f /etc/alpine-release ]; then
        echo alpine
        return
    fi
}

#######################################
# Check which package manager is available
# It's based on distro so only supports:
# Debain: apt
# Arch: yay|pacman
# Alpine: apk
# Other: unkown
#
# Outputs:
# 	Returns name of package manager or unkown
which_pmg() {
    local distro
    distro=$(which_distro)
    if [ "${distro}" = "debian" ]; then
        echo "apt"
    elif [ "${distro}" = "arch" ]; then
        # command -v exits with 1 if command not found
        # We dont want to have to flip e all the time
        # shellcheck disable=SC2312
        [ -n "$(command -v yay)" ] && echo "yay" && return
        echo "pacman"
    elif [ "${distro}" = "alpine" ]; then
        echo "apk"
    else
        echo uknown
    fi
}

#######################################
# Verify there is a sudo command available
#
# Outputs:
# 	Exits if no sudo equivalent is found
verify_sudo() {
    # command -v exits with 1 if command not found
    # We dont want to have to flip e all the time
    # shellcheck disable=SC2312
    [ -n "$(command -v sudo)" ] && return
    # shellcheck disable=SC2312
    [ -n "$(command -v doas)" ] && return
    print_error "No sudo equivalent found!"
    exit 1
}

#######################################
# Return the sudo command to use
#
# Outputs:
# 	Exits if no sudo equivalent is found
#   Otherwise echos the sudo command
which_sudo() {
    local _sudo
    local _cmd
    # command -v exits with 1 if command not found
    # We dont want to have to flip e all the time
    # shellcheck disable=SC2312
    [ -n "$(command -v sudo)" ] && _sudo="sudo -E"
    # shellcheck disable=SC2312
    [ -n "$(command -v doas)" ] && _sudo="doas"
    if [ -z "${_sudo}" ]; then
        log_error "[which_sudo] No sudo equivalent found!"
        exit 1
    fi
    echo "${_sudo}"
}

#######################################
# Installs a needed packages
#
# Arguments:
#   $#: package
# Outputs:
# 	Exits if distro is not supported
check_install() {
    local _filter
    _filter="$(pmg_filter "$*")"
    set "${_filter}"

    local distro
    distro=$(which_distro)
    local pkgs="$*"
    local _sudo
    _sudo=$(which_sudo)
    print_info "Installing: ${pkgs}"
    if [ "${distro}" = "debian" ]; then
        # pkgs=${pkgs//python-pip/python3-pip}
        # shellcheck disable=SC2086
        ${_sudo} DEBIAN_FRONTEND=noninteractive apt-get install -y ${pkgs}
    elif [ "${distro}" = "arch" ]; then
        local pmg
        pmg=$(which_pmg)
        if [ "${pmg}" = "yay" ]; then
            # shellcheck disable=SC2086
            ${pmg} -S --noconfirm --needed ${pkgs}
        else
            # shellcheck disable=SC2086
            ${_sudo} "${pmg}" -S --noconfirm --needed ${pkgs}
        fi
    elif [ "${distro}" = "alpine" ]; then
        # pkgs=${pkgs//python-pip/py-pip}
        # shellcheck disable=SC2086
        ${_sudo} apk add --no-cache ${pkgs}
    else
        print_error "Unsupported distro for install"
        exit 1
    fi
}

#######################################
# Filter a list of packages against the
# current package manager and distro
#
# Source:
#   https://github.com/kaixinguo360/dotfiles/
#
# Arguments:
#   $#: package | @distro:package | @!distro:package |
#       @pmg:package | @!pmg:package
# Outputs:
# 	Echo a filtered list of packages
pmg_filter() {
    local _distro
    local _pmg
    _distro="$(which_distro)"
    _pmg="$(which_pmg)"
    # 1,3  : @pmg:package > package
    # 2,4  : @!pmg:package > removed
    # 5    : @!other:package > package
    # 6    : @other:package > removed
    # 7    : Reduce spaces to a single one
    # 8    : Remove starting space
    # 9    : Remove ending space
    echo "$*" |
        sed "s/@${_pmg}:\([^ ]\+\)/\1/g" |
        sed "s/@!${_pmg}:[^ :]\+//g" |
        sed "s/@${_distro}:\([^ ]\+\)/\1/g" |
        sed "s/@!${_distro}:[^ :]\+//g" |
        sed 's/@![^ :]\+:\([^ :]\+\)/\1/g' |
        sed 's/@[^ :]\+:[^ :]\+//g' |
        sed 's/ \+/ /g' |
        sed 's/^ \+//g' |
        sed 's/ \+$//g'
}

#######################################
# Checks if a set of commands are available
#
# Arguments:
#   $#: command
# Outputs:
# 	Returns 1 if a command is not found
#   Returns 0 if all commands are found
has() {
    local _filter
    _filter="$(pmg_filter "$*")"
    set "${_filter}"

    for CMD in "$@"; do
        # command -v exits with 1 if command not found
        # We dont want to have to flip e all the time
        # shellcheck disable=SC2312
        [ -z "$(command -v "${CMD}")" ] && return 1
    done
    return 0
}
#######################################
# Checks if a set of commands are not available
#
# Arguments:
#   $#: command
# Outputs:
# 	Returns 1 if a command is found
#   Returns 0 if all commands are not found
not_has() {
    # has does not exit
    # shellcheck disable=SC2310
    if has "$@"; then
        return 1
    else
        return 0
    fi
}

#######################################
# Checks if a set of packages is installed
#
# Arguments:
#   $#: package
# Outputs:
# 	Returns 1 if a package is found
#   Returns 0 if all package are not found
is_installed() {
    local _filter
    _filter="$(pmg_filter "$*")"
    set "${_filter}"
    local pmg
    pmg=$(which_pmg)
    # set +e
    for CMD in "$@"; do
        local _cmd
        set +e
        if [ "${pmg}" = "apt" ]; then
            _cmd="$(dpkg -s "${CMD}" 2>/dev/null)"
        elif [ "${pmg}" = "yay" ] || [ "${pmg}" = "pacman" ]; then
            _cmd="$(${pmg} -Q "${CMD}" 2>/dev/null)"
        elif [ "${pmg}" = "apk" ]; then
            _cmd="$(apk info 2>/dev/null | sed -n '/^'"${CMD}"'$/p')"
        fi
        set -e
        [ -z "${_cmd}" ] && return 1
    done
    return 0
}
