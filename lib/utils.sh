#!/usr/bin/env bash

utils::clone() {
    local func="$1"
    local name="$2"
    eval "$(printf '%q()' "$name"; declare -f "$func" | tail -n +2)"
}

utils::render_template() {
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
