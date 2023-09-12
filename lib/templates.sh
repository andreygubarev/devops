#!/usr/bin/env bash
TEMPLATES_DIR="$INFRACTL_PATH/templates"

template_render() {
    log info "rendering template: $1"

    local -r template_path="$1"
    local -r template_config="$2"
    local -r template_output="$3"

    if ! cookiecutter \
        --no-input \
        --overwrite-if-exists \
        --config-file "$template_config" \
        --output-dir "$template_output" \
        "$template_path"
    then
        log critical "failed to render template: $template_path"
    fi
}
