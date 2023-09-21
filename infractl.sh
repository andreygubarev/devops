#!/usr/bin/env bash
set -euo pipefail

### Globals ###################################################################
INFRACTL_PATH="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
INFRACTL_WORKSPACE=".infractl"

INFRACTL_DRYRUN="${INFRACTL_DRYRUN:-false}"

### Libarary ##################################################################

# shellcheck source=lib/utils.sh
source "$INFRACTL_PATH/lib/utils.sh"

# shellcheck source=lib/logging.sh
source "$INFRACTL_PATH/lib/logging.sh"

# shellcheck source=lib/workspace.sh
source "$INFRACTL_PATH/lib/workspace.sh"

# shellcheck source=lib/resource.sh
source "$INFRACTL_PATH/lib/resource.sh"

# shellcheck source=lib/build.sh
source "$INFRACTL_PATH/lib/build.sh"

# shellcheck source=lib/api.sh
source "$INFRACTL_PATH/lib/api.sh"

### Command line #############################################################

command_build() {
    while getopts ":f:t:" opt; do
        case $opt in
            f)
                opt_f="$OPTARG"
                ;;
            t)
                opt_t="$OPTARG"
                ;;
            \?)
                log critical "invalid option: -$OPTARG"
                ;;
            :)
                log critical "option -$OPTARG requires an argument."
                ;;
        esac
    done

    if [ -z "${opt_f:-}" ]; then
        opt_f="Infrafile"
    fi

    if [ -z "${opt_t:-}" ]; then
        opt_t=""
    fi

    workspace::new "$opt_f"
    for doc in $(workspace::documents); do
        workspace::set "$doc"
        if [ -z "${opt_t}" ]; then
            build::new
        elif [ "${opt_t}" == "$(resource::metadata::name)" ]; then
            build::new
        fi
    done
}

command_run() {
    while getopts ":f:t:n" opt; do
        case $opt in
            f)
                opt_f="$OPTARG"
                ;;
            t)
                opt_t="$OPTARG"
                ;;

            n)
                opt_n=true
                ;;
            \?)
                log critical "invalid option: -$OPTARG"
                ;;
            :)
                log critical "option -$OPTARG requires an argument."
                ;;
        esac
    done

    if [ -n "${opt_n:-}" ]; then
        INFRACTL_DRYRUN="true"
    fi

    if [ -z "${opt_f:-}" ]; then
        opt_f="Infrafile"
    fi

    if [ -z "${opt_t:-}" ]; then
        opt_t=""
    fi

    workspace::new "$opt_f"
    for doc in $(workspace::documents); do
        workspace::set "$doc"
        if [ -z "${opt_t}" ]; then
            api::run
        elif [ "${opt_t}" == "$(resource::metadata::name)" ]; then
            api::run
        fi
    done
}

command_clean() {
    while getopts ":f" opt; do
    case $opt in
        f)
            opt_f="$OPTARG"
            ;;
        \?)
            log critical "invalid option: -$OPTARG"
            ;;
        :)
            log critical "option -$OPTARG requires an argument."
            ;;
    esac
    done

    if [ -z "${opt_f:-}" ]; then
        opt_f="Infrafile"
    fi

    workspace::new "$opt_f"
    rm -rf "$(workspace::dir)"
}

command_install() {
    log info "installing infractl"
}

if [ $# -lt 1 ]; then
    log critical "usage: $0 {build|run|clean|install}"
fi

case "$1" in
    build)
        shift
        command_build "$@"
        ;;
    run)
        shift
        command_run "$@"
        ;;
    clean)
        shift
        command_clean "$@"
        ;;
    install)
        shift
        command_install "$@"
        ;;
    *)
        log critical "usage: $0 {build|run|clean|install}"
        ;;
esac
