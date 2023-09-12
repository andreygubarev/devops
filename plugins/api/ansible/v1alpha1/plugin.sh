#!/usr/bin/env bash
declare -A api_ansible_v1alpha1

### Settings ##################################################################
__api_ansible_v1alpha1_get_version() {
    local -r v=$(yq '.metadata.annotations["ansible.com/version"]' < "$1")
    if [ "$v" == "null" ]; then
        echo ""
    else
        echo "$v"
    fi
}

# shellcheck disable=SC2034
api_ansible_v1alpha1["get_version"]=__api_ansible_v1alpha1_get_version

### Functions #################################################################
__api_ansible_v1alpha1_get_inventory() {
    local -r v=$(yq '.spec.ansible_inventory' < "$1")
    if [ "$v" == "null" ]; then
        echo ""
    else
        echo "--inventory $v"
    fi
}

# shellcheck disable=SC2034
api_ansible_v1alpha1["get_inventory"]=__api_ansible_v1alpha1_get_inventory
