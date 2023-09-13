#!/usr/bin/env bash

INFRACTL_LOGLEVEL="${INFRACTL_LOGLEVEL:-warn}"

if [ "${INFRACTL_LOGLEVEL}" == "trace" ]; then
    set -x
fi

log() {
    local loglevel="$1"
    shift

    case "$INFRACTL_LOGLEVEL" in
        "trace")
            level=0
            ;;
        "debug")
            level=10
            ;;
        "info")
            level=20
            ;;
        "warn")
            level=30
            ;;
        "error")
            level=40
            ;;
        "critical")
            level=50
            ;;
        *)
            echo "Invalid log level: $loglevel"
            exit 1
            ;;
    esac

    local message="$*"

    if [ "$loglevel" == "trace" ] && [ "$level" -le 0 ]; then
        echo "DEBUG: $message" >&2
    elif [ "$loglevel" == "debug" ] && [ "$level" -le 10 ]; then
        echo "DEBUG: $message" >&2
    elif [ "$loglevel" == "info" ] && [ "$level" -le 20 ]; then
        echo "INFO: $message" >&2
    elif [ "$loglevel" == "warn" ] && [ "$level" -le 30 ]; then
        echo "WARNING: $message" >&2
    elif [ "$loglevel" == "error" ] && [ "$level" -le 40 ]; then
        echo "ERROR: $message" >&2
        exit 1
    elif [ "$loglevel" == "critical" ] && [ "$level" -le 50 ]; then
        echo "CRITICAL: $message" >&2
        exit 1
    fi
}
