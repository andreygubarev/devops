#!/usr/bin/env bash
API_TERRAFORM_V1ALPHA1_PATH="$INFRACTL_PATH/plugins/api/terraform/v1alpha1"
declare -A api_terraform_v1alpha1

### Manifest ##################################################################
api_terraform_v1alpha1["manifest"]=api_terraform_v1alpha1__manifest
api_terraform_v1alpha1__manifest() {
    if [ ! -f "$1" ]; then
        log error "terraform.io/v1alpha1/manifest: manifest not found: $1"
        return
    fi

    if [ -z "$2" ]; then
        log error "terraform.io/v1alpha1/manifest: query not found"
        return
    fi

    local -r v=$(yq "$2" < "$1")
    if [ "$v" == "null" ]; then
        log warn "terraform.io/v1alpha1/manifest: field not found: $2"
        return
    fi
    echo "$v"
}

### Settings ##################################################################
api_terraform_v1alpha1["settings_terraform_version"]=api_terraform_v1alpha1__settings_terraform_version
api_terraform_v1alpha1__settings_terraform_version() {
    manifest_query '.metadata.annotations["terraform.io/version"]'
}

api_terraform_v1alpha1["settings_terragrunt_version"]=api_terraform_v1alpha1__settings_terragrunt_version
api_terraform_v1alpha1__settings_terragrunt_version() {
    manifest_query '.metadata.annotations["terragrunt.gruntwork.io/version"]'
}

api_terraform_v1alpha1["labels"]=api_terraform_v1alpha1__labels
api_terraform_v1alpha1__labels() {
    local -r v=$(manifest_query '.metadata.labels | keys | .[]')
    echo "$v" | xargs echo
}

api_terraform_v1alpha1["settings_remote_state_backend"]=api_terraform_v1alpha1__settings_remote_state_backend
api_terraform_v1alpha1__settings_remote_state_backend() {
    manifest_query '.metadata.annotations["terraform.io/remote-state-backend"]'
}

api_terraform_v1alpha1["settings_remote_state_locking"]=api_terraform_v1alpha1__settings_remote_state_locking
api_terraform_v1alpha1__settings_remote_state_locking() {
    manifest_query '.metadata.annotations["terraform.io/remote-state-locking"]'
}

api_terraform_v1alpha1["settings_remote_state_region"]=api_terraform_v1alpha1__settings_remote_state_region
api_terraform_v1alpha1__settings_remote_state_region() {
    manifest_query '.metadata.annotations["terraform.io/remote-state-region"]'
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
    if [ ! -f "$1" ]; then
        log error "terraform.io/v1alpha1/set_terraform_version: manifest not found: $1"
        return
    fi

    local -r terraform_version=$(api_terraform_v1alpha1__settings_terraform_version "$1")
    local -r current_terraform_version=$(api_terraform_v1alpha1__system_terraform_version "$1")

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
    if [ ! -f "$1" ]; then
        log error "terraform.io/v1alpha1/set_terragrunt_version: manifest not found: $1"
        return
    fi

    local -r terragrunt_version=$(api_terraform_v1alpha1__settings_terragrunt_version "$1")
    local -r current_terragrunt_version=$(api_terraform_v1alpha1__system_terragrunt_version "$1")

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
api_terraform_v1alpha1["template_config"]=api_terraform_v1alpha1__template_config
api_terraform_v1alpha1__template_config() {
    cat <<- EOF > "$1"
default_context:
    name: "$manifest_name"
    version: "$manifest_version"
    terraform_metadata_labels: "$(api_terraform_v1alpha1__labels "$manifest_path")"
    terraform_remote_state_backend: "$(api_terraform_v1alpha1__settings_remote_state_backend "$manifest_path")"
    terraform_remote_state_locking: "$(api_terraform_v1alpha1__settings_remote_state_locking "$manifest_path")"
    terraform_remote_state_region: "$(api_terraform_v1alpha1__settings_remote_state_region "$manifest_path")"
    terraform_version: "$(api_terraform_v1alpha1__settings_terraform_version "$manifest_path")"
    terragrunt_version: "$(api_terraform_v1alpha1__settings_terragrunt_version "$manifest_path")"
EOF
}

api_terraform_v1alpha1["template"]=api_terraform_v1alpha1__template
api_terraform_v1alpha1__template() {
    local -r template_path="$API_TERRAFORM_V1ALPHA1_PATH/template"
    local -r template_config="$1"
    local -r template_output="$2"

    template_render "$template_path" "$template_config" "$template_output"
}
