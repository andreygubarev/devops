#!/usr/bin/env bash
set -euo pipefail

### Globals ###################################################################
INFRACTL_PATH="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
INFRACTL_DRYRUN="${INFRACTL_DRYRUN:-false}"

### Libarary ##################################################################

# shellcheck source=lib/utils.sh
source "$INFRACTL_PATH/lib/utils.sh"

# shellcheck source=lib/logging.sh
source "$INFRACTL_PATH/lib/logging.sh"

# shellcheck source=lib/manifest.sh
source "$INFRACTL_PATH/lib/manifest.sh"

# shellcheck source=lib/build.sh
source "$INFRACTL_PATH/lib/build.sh"

# shellcheck source=lib/api.sh
source "$INFRACTL_PATH/lib/api.sh"

### Command line #############################################################

command_build() {
    while getopts ":f:" opt; do
    case $opt in
        f) opt_f="$OPTARG" ;;
        \?)
            log critical "invalid option: -$OPTARG"
            ;;
        :)
            log critical "option -$OPTARG requires an argument."
            ;;
    esac
    done

    if [ -n "${opt_f:-}" ]; then
        new_manifest "$opt_f"
    else
        log critical "usage: $0 build -f <manifest>"
    fi

    build
}

command_run() {
    while getopts ":f:n" opt; do
        case $opt in
            f)
                opt_f="$OPTARG"
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

    if [ -n "${opt_f:-}" ]; then
        new_manifest "$opt_f"
    else
        log critical "usage: $0 run [-n] -f <manifest>"
    fi

    if [ -n "${opt_n:-}" ]; then
        INFRACTL_DRYRUN="true"
    fi

    api::run
}

command_clean() {
    while getopts ":f:" opt; do
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

    if [ -n "${opt_f:-}" ]; then
        new_manifest "$opt_f"
    else
        log critical "usage: $0 clean -f <manifest>"
    fi

    rm -rf "$(build_dist)"
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
