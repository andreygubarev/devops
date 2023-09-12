#!/usr/bin/env bash
set -euo pipefail

### Globals ###################################################################
INFRACTL_PATH="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
INFRACTL_DRYRUN="${INFRACTL_DRYRUN:-false}"

### Libarary ##################################################################

# shellcheck source=lib/logging.sh
source "$INFRACTL_PATH/lib/logging.sh"

# shellcheck source=lib/manifest.sh
source "$INFRACTL_PATH/lib/manifest.sh"

# shellcheck source=lib/build.sh
source "$INFRACTL_PATH/lib/build.sh"

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


### Ansible ###################################################################

ansible_run() {
    build_output=$(build)
    pushd "$build_output"
    direnv allow .
    eval "$(direnv export bash)"

    echo "ansible-playbook $(api "inventory") $(api "dryrun") $(api "extra_vars" "$build_output") src/$(api "playbook")"
    popd
}

### Terraform #################################################################

terraform_run() {
    build_output=$(build)
    pushd "$build_output"
    direnv allow .
    eval "$(direnv export bash)"

    api "set_terraform_version"
    api "set_terragrunt_version"

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
        manifest_set "$opt_f"
    else
        log critical "usage: $0 build -f <manifest>"
    fi

    case "$(manifest_apiversion)" in
        "terraform.io/v1alpha1")
            build
            ;;
        "ansible.com/v1alpha1")
            build
            ;;
        *)
            log critical "unsupported apiVersion: $(manifest_apiversion)"
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
        manifest_set "$opt_f"
    else
        log critical "usage: $0 run [-n] -f <manifest>"
    fi

    if [ -n "${opt_n:-}" ]; then
        INFRACTL_DRYRUN="true"
    fi

    case "$(manifest_apiversion)" in
        "terraform.io/v1alpha1")
            terraform_run
            ;;
        "ansible.com/v1alpha1")
            ansible_run
            ;;
        *)
            log critical "unsupported apiVersion: $(manifest_apiversion)"
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
        manifest_set "$opt_f"
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
