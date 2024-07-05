#!/usr/bin/env sh

#######################################
# Return the escape sequence for the standard 8 colors.
#
# Arguments:
#   $1: color
# Colors:
# 	default | black | red | green |
# 	yellow | blue | magenta | cyan |
# 	white | reset
# Outputs:
# 	Escaped/reset color
get_color() {
	local color
	if [ "$#" -gt 0 ]; then
		color=${1}
	fi
	case "${color}" in
	default)
		printf "%s" "\e[m"
		return
		;;
	black)
		printf "%s" "\e[1;30m"
		return
		;;
	red)
		printf "%s" "\e[1;31m"
		return
		;;
	green)
		printf "%s" "\e[1;32m"
		return
		;;
	yellow)
		printf "%s" "\e[1;33m"
		return
		;;
	blue)
		printf "%s" "\e[1;34m"
		return
		;;
	magenta)
		printf "%s" "\e[1;35m"
		return
		;;
	cyan)
		printf "%s" "\e[1;36m"
		return
		;;
	white)
		printf "%s" "\e[1;37m"
		return
		;;
	reset)
		printf "%s" "\e[m"
		return
		;;
	*)
		printf "%s" "\e[m"
		return
		;;
	esac
}

#######################################
# Prints a single line with color.
#
# Arguments:
#   $1: [color] optional, defaults to default
# 	$2: text
# Outputs:
# 	Prints a single line using printf
print_color() {
	local color
	local text
	if [ "$#" -gt 1 ]; then
		color="${1}"
		shift
		text="${1}"
	elif [ "$#" = 1 ]; then
		color="default"
		text="${1}"
	else
		return
	fi
	local prefix
	prefix="$(get_color "${color}")"
	local suffix
	suffix="$(get_color reset)"
	printf '%b\n' "${prefix}${text}${suffix}"
}

#######################################
# Returns the log level based on a string
#
# Arguments:
# 	$1: level
# Outputs:
#  Log level #, lower is more important
sagedot_log_level() {
	if [ "$#" -lt 1 ]; then
		echo 0
		return
	fi
	local level
	level="${1}"
	case "${level}" in
	error)
		echo 1
		return
		;;
	warning)
		echo 2
		return
		;;
	success | notice | info | default)
		echo 3
		return
		;;
	debug)
		echo 4
		return
		;;
	trace)
		echo 5
		return
		;;
	esac

	echo 0
	return
}

# The # level of the current Log level
SAGEDOT_LOGGER_LEVEL=$(sagedot_log_level "${SAGEDOT_LOG_LEVEL}")
# Has the logger been setup or not?
SAGEDOT_LOGGER_SETUP=false

#######################################
# Logs a message to the log file
#
# Globals:
#	SAGEDOT_LOGGER_SETUP
#	SAGEDOT_LOGGER_LEVEL
# Arguments:
# 	$1: [level] optional
#	$2: text
# Outputs:
# 	Appends the log file with the provied text along with the date.
sagedot_log() {
	local level
	local text
	if [ "$#" -gt 1 ]; then
		level="${1}"
		text="${2}"
	elif [ "$#" = 1 ]; then
		level="default"
		text="${1}"
	else
		return
	fi
	if [ "${SAGEDOT_LOGGER_SETUP}" = false ]; then
		mkdir -p "${SAGEDOT_LOG_FOLDER}"
		sagedot_logs_clean
		SAGEDOT_LOGGER_SETUP=true
	fi
	local log_level
	log_level=$(sagedot_log_level "${level}")
	local log_time
	log_time="$(date "+${SAGEDOT_LOG_FMT}")"
	# This has to be an integer expression, so diable quotes
	# shellcheck disable=SC2086
	if [ ${log_level} -le ${SAGEDOT_LOGGER_LEVEL} ]; then
		case "${level}" in
		error)
			echo "[${log_time}][ERROR] ${text}" >>"${SAGEDOT_LOG_FILE}"
			;;
		warning)
			echo "[${log_time}][WARN] ${text}" >>"${SAGEDOT_LOG_FILE}"
			;;
		success | notice | info | default)
			echo "[${log_time}][INFO] ${text}" >>"${SAGEDOT_LOG_FILE}"
			;;
		debug)
			echo "[${log_time}][DEBUG] ${text}" >>"${SAGEDOT_LOG_FILE}"
			;;
		trace)
			echo "[${log_time}][TRACE] ${text}" >>"${SAGEDOT_LOG_FILE}"
			;;
		esac
	fi
}

