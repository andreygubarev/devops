#!/usr/bin/env bash
API_TERRAFORM_V1ALPHA1_PATH="$INFRACTL_PATH/plugins/api/terraform/v1alpha1"
declare -gA api_terraform_v1alpha1

### Settings ##################################################################
api_terraform_v1alpha1["settings_terraform_version"]=api_terraform_v1alpha1__settings_terraform_version
api_terraform_v1alpha1__settings_terraform_version() {
    resource::query '.metadata.annotations["terraform.io/version"]'
}

api_terraform_v1alpha1["settings_terragrunt_version"]=api_terraform_v1alpha1__settings_terragrunt_version
api_terraform_v1alpha1__settings_terragrunt_version() {
    resource::query '.metadata.annotations["terragrunt.gruntwork.io/version"]'
}

api_terraform_v1alpha1["labels"]=api_terraform_v1alpha1__labels
api_terraform_v1alpha1__labels() {
    local -r v=$(resource::query '.metadata.labels | keys | .[]')
    echo "$v" | xargs echo
}

api_terraform_v1alpha1["settings_remote_state_backend"]=api_terraform_v1alpha1__settings_remote_state_backend
api_terraform_v1alpha1__settings_remote_state_backend() {
    resource::query '.metadata.annotations["terraform.io/remote-state-backend"]'
}

api_terraform_v1alpha1["settings_remote_state_locking"]=api_terraform_v1alpha1__settings_remote_state_locking
api_terraform_v1alpha1__settings_remote_state_locking() {
    resource::query '.metadata.annotations["terraform.io/remote-state-locking"]'
}

api_terraform_v1alpha1["settings_remote_state_region"]=api_terraform_v1alpha1__settings_remote_state_region
api_terraform_v1alpha1__settings_remote_state_region() {
    resource::query '.metadata.annotations["terraform.io/remote-state-region"]'
}

### Runtime ###################################################################
api_terraform_v1alpha1["system_terraform_version"]=api_terraform_v1alpha1__system_terraform_version
api_terraform_v1alpha1__system_terraform_version() {
    if command -v terraform >/dev/null 2>&1; then
        terraform version | head -n1 | cut -d' ' -f2 | cut -d'v' -f2
    else
        log info "terraform.io/v1alpha1/system_terraform_version: terraform not found"
    fi
}

api_terraform_v1alpha1["set_terraform_version"]=api_terraform_v1alpha1__set_terraform_version
api_terraform_v1alpha1__set_terraform_version() {
    local -r terraform_version=$(api_terraform_v1alpha1__settings_terraform_version)
    local -r current_terraform_version=$(api_terraform_v1alpha1__system_terraform_version)

    if [ "$terraform_version" != "$current_terraform_version" ]; then
        if ! command -v tfenv >/dev/null 2>&1; then
            log error "terraform.io/v1alpha1/set_terraform_version: tfenv not found"
            return
        fi
        tfenv install "$terraform_version"
        tfenv use "$terraform_version"
    fi
}

api_terraform_v1alpha1["system_terragrunt_version"]=api_terraform_v1alpha1__system_terragrunt_version
api_terraform_v1alpha1__system_terragrunt_version() {
    if command -v terragrunt >/dev/null 2>&1; then
        terragrunt --version | awk '{print $3}' | cut -d'v' -f2
    else
        log info "terraform.io/v1alpha1/system_terragrunt_version: terragrunt not found"
    fi
}

api_terraform_v1alpha1["set_terragrunt_version"]=api_terraform_v1alpha1__set_terragrunt_version
api_terraform_v1alpha1__set_terragrunt_version() {
    local -r terragrunt_version=$(api_terraform_v1alpha1__settings_terragrunt_version)
    local -r current_terragrunt_version=$(api_terraform_v1alpha1__system_terragrunt_version)

    if [ "$terragrunt_version" != "$current_terragrunt_version" ]; then
        if ! command -v tfenv >/dev/null 2>&1; then
            log error "terraform.io/v1alpha1/set_terragrunt_version: tgenv not found"
            return
        fi

        tgenv install "$terragrunt_version"
        tgenv use "$terragrunt_version"
    fi
}

### Template ##################################################################
api::template::render_config() {
    cat <<- EOF > "$1"
default_context:
    name: "$(resource::metadata::name)"
    version: "$(resource::version)"
    terraform_metadata_labels: "$(api_terraform_v1alpha1__labels)"
    terraform_remote_state_backend: "$(api_terraform_v1alpha1__settings_remote_state_backend)"
    terraform_remote_state_locking: "$(api_terraform_v1alpha1__settings_remote_state_locking)"
    terraform_remote_state_region: "$(api_terraform_v1alpha1__settings_remote_state_region)"
    terraform_version: "$(api_terraform_v1alpha1__settings_terraform_version)"
    terragrunt_version: "$(api_terraform_v1alpha1__settings_terragrunt_version)"
EOF
}

api::template::render() {
    local -r template_path="$API_TERRAFORM_V1ALPHA1_PATH/template"
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

    api::set_terraform_version
    api::set_terragrunt_version

    if [ "$INFRACTL_DRYRUN" == "true" ]; then
        log info "running: terragrunt plan"
        terragrunt plan
    else
        log info "running: terragrunt apply"
        terragrunt apply
    fi

    popd
}
