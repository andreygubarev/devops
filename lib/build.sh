#!/usr/bin/env bash

build_set_context() {
    log debug "setting build context"

    build_source_provider=$(build_get_source_provider)
    build_source_path=$(build_get_source_path)

    build_dist="$(manifest_dir)/.infractl/dist/$(manifest_name)"
    build_version="$(manifest_version)"
    build_config="$build_dist/$build_version.config.yaml"
    build_output="$build_dist/$build_version"

    mkdir -p "$build_dist"
}

build_get_source_provider() {
    manifest_kind | cut -d':' -f1
}

build_get_source_path() {
    manifest_kind | cut -d':' -f2 | cut -d'/' -f2- | cut -d'/' -f2-
}

build_source_using_file() {
    log info "copying source: $build_source_path"

    local source=$build_source_path

    if [[ $source != /* ]]; then
        source="$(manifest_dir)/$source"
    fi

    if [ -d "$source" ]; then
        source="${source%/}/"
    fi

    rm -rf "$build_output/src"
    cp -r "$source" "$build_output/src/"
}

build_source() {
    cp "$(manifest_path)" "$build_output/manifest.yaml"

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
    if [ -f "$(manifest_dir)/.envrc" ]; then
        cat "$(manifest_dir)/.envrc" >> "$build_output/.envrc"
    fi
    direnv allow "$build_output"
}

build() {
    build_set_context
    api "template_config" "$build_config"
    api "template" "$build_config" "$build_dist"
    build_environment
    build_source

    echo "$build_output"
}