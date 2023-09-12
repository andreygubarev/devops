#!/usr/bin/env bash
API_TERRAFORM_V1ALPHA1_PATH="$INFRACTL_PATH/plugins/api/terraform/v1alpha1"
declare -A api_terraform_v1alpha1

### Settings ##################################################################
api_terraform_v1alpha1["settings_terraform_version"]=api_terraform_v1alpha1__settings_terraform_version
api_terraform_v1alpha1__settings_terraform_version() {
    if [ ! -f "$1" ]; then
        log error "terraform.io/v1alpha1/settings_terraform_version: manifest not found: $1"
        return
    fi

    local -r v=$(yq '.metadata.annotations["terraform.io/version"]' < "$1")
    if [ "$v" == "null" ]; then
        log warn "terraform.io/v1alpha1/settings_terraform_version: terraform version not found"
        return
    fi
    echo "$v"
}
