#!/usr/bin/env bash
declare -A api_ansible_v1alpha1

### Settings ##################################################################
# shellcheck disable=SC2034
api_ansible_v1alpha1["get_version"]=api_ansible_v1alpha1_get_version
api_ansible_v1alpha1_get_version() {
    local -r v=$(yq '.metadata.annotations["ansible.com/version"]' < "$1")
    if [ "$v" == "null" ]; then
        echo ""
    else
        echo "$v"
    fi
}

### Inventory #################################################################
# shellcheck disable=SC2034
api_ansible_v1alpha1["get_inventory"]=api_ansible_v1alpha1_get_inventory
api_ansible_v1alpha1_get_inventory() {
    local -r v=$(yq '.spec.ansible_inventory' < "$1")
    if [ "$v" == "null" ]; then
        echo ""
    else
        echo "--inventory $v"
    fi
}

### Playbook ##################################################################
# shellcheck disable=SC2034
api_ansible_v1alpha1["get_playbook"]=api_ansible_v1alpha1_get_playbook
api_ansible_v1alpha1_get_playbook() {
    local -r v=$(yq '.spec.ansible_playbook' < "$1")
    if [ "$v" == "null" ]; then
        echo "Ansible playbook not found"
        exit 1
    else
        echo "$v"
    fi
}
