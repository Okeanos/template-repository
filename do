#!/usr/bin/env bash

# script-template.sh https://gist.github.com/m-radzikowski/53e0b39e9a59a1518990e76c2bff8038 by Maciej Radzikowski
# MIT License https://gist.github.com/m-radzikowski/d925ac457478db14c2146deadd0020cd
# https://betterdev.blog/minimal-safe-bash-script-template/

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

# shellcheck disable=SC2034
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

usage() {
	cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [-f] -p param_value arg1 [arg2...]

Script description here. With a lot more text to test how columns behave

EOF
	# use column to format the flag & parameter output consistently
	cat <<EOF | column -t -s ':'
Available options:

: -h, --help: Print this help and exit
: -v, --verbose: Print script debug info
: -f, --flag: Some flag description
: -p, --param: Some param description
: arg1: Some argument description
EOF
	# Find all extension scripts in the `scripts` folder and extract their descriptions
	# in order to list & explain them here when invoking the `do`-script.
	#
	# The expected format of documentation for extension scripts to appear here is:
	# ## extension-name <required-parameter/flag> [<optional-parameter/flag>: description
	# or alternatively as multi-line statement:
	# ## extension-name: description
	# ## : -l, --long-form-param: Description of the parameter
	# ## : -[o, --optional-param]: Description of the parameter
	find "${script_dir}/scripts/" -maxdepth 1 -type f -exec cat {} + |
		sed -nE "s/^##(.*):(.*)/\1:\2/p" |
		column -t -s '::'
	exit 1 # ensure scripts that encounter the help message do not unexpectedly proceed
}

cleanup() {
	trap - SIGINT SIGTERM ERR EXIT
	# script cleanup here
}

setup_colors() {
	if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
		# shellcheck disable=SC2034
		NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
	else
		# shellcheck disable=SC2034
		NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
	fi
}

msg() {
	echo >&2 -e "${1-}"
}

die() {
	local msg=${1}
	local code=${2-1} # default exit status 1
	msg "${msg}"
	exit "${code}"
}

parse_params() {
	# default values of variables set from params
	sub_function=''
	flag=0
	param=''

	while :; do
		case "${1-}" in
		-h | --help) usage ;;
		-v | --verbose) set -x ;;
		--no-color) NO_COLOR=1 ;;
		-f | --flag) flag=1 ;; # example flag
		-p | --param)          # example named parameter
			param="${2-}"
			shift
			;;
		-?*) die "Unknown option: $1" ;;
		*) break ;;
		esac
		shift
	done

	# shellcheck disable=SC2034
	args=("$@")
	# Parse extension function from args
	sub_function="${args[0]:-}"
	args=("${args[@]:1}")
	sub_function_script="${script_dir}/scripts/${sub_function}"

	# check required params and arguments
	[[ -z "${param-}" ]] && die "Missing required parameter: param"
	[[ ${#args[@]} -eq 0 ]] && die "Missing script arguments"
	[[ ! -x "${sub_function_script}" ]] && die "The specified function does not exist or is not executable"

	return 0
}

parse_params "$@"
setup_colors

# script logic here

msg "${RED}Read parameters:${NOFORMAT}"
msg "- flag: ${flag}"
msg "- param: ${param}"
msg "- arguments: ${args[*]-}"

# Invoke sub function / extension
"${sub_function_script}" "${args[@]}"
