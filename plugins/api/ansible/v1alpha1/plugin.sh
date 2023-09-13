#!/usr/bin/env bash
API_ANSIBLE_V1ALPHA1_PATH="$INFRACTL_PATH/plugins/api/ansible/v1alpha1"
declare -gA api_ansible_v1alpha1

### Settings ##################################################################
ansible::version() {
    manifest::query '.metadata.annotations["ansible.com/version"]'
}

ansible::roles_path() {
    manifest::query '.metadata.annotations["ansible.com/roles_path"]'
}

ansible::python_version() {
    manifest::query '.metadata.annotations["python.org/version"]'
}

ansible::python_requirements() {
    manifest::query '.metadata.annotations["python.org/requirements"]' | yq -r '.[]' | xargs echo
}


### Inventory #################################################################
ansible::inventory() {
    local -r v=$(manifest::query '.spec.inventory')
    if [ -z "$v" ]; then
        log warn "ansible.com/v1alpha1/inventory: inventory field not found"
        return
    fi
    echo "--inventory $v"
}

### Playbook ##################################################################
ansible::playbook() {
    local -r v=$(manifest::query '.spec.playbook')
    if [ -z "$v" ]; then
        log error "ansible.com/v1alpha1/playbook: playbook field not found"
        return
    fi
    echo "$v"
}

ansible::extra_vars() {
    local -r v=$(manifest::query '.spec.extra_vars')
    if [ -z "$v" ]; then
        log warn "ansible.com/v1alpha1/extra_vars: extra_vars field not found"
        return
    fi

    local f="$1/extra_vars.yaml"
    echo "$v" > "$f"
    echo "--extra-vars @$f"
}

ansible::dry_run() {
    if [ "$INFRACTL_DRYRUN" == "true" ]; then
        echo "--check"
    fi
}

### Template ##################################################################
api::render_template_config() {
    cat <<- EOF > "$1"
default_context:
    name: "$(manifest::name)"
    version: "$(manifest::version)"
    ansible_inventory: "$(ansible::inventory)"
    ansible_roles_path: "$(ansible::roles_path)"
    ansible_version: "$(ansible::version)"
    python_version: "$(ansible::python_version)"
    python_requirements: "$(ansible::python_requirements)"
EOF
}

api::render_template() {
    local -r template_path="$API_ANSIBLE_V1ALPHA1_PATH/template"
    local -r template_config="$1"
    local -r template_output="$2"

    utils::render_template "$template_path" "$template_config" "$template_output"
}

### Runtime ###################################################################
api::run() {
    build_output=$(build::new)
    pushd "$build_output"
    direnv allow .
    eval "$(direnv export bash)"

    echo "ansible-playbook $(ansible::inventory) $(ansible::dry_run) $(ansible::extra_vars "$(build::output)") src/$(ansible::playbook)"
    popd
}