#######################################
# Logs a error message
#
# Arguments:
# 	$1: text
# Outputs:
# 	Adds a log to the log file with the [ERROR] tag
log_error() {
	sagedot_log "error" "$*"
}

#######################################
# Logs a warning message
#
# Arguments:
# 	$1: text
# Outputs:
# 	Adds a log to the log file with the [WARN] tag
log_warning() {
	sagedot_log "warning" "$*"
}

#######################################
# Logs a info message
#
# Arguments:
# 	$1: text
# Outputs:
# 	Adds a log to the log file with the [INFO] tag
log_info() {
	sagedot_log "info" "$*"
}

#######################################
# Logs a debug message
#
# Arguments:
# 	$1: text
# Outputs:
# 	Adds a log to the log file with the [DEBUG] tag
log_debug() {
	sagedot_log "debug" "$*"
}

#######################################
# Logs a trace message
#
# Arguments:
# 	$1: text
# Outputs:
# 	Adds a log to the log file with the [TRACE] tag
log_trace() {
	sagedot_log "trace" "$*"
}

#######################################
# Limits the amount of log files in the log folder
#
# Globals:
#	SAGEDOT_LOG_FOLDER
#	SAGEDOT_LOG_MAX
# Outputs:
# 	Removes extra log files
sagedot_logs_clean() {
	# Not sure if this is a smart way to do this, but it works.
	# We loop twice to get the count, then again to delete the first files.
	local files=0
	for _file in "${SAGEDOT_LOG_FOLDER}"/*.log; do
		files=$((files + 1))
	done
	for file in "${SAGEDOT_LOG_FOLDER}"/*.log; do
		# This is an integer expression so disable quotes
		# shellcheck disable=SC2086,SC2248
		if [ ${files} -ge ${SAGEDOT_LOG_MAX} ]; then
			rm "${file}"
			files=$((files - 1))
		else
			break
		fi
	done
}

#######################################
# Prints a defualt message
#
# Arguments:
# 	$1: text
# Outputs:
# 	Prints a line with the default color
print_default() {
	print_color "$*"
	log_info "$*"
}

#######################################
# Prints a info message
#
# Arguments:
# 	$1: text
# Outputs:
# 	Prints a line colored cyan
print_info() {
	print_color cyan "$*"
	log_info "$*"
}

#######################################
# Prints a notice message
#
# Arguments:
# 	$1: text
# Outputs:
# 	Prints a line colored magenta
print_notice() {
	print_color magenta "$*"
	log_info "$*"
}

#######################################
# Prints a success message
#
# Arguments:
# 	$1: text
# Outputs:
# 	Prints a line colored green
print_success() {
	print_color green "$*"
	log_info "$*"
}

#######################################
# Prints a warning message
#
# Arguments:
# 	$1: text
# Outputs:
# 	Prints a line colored yellow
print_warning() {
	print_color yellow "$*"
	log_warning "$*"
}

#######################################
# Prints a error message
#
# Arguments:
# 	$1: text
# Outputs:
# 	Prints a line colored red
print_error() {
	print_color red "$*"
	log_error "$*"
}

#######################################
# Prints a debug message
#
# Arguments:
# 	$1: text
# Outputs:
# 	Prints a line colored blue
print_debug() {
	print_color blue "$*"
	log_debug "$*"
}
