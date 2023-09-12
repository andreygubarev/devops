#!/usr/bin/env bash

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

manifest_query() {
    if [ ! -f "$manifest_path" ]; then
        log error "ansible.com/v1alpha1/manifest: manifest not found: $1"
        return
    fi

    local -r query="$1"
    if [ -z "$query" ]; then
        log error "ansible.com/v1alpha1/manifest: query not found"
        return
    fi

    local -r v=$(yq "$query" < "$manifest_path")
    if [ "$v" == "null" ]; then
        log warn "ansible.com/v1alpha1/manifest: field not found: $query"
        return
    fi
    echo "$v"
}
