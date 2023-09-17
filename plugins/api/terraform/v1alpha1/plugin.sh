#!/usr/bin/env bash
### Settings ##################################################################
terraform::settings::version() {
    resource::query '.metadata.annotations["terraform.io/version"]'
}

terraform::settings::terragrunt_version() {
    resource::query '.metadata.annotations["terragrunt.gruntwork.io/version"]'
}

terraform::settings::labels() {
    local -r v=$(resource::query '.metadata.labels | keys | .[]')
    echo "$v" | xargs echo
}

terraform::settings::remote_state_backend() {
    resource::query '.metadata.annotations["terraform.io/remote-state-backend"]'
}

terraform::settings::remote_state_locking() {
    resource::query '.metadata.annotations["terraform.io/remote-state-locking"]'
}

terraform::settings::remote_state_region() {
    resource::query '.metadata.annotations["terraform.io/remote-state-region"]'
}

### Runtime ###################################################################
terraform::system_version() {
    if command -v terraform >/dev/null 2>&1; then
        terraform version | head -n1 | cut -d' ' -f2 | cut -d'v' -f2
    else
        log info "terraform.io/v1alpha1/system_terraform_version: terraform not found"
    fi
}

terraform::set_version() {
    local -r terraform_version=$(terraform::settings::version)
    local -r current_terraform_version=$(terraform::system_version)

    if [ "$terraform_version" != "$current_terraform_version" ]; then
        if ! command -v tfenv >/dev/null 2>&1; then
            log error "terraform.io/v1alpha1/set_terraform_version: tfenv not found"
            return
        fi
        tfenv install "$terraform_version"
        tfenv use "$terraform_version"
    fi
}

terraform::system_terragrunt_version() {
    if command -v terragrunt >/dev/null 2>&1; then
        terragrunt --version | awk '{print $3}' | cut -d'v' -f2
    else
        log info "terraform.io/v1alpha1/system_terragrunt_version: terragrunt not found"
    fi
}

terraform::set_terragrunt_version() {
    local -r terragrunt_version=$(terraform::settings::terragrunt_version)
    local -r current_terragrunt_version=$(terraform::system_terragrunt_version)

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
    version: "$(workspace::manifest::version)"
    terraform_metadata_labels: "$(terraform::settings::labels)"
    terraform_remote_state_backend: "$(terraform::settings::remote_state_backend)"
    terraform_remote_state_locking: "$(terraform::settings::remote_state_locking)"
    terraform_remote_state_region: "$(terraform::settings::remote_state_region)"
    terraform_version: "$(terraform::settings::version)"
    terragrunt_version: "$(terraform::settings::terragrunt_version)"
EOF
}

api::template::render() {
    local -r template_path="$INFRACTL_PATH/plugins/api/terraform/v1alpha1/template"
    local -r template_config="$1"
    local -r template_output="$2"

    utils::render_template "$template_path" "$template_config" "$template_output"
}

### Runtime ###################################################################

api::run() {
    build_output=$(build::new)
    pushd "$build_output"

    if [ -f ".envrc" ]; then
        direnv allow .
        eval "$(direnv export bash)"
    fi

    TERRAGRUNT_DOWNLOAD="$(workspace::dir::cache 'terragrunt')"
    export TERRAGRUNT_DOWNLOAD
    TF_PLUGIN_CACHE_DIR="$(workspace::dir::cache 'terraform')"
    export TF_PLUGIN_CACHE_DIR
    TF_DATA_DIR="$(workspace::dir::data 'terraform')"
    export TF_DATA_DIR

    terraform::set_version
    terraform::set_terragrunt_version

    if [ "$INFRACTL_DRYRUN" == "true" ]; then
        log info "running: terragrunt plan"
        terragrunt plan
    else
        log info "running: terragrunt apply"
        terragrunt apply
    fi

    popd
}
