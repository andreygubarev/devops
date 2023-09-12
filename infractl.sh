#!/usr/bin/env bash
set -euo pipefail

### Globals ###################################################################
INFRACTL_PATH="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

### Libarary ##################################################################

# shellcheck source=lib/logging.sh
source "$INFRACTL_PATH/lib/logging.sh"

# shellcheck source=lib/templates.sh
source "$INFRACTL_PATH/lib/templates.sh"

# shellcheck source=lib/api.sh
source "$INFRACTL_PATH/lib/api.sh"

### Plugins ###################################################################
INFRACTL_PLUGINS_PATH="$INFRACTL_PATH/plugins"

# shellcheck source=plugins/api/ansible/v1alpha1/plugin.sh
source "$INFRACTL_PLUGINS_PATH/api/ansible/v1alpha1/plugin.sh"

# shellcheck source=plugins/api/terraform/v1alpha1/plugin.sh
source "$INFRACTL_PLUGINS_PATH/api/terraform/v1alpha1/plugin.sh"


### Runtime ###################################################################
INFRACTL_DRYRUN="${INFRACTL_DRYRUN:-false}"

### Manifests #################################################################
manifest_get_path() {
    if [ -f "$1" ]; then
        readlink -f "$1"
    fi
}

manifest_get_dir() {
    dirname "$1"
}

manifest_get_apiversion() {
    yq '.apiVersion' < "$1"
}

manifest_get_kind() {
    yq '.kind' < "$1"
}

manifest_get_name() {
    yq '.metadata.name' < "$1"
}

manifest_get_version() {
    pushd "$(manifest_get_dir "$1")" > /dev/null
    echo "$(git rev-parse --short HEAD)$(git diff-index --quiet HEAD -- || echo "-dirty")"
    popd > /dev/null
}

manifest_set_context() {
    manifest_path=$(manifest_get_path "$1")
    if [ ! -f "$manifest_path" ]; then
        log critical "manifest not found: $1"
    fi

    manifest_dir=$(manifest_get_dir "$manifest_path")
    if [ ! -d "$manifest_dir" ]; then
        log critical "manifest directory not found: $manifest_dir"
    fi

    manifest_apiversion=$(manifest_get_apiversion "$manifest_path")
    if [ "$manifest_apiversion" == "null" ]; then
        log critical "manifest '.apiVersion' not found"
    fi

    manifest_kind=$(manifest_get_kind "$manifest_path")
    if [ "$manifest_kind" == "null" ]; then
        log critical "manifest '.kind' not found"
    fi

    manifest_name=$(manifest_get_name "$manifest_path")
    if [ "$manifest_name" == "null" ]; then
        log critical "manifest '.metadata.name' not found"
    fi

    # FIXME: Update this to use the version from the manifest
    manifest_version=$(manifest_get_version "$manifest_dir")
    if [ "$manifest_version" == "null" ]; then
        log critical "manifest version not found"
    fi
}

manifest_set_api_context() {
    api_set_context "$manifest_apiversion"
}

### Build #####################################################################

build_set_context() {
    log debug "setting build context"

    build_source_provider=$(build_get_source_provider)
    build_source_path=$(build_get_source_path)

    build_dist="$manifest_dir/.infractl/dist/$manifest_name"
    build_version="$manifest_version"
    build_config="$build_dist/$build_version.config.yaml"
    build_output="$build_dist/$build_version"

    mkdir -p "$build_dist"
}

build_get_source_provider() {
    echo "$manifest_kind" | cut -d':' -f1
}

build_get_source_path() {
    echo "$manifest_kind" | cut -d':' -f2 | cut -d'/' -f2- | cut -d'/' -f2-
}

