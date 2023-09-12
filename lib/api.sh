#!/usr/bin/env bash

### Functions #################################################################

api_set_context() {
    local -r apiversion="$1"
    log info "setting api: $apiversion"

    declare -gA api
    case "$apiversion" in
        ansible.com/v1alpha1)
            # shellcheck disable=SC2154
            for key in "${!api_ansible_v1alpha1[@]}"; do
                api["$key"]="${api_ansible_v1alpha1[$key]}"
                log debug "api[$key] -> ${api_ansible_v1alpha1[$key]}"
            done
            ;;
        *)
            echo "Unknown API: $apiversion"
            exit 1
            ;;
    esac
}

api_call() {
    local -r api_func="$1"
    shift

    "${api[$api_func]}" "$@"
}
