#!/usr/bin/env bash

### Globals ###################################################################
INFRACTL_PLUGINS_PATH="$INFRACTL_PATH/plugins"

### Functions #################################################################
api::new() {
    local -r apiversion="$1"
    log info "api: new $apiversion"

    case "$apiversion" in
        "ansible.com/v1alpha1")
            # shellcheck source=../plugins/api/ansible/v1alpha1/plugin.sh
            source "$INFRACTL_PLUGINS_PATH/api/ansible/v1alpha1/plugin.sh"
            ;;
        "terraform.io/v1alpha1")
            # shellcheck source=../plugins/api/terraform/v1alpha1/plugin.sh
            source "$INFRACTL_PLUGINS_PATH/api/terraform/v1alpha1/plugin.sh"
            ;;
        *)
            echo "Unknown API: $apiversion"
            exit 1
            ;;
    esac
}
