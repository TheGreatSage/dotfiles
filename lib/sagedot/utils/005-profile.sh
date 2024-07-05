#!/usr/bin/env sh

# SAGEDOT_CURRENT_PROFILE
# Database ID of the currently instally database
# 0 is unset
# WARNING: DO NOT SET THIS MANUALLY UNLESS YOU KNOW WHAT YOUR DOING
SAGEDOT_CURRENT_PROFILE=0
# SAGEDOT_CURRENT_PROFILE_DIR
# Used to track the current pofile directory name
# "" is unset
# WARNING: DO NOT SET THIS MANUALLY UNLESS YOU KNOW WHAT YOUR DOING
SAGEDOT_CURRENT_PROFILE_DIR=""

#######################################
# Exit if profile name is invalid.
# Valid profiles are [a-zA-Z0-9_-]
#
# Arguments:
#   $1: profile
# Outputs:
#   Exits if arguments are wrong
#   Exits if a profile name is invalid
check_profile_name() {
    local profile
    if [ "$#" -gt 0 ]; then
        profile=${1}
    else
        print_error "check_profile_name: Wrong arguments!"
        exit 1
    fi
    if ! echo "${profile}" | grep "^[a-zA-Z0-9_-]*$" >/dev/null; then
        print_error "Invalid profile name '${profile}'. Profiles must be alpha numeric with only dashes or underscores."
        exit 1
    fi
}

#######################################
# Exit if profile does not exist
#
# Globals:
#   SAGEDOT_HOME
# Arguments:
#   $1: profile
# Outputs:
#   Exits if arguments are wrong
#   Exits if a profile folder is not found
profile_exists() {
    local profile
    if [ "$#" -gt 0 ]; then
        profile=${1}
    else
        print_error "profile_exists: Wrong arguments!"
        exit 1
    fi
    local profile_dir="${SAGEDOT_HOME}/${profile}"

    if [ ! -d "${profile_dir}" ]; then
        print_error "profile_exists: Profile '${profile}' directory does not exist."
        exit 1
    fi
}

#######################################
# Update or create profile if it doesn't exist
#
# Globals:
#   SAGEDOT_CURRENT_PROFILE
#   SAGEDOT_CURRENT_PROFILE_DIR
# Arguments:
#   $1: profile
# Outputs:
#   Exits if arguments are wrong
#   Exits if a profile folder is not found
#   Sets the GLOBALS to the current profile
profile_update() {
    local profile
    if [ "$#" -gt 0 ]; then
        profile=${1}
    else
        print_error "[profile_update] Wrong arguments!"
        exit 1
    fi
    local sql
    sql="SELECT (id) FROM profiles WHERE profile = '${profile}';"
    local _res
    _res="$(sqlite_run "${sql}")"
    # Not sure why the first time this is ran, its a string
    if [ -z "${_res}" ]; then
        sql="
        INSERT INTO profiles (profile, installed_at, updated_at)
        VALUES ('${profile}', '${SAGEDOT_RUNTIME}', '${SAGEDOT_RUNTIME}');
        "
        _res="$(sqlite_run "${sql}")"
        sql="SELECT (id) FROM profiles WHERE profile = '${profile}';"
        _res="$(sqlite_run "${sql}")"
        if [ "${_res}" -gt 0 ]; then
            SAGEDOT_CURRENT_PROFILE="${_res}"
            SAGEDOT_CURRENT_PROFILE_DIR="${SAGEDOT_HOME}/${profile}"
        else
            print_error "[profile_update] Could not find profile: '${profile}' in database!"
            exit 1
        fi
    else
        # Not sure why shellcheck is complaining about these lines?
        # shellcheck disable=SC2034
        SAGEDOT_CURRENT_PROFILE="${_res}"
        # shellcheck disable=SC2034
        SAGEDOT_CURRENT_PROFILE_DIR="${SAGEDOT_HOME}/${profile}"
        sql="
        UPDATE profiles
        SET updated_at = '${SAGEDOT_RUNTIME}'
        WHERE profile = '${profile}';
        "
        _res="$(sqlite_run "${sql}")"
    fi
}
