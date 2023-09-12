#!/usr/bin/env bash
declare -A api_ansible_v1alpha1

### Settings ##################################################################
api_ansible_v1alpha1["settings_ansible_version"]=api_ansible_v1alpha1_settings_ansible_version
api_ansible_v1alpha1_settings_ansible_version() {
    if [ ! -f "$1" ]; then
        log error "ansible.com/v1alpha1/settings_ansible_version: manifest not found: $1"
        return
    fi

    local -r v=$(yq '.metadata.annotations["ansible.com/version"]' < "$1")
    if [ "$v" == "null" ]; then
        return
    fi
    echo "$v"
}

api_ansible_v1alpha1["settings_ansible_roles"]=api_ansible_v1alpha1_settings_ansible_roles
api_ansible_v1alpha1_settings_ansible_roles() {
    if [ ! -f "$1" ]; then
        log error "ansible.com/v1alpha1/settings_ansible_roles: manifest not found: $1"
        return
    fi

    local -r v=$(yq '.metadata.annotations["ansible.com/roles"]' < "$1")
    if [ "$v" == "null" ]; then
        log warn "ansible.com/v1alpha1/settings_ansible_roles: roles not found"
        return
    fi
    echo "$v"
}


api_ansible_v1alpha1["settings_python_version"]=api_ansible_v1alpha1_settings_python_version
api_ansible_v1alpha1_settings_python_version() {
    if [ ! -f "$1" ]; then
        log error "ansible.com/v1alpha1/settings_python_version: manifest not found: $1"
        return
    fi

    local -r v=$(yq '.metadata.annotations["python.org/version"]' < "$1")
    if [ "$v" == "null" ]; then
        log warn "ansible.com/v1alpha1/settings_python_version: python version not found"
        return
    fi
    echo "$v"
}

api_ansible_v1alpha1["settings_python_requirements"]=api_ansible_v1alpha1_settings_python_requirements
api_ansible_v1alpha1_settings_python_requirements() {
    if [ ! -f "$1" ]; then
        log error "ansible.com/v1alpha1/settings_python_requirements: manifest not found: $1"
        return
    fi

    local -r v=$(yq '.metadata.annotations["python.org/requirements"][]' < "$1")
    if [ "$v" == "null" ]; then
        log warn "ansible.com/v1alpha1/settings_python_requirements: requirements not found"
        return
    fi
    echo "$v" | xargs echo
}


### Inventory #################################################################
api_ansible_v1alpha1["inventory"]=api_ansible_v1alpha1_inventory
api_ansible_v1alpha1_inventory() {
    if [ ! -f "$1" ]; then
        log error "ansible.com/v1alpha1/inventory: manifest not found: $1"
        return
    fi

    local -r v=$(yq '.spec.inventory' < "$1")
    if [ "$v" == "null" ]; then
        log warn "ansible.com/v1alpha1/inventory: inventory not found"
        return
    fi
    echo "--inventory $v"
}

### Playbook ##################################################################
api_ansible_v1alpha1["playbook"]=api_ansible_v1alpha1_playbook
api_ansible_v1alpha1_playbook() {
    if [ ! -f "$1" ]; then
        log error "ansible.com/v1alpha1/playbook: manifest not found: $1"
        return
    fi

    local -r v=$(yq '.spec.playbook' < "$1")
    if [ "$v" == "null" ]; then
        log error "ansible.com/v1alpha1/playbook: playbook not found"
        return
    fi
    echo "$v"
}

api_ansible_v1alpha1["extra_vars"]=api_ansible_v1alpha1_extra_vars
api_ansible_v1alpha1_extra_vars() {
    if [ ! -f "$1" ]; then
        log error "ansible.com/v1alpha1/extra_vars: manifest not found: $1"
        return
    fi

    if [ ! -d "$2" ]; then
        log error "ansible.com/v1alpha1/extra_vars: build output directory not found: $2"
        return
    fi

    local -r v=$(yq '.spec.extra_vars' < "$1")
    if [ "$v" == "null" ]; then
        log warn "ansible.com/v1alpha1/extra_vars: extra_vars field not found"
        return
    fi

    local f="$2/extra_vars.yaml"
    echo "$v" > "$f"
    echo "--extra-vars @$f"
}

api_ansible_v1alpha1["dryrun"]=api_ansible_v1alpha1_dryrun
api_ansible_v1alpha1_dryrun() {
    if [ "$INFRACTL_DRYRUN" == "true" ]; then
        echo "--check"
    fi
}