build_source_using_file() {
    log info "copying source: $build_source_path"

    local source=$build_source_path

    if [[ $source != /* ]]; then
        source="$manifest_dir/$source"
    fi

    if [ -d "$source" ]; then
        source="${source%/}/"
    fi

    rm -rf "$build_output/src"
    cp -r "$source" "$build_output/src/"
}

build_source() {
    cp "$manifest_path" "$build_output/manifest.yaml"

    case "$build_source_provider" in
        "file")
            build_source_using_file
            ;;
        *)
            log critical "Unsupported source provider: $build_source_provider"
            ;;
    esac
}

build_environment() {
    if [ -f "$manifest_dir/.envrc" ]; then
        cat "$manifest_dir/.envrc" >> "$build_output/.envrc"
    fi
    direnv allow "$build_output"
}

build_template_config() {
    case "$manifest_apiversion" in
        "terraform.io/v1alpha1")
            terraform_template_config "$build_config"
            ;;
        "ansible.com/v1alpha1")
            api "template_config" "$build_config"
            ;;
        *)
            log critical "unsupported apiVersion: $manifest_apiversion"
            ;;
    esac
}

build_template() {
    case "$manifest_apiversion" in
        "terraform.io/v1alpha1")
            template_render "$TEMPLATES_DIR/terraform-v1" "$build_config" "$build_dist"
            ;;
        "ansible.com/v1alpha1")
            api "template" "$build_config" "$build_dist"
            ;;
        *)
            log critical "unsupported apiVersion: $manifest_apiversion"
            ;;
    esac
}

build() {
    build_set_context
    build_template_config
    build_template
    build_environment
    build_source

    echo "$build_output"
}

### Ansible ###################################################################
### Ansible | API #############################################################
ansible_run() {
    build_output=$(build)
    pushd "$build_output"
    direnv allow .
    eval "$(direnv export bash)"

    echo "ansible-playbook $(api "inventory" "$manifest_path") $(api "dryrun") $(api "extra_vars" "$manifest_path" "$build_output") src/$(api "playbook" "$manifest_path")"
    popd
}

### Terraform #################################################################
### Terraform | Versions ######################################################

### Terraform | Build #########################################################

terraform_template_config_get_metadata_labels() {
    yq '.metadata.labels | keys | .[]' < "$manifest_path" | xargs echo
}

terraform_template_config_get_remote_state_backend() {
    yq '.metadata.annotations["terraform.io/remote-state-backend"]' < "$manifest_path"
}

terraform_template_config_get_remote_state_region() {
    yq '.metadata.annotations["terraform.io/remote-state-region"]' < "$manifest_path"
}

terraform_template_config_get_remote_locking() {
    yq '.metadata.annotations["terraform.io/remote-state-locking"]' < "$manifest_path"
}

terraform_template_config() {
    cat <<- EOF > "$1"
default_context:
    name: "$manifest_name"
    version: "$manifest_version"
    terraform_metadata_labels: "$(terraform_template_config_get_metadata_labels)"
    terraform_remote_state_backend: "$(terraform_template_config_get_remote_state_backend)"
    terraform_remote_state_locking: "$(terraform_template_config_get_remote_locking)"
    terraform_remote_state_region: "$(terraform_template_config_get_remote_state_region)"
    terraform_version: "$(api "settings_terraform_version" "$manifest_path")"
    terragrunt_version: "$(api "settings_terragrunt_version" "$manifest_path")"
EOF
}

### Terraform | API ###########################################################
terraform_run() {
    build_output=$(build)
    pushd "$build_output"
    direnv allow .
    eval "$(direnv export bash)"

    api "set_terraform_version" "$manifest_path"
    api "set_terragrunt_version" "$manifest_path"

    if [ "$INFRACTL_DRYRUN" == "true" ]; then
        log info "running: terragrunt plan"
        terragrunt plan
    else
        log info "running: terragrunt apply"
        terragrunt apply
    fi

    popd
}

### Command line #############################################################

command_build() {
    while getopts ":f:" opt; do
    case $opt in
        f) opt_f="$OPTARG" ;;
        \?)
            log critical "invalid option: -$OPTARG"
            ;;
        :)
            log critical "option -$OPTARG requires an argument."
            ;;
    esac
    done

    if [ -n "${opt_f:-}" ]; then
        manifest_set_context "$opt_f"
        manifest_set_api_context
    else
        log critical "usage: $0 build -f <manifest>"
    fi

    case "$manifest_apiversion" in
        "terraform.io/v1alpha1")
            build
            ;;
        "ansible.com/v1alpha1")
            build
            ;;
        *)
            log critical "unsupported apiVersion: $manifest_apiversion"
            ;;
    esac
}

command_run() {
    while getopts ":f:n" opt; do
        case $opt in
            f)
                opt_f="$OPTARG"
                ;;
            n)
                opt_n=true
                ;;
            \?)
                log critical "invalid option: -$OPTARG"
                ;;
            :)
                log critical "option -$OPTARG requires an argument."
                ;;
        esac
    done

    if [ -n "${opt_f:-}" ]; then
        log debug "setting manifest context: $opt_f"
        manifest_set_context "$opt_f"
        manifest_set_api_context
    else
        log critical "usage: $0 run [-n] -f <manifest>"
    fi

    if [ -n "${opt_n:-}" ]; then
        INFRACTL_DRYRUN="true"
    fi

    case "$manifest_apiversion" in
        "terraform.io/v1alpha1")
            terraform_run
            ;;
        "ansible.com/v1alpha1")
            ansible_run
            ;;
        *)
            log critical "unsupported apiVersion: $manifest_apiversion"
            ;;
    esac
}

command_clean() {
    while getopts ":f:" opt; do
    case $opt in
        f)
            opt_f="$OPTARG"
            ;;
        \?)
            log critical "invalid option: -$OPTARG"
            ;;
        :)
            log critical "option -$OPTARG requires an argument."
            ;;
    esac
    done

    if [ -n "${opt_f:-}" ]; then
        manifest_set_context "$opt_f"
        manifest_set_api_context
    else
        log critical "usage: $0 clean -f <manifest>"
    fi

    build_set_context
    rm -rf "$build_dist"
}

command_install() {
    log info "installing infractl"
}

if [ $# -lt 1 ]; then
    log critical "usage: $0 {build|run|clean|install}"
fi

case "$1" in
    build)
        shift
        command_build "$@"
        ;;
    run)
        shift
        command_run "$@"
        ;;
    clean)
        shift
        command_clean "$@"
        ;;
    install)
        shift
        command_install "$@"
        ;;
    *)
        log critical "usage: $0 {build|run|clean|install}"
        ;;
esac
