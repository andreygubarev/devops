#!/usr/bin/env bash
API_ANSIBLE_V1ALPHA1_PATH="$INFRACTL_PATH/plugins/api/ansible/v1alpha1"
declare -gA api_ansible_v1alpha1

### Settings ##################################################################
api_ansible_v1alpha1["settings_ansible_version"]=api_ansible_v1alpha1__settings_ansible_version
api_ansible_v1alpha1__settings_ansible_version() {
    manifest_query '.metadata.annotations["ansible.com/version"]'
}

api_ansible_v1alpha1["settings_ansible_roles"]=api_ansible_v1alpha1__settings_ansible_roles
api_ansible_v1alpha1__settings_ansible_roles() {
    manifest_query '.metadata.annotations["ansible.com/roles"]'
}

api_ansible_v1alpha1["settings_python_version"]=api_ansible_v1alpha1__settings_python_version
api_ansible_v1alpha1__settings_python_version() {
    manifest_query '.metadata.annotations["python.org/version"]'
}

api_ansible_v1alpha1["settings_python_requirements"]=api_ansible_v1alpha1__settings_python_requirements
api_ansible_v1alpha1__settings_python_requirements() {
    manifest_query '.metadata.annotations["python.org/requirements"]' | xargs echo
}


### Inventory #################################################################
api_ansible_v1alpha1["inventory"]=api_ansible_v1alpha1__inventory
api_ansible_v1alpha1__inventory() {
    local -r v=$(manifest_query'.spec.inventory')
    if [ -z "$v" ]; then
        log warn "ansible.com/v1alpha1/inventory: inventory field not found"
        return
    fi
    echo "--inventory $v"
}

### Playbook ##################################################################
api_ansible_v1alpha1["playbook"]=api_ansible_v1alpha1__playbook
api_ansible_v1alpha1__playbook() {
    local -r v=$(manifest_query '.spec.playbook')
    if [ -z "$v" ]; then
        log error "ansible.com/v1alpha1/playbook: playbook field not found"
        return
    fi
    echo "$v"
}

api_ansible_v1alpha1["extra_vars"]=api_ansible_v1alpha1__extra_vars
api_ansible_v1alpha1__extra_vars() {
    local -r v=$(manifest_query '.spec.extra_vars')
    if [ -z "$v" ]; then
        log warn "ansible.com/v1alpha1/extra_vars: extra_vars field not found"
        return
    fi

    local f="$1/extra_vars.yaml"
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
    name: "$(manifest_name)"
    version: "$(manifest_version)"
    ansible_inventory: "$(api_ansible_v1alpha1__inventory)"
    ansible_roles_path: "$(api_ansible_v1alpha1__settings_ansible_roles)"
    ansible_version: "$(api_ansible_v1alpha1__settings_ansible_version)"
    python_version: "$(api_ansible_v1alpha1__settings_python_version)"
    python_requirements: "$(api_ansible_v1alpha1__settings_python_requirements)"
EOF
}

api_ansible_v1alpha1["template"]=api_ansible_v1alpha1__template
api_ansible_v1alpha1__template() {
    local -r template_path="$API_ANSIBLE_V1ALPHA1_PATH/template"
    local -r template_config="$1"
    local -r template_output="$2"

    template_render "$template_path" "$template_config" "$template_output"
}
