#!/usr/bin/env bash
# namespace: ansible

### Settings ##################################################################
ansible::settings::version() {
    resource::query '.metadata.annotations["ansible.com/version"]'
}

ansible::settings::roles_path() {
    resource::query '.metadata.annotations["ansible.com/roles_path"]'
}

ansible::settings::python_version() {
    resource::query '.metadata.annotations["python.org/version"]'
}

ansible::settings::python_requirements() {
    resource::query '.metadata.annotations["python.org/requirements"]' | yq -r '.[]' | xargs echo
}


### Inventory #################################################################
ansible::inventory() {
    local -r v=$(resource::query '.spec.inventory')
    if [ -z "$v" ]; then
        log warn "ansible.com/v1alpha1/inventory: inventory field not found"
        return
    fi
    echo "--inventory $v"
}

### Playbook ##################################################################
ansible::playbook() {
    local -r v=$(resource::query '.spec.playbook')
    if [ -z "$v" ]; then
        log error "ansible.com/v1alpha1/playbook: playbook field not found"
        return
    fi
    echo "$v"
}

ansible::extra_vars() {
    local -r v=$(resource::query '.spec.extra_vars')
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
api::template::render_config() {
    cat <<- EOF > "$1"
default_context:
    name: "$(resource::metadata::name)"
    version: "$(resource::version)"
    ansible_inventory: "$(ansible::inventory)"
    ansible_roles_path: "$(ansible::settings::roles_path)"
    ansible_version: "$(ansible::settings::version)"
    python_version: "$(ansible::settings::python_version)"
    python_requirements: "$(ansible::settings::python_requirements)"
EOF
}

api::template::render() {
    local -r template_path="$INFRACTL_PATH/plugins/api/ansible/v1alpha1/template"
    local -r template_config="$1"
    local -r template_output="$2"

    utils::render_template "$template_path" "$template_config" "$template_output"
}

### Runtime ###################################################################
api::environment() {
    echo ""
}

api::run() {
    build_output=$(build::new)
    pushd "$build_output"
    if [ -f ".envrc" ]; then
        direnv allow .
        eval "$(direnv export bash)"
    fi

    echo "ansible-playbook $(ansible::inventory) $(ansible::dry_run) $(ansible::extra_vars "$(build::path::output)") src/$(ansible::playbook)"
    popd
}
