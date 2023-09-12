#!/usr/bin/env bash

### Functions #################################################################

api_set_context() {
    local -r apiversion="$1"
    log info "setting api: $apiversion"

    declare -gA apis
    case "$apiversion" in
        ansible.com/v1alpha1)
            # shellcheck disable=SC2154
            for key in "${!api_ansible_v1alpha1[@]}"; do
                apis["$key"]="${api_ansible_v1alpha1[$key]}"
                log debug "apis[$key] -> ${api_ansible_v1alpha1[$key]}"
            done
            ;;
        *)
            echo "Unknown API: $apiversion"
            exit 1
            ;;
    esac
}

api() {
    local -r api_func="$1"
    shift

    if [ -z "${apis[$api_func]+exists}" ]; then
        log critical "API does not exist: $api_func"
        return
    fi

    "${apis[$api_func]}" "$@"
}
