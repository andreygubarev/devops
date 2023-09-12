#!/usr/bin/env bash
API_ANSIBLE_V1ALPHA1_PATH="$INFRACTL_PATH/plugins/api/ansible/v1alpha1"
declare -A api_ansible_v1alpha1

### Manifest ##################################################################
api_ansible_v1alpha1["manifest"]=api_ansible_v1alpha1__manifest
api_ansible_v1alpha1__manifest() {
    if [ ! -f "$1" ]; then
        log error "ansible.com/v1alpha1/manifest: manifest not found: $1"
        return
    fi

    if [ -z "$2" ]; then
        log error "ansible.com/v1alpha1/manifest: query not found"
        return
    fi

    local -r v=$(yq "$2" < "$1")
    if [ "$v" == "null" ]; then
        log warn "ansible.com/v1alpha1/manifest: field not found: $2"
        return
    fi
    echo "$v"
}

### Settings ##################################################################
api_ansible_v1alpha1["settings_ansible_version"]=api_ansible_v1alpha1__settings_ansible_version
api_ansible_v1alpha1__settings_ansible_version() {
    api_ansible_v1alpha1__manifest "$1" '.metadata.annotations["ansible.com/version"]'
}

api_ansible_v1alpha1["settings_ansible_roles"]=api_ansible_v1alpha1__settings_ansible_roles
api_ansible_v1alpha1__settings_ansible_roles() {
    api_ansible_v1alpha1__manifest "$1" '.metadata.annotations["ansible.com/roles"]'
}

api_ansible_v1alpha1["settings_python_version"]=api_ansible_v1alpha1__settings_python_version
api_ansible_v1alpha1__settings_python_version() {
    api_ansible_v1alpha1__manifest "$1" '.metadata.annotations["python.org/version"]'
}

api_ansible_v1alpha1["settings_python_requirements"]=api_ansible_v1alpha1__settings_python_requirements
api_ansible_v1alpha1__settings_python_requirements() {
    local -r v=$(api_ansible_v1alpha1__manifest "$1" '.metadata.annotations["python.org/requirements"]')
    echo "$v" | xargs echo
}


### Inventory #################################################################
api_ansible_v1alpha1["inventory"]=api_ansible_v1alpha1__inventory
api_ansible_v1alpha1__inventory() {
    local -r v=$(api_ansible_v1alpha1__manifest "$1" '.spec.inventory')
    echo "--inventory $v"
}

### Playbook ##################################################################
api_ansible_v1alpha1["playbook"]=api_ansible_v1alpha1__playbook
api_ansible_v1alpha1__playbook() {
    api_ansible_v1alpha1__manifest "$1" '.spec.playbook'
}

api_ansible_v1alpha1["extra_vars"]=api_ansible_v1alpha1__extra_vars
api_ansible_v1alpha1__extra_vars() {
    local -r v=$(api_ansible_v1alpha1__manifest "$1" '.spec.extra_vars')
    if [ -z "$v" ]; then
        log warn "ansible.com/v1alpha1/extra_vars: extra_vars field not found"
        return
    fi

    local f="$2/extra_vars.yaml"
    echo "$v" > "$f"
    echo "--extra-vars @$f"
}

api_ansible_v1alpha1["dryrun"]=api_ansible_v1alpha1__dryrun
api_ansible_v1alpha1__dryrun() {
    if [ "$INFRACTL_DRYRUN" == "true" ]; then
        echo "--check"
    fi
}

### Template ##################################################################
api_ansible_v1alpha1["template_config"]=api_ansible_v1alpha1__template_config
api_ansible_v1alpha1__template_config() {
    cat <<- EOF > "$1"
default_context:
    name: "$manifest_name"
    version: "$manifest_version"
    ansible_inventory: "$(api "inventory" "$manifest_path")"
    ansible_roles_path: "$(api "settings_ansible_roles" "$manifest_path")"
    ansible_version: "$(api "settings_ansible_version" "$manifest_path")"
    python_version: "$(api "settings_python_version" "$manifest_path")"
    python_requirements: "$(api "settings_python_requirements" "$manifest_path")"
EOF
}

api_ansible_v1alpha1["template"]=api_ansible_v1alpha1__template
api_ansible_v1alpha1__template() {
    local -r template_path="$API_ANSIBLE_V1ALPHA1_PATH/template"
    local -r template_config="$1"
    local -r template_output="$2"

    template_render "$template_path" "$template_config" "$template_output"
}
