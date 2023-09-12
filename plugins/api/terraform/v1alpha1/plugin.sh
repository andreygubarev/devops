#!/usr/bin/env bash
API_TERRAFORM_V1ALPHA1_PATH="$INFRACTL_PATH/plugins/api/terraform/v1alpha1"
declare -A api_terraform_v1alpha1

### Settings ##################################################################
api_terraform_v1alpha1["settings_terraform_version"]=api_terraform_v1alpha1__settings_terraform_version
api_terraform_v1alpha1__settings_terraform_version() {
    if [ ! -f "$1" ]; then
        log error "terraform.io/v1alpha1/settings_terraform_version: manifest not found: $1"
        return
    fi

    local -r v=$(yq '.metadata.annotations["terraform.io/version"]' < "$1")
    if [ "$v" == "null" ]; then
        log warn "terraform.io/v1alpha1/settings_terraform_version: terraform version not found"
        return
    fi
    echo "$v"
}

api_terraform_v1alpha1["settings_terragrunt_version"]=api_terraform_v1alpha1__settings_terragrunt_version
api_terraform_v1alpha1__settings_terragrunt_version() {
    if [ ! -f "$1" ]; then
        log error "terraform.io/v1alpha1/settings_terragrunt_version: manifest not found: $1"
        return
    fi

    local -r v=$(yq '.metadata.annotations["terragrunt.gruntwork.io/version"]' < "$1")
    if [ "$v" == "null" ]; then
        log warn "terraform.io/v1alpha1/settings_terragrunt_version: terragrunt version not found"
        return
    fi
    echo "$v"
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
