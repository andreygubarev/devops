#!/usr/bin/env bash

new_manifest() {
    local -r v=$(readlink -f "$1")
    if [ ! -f "$v" ]; then
        log critical "manifest: not found: $1"
    fi
    manifest="$v"
    log debug "manifest: new $manifest"

    new_api "$(manifest_apiversion)"
}

manifest_path() {
    echo "$manifest"
}

manifest_dir() {
    local -r v=$(dirname "$(manifest_path)")
    if [ ! -d "$v" ]; then
        log critical "manifest: directory not found: $v"
    fi
    echo "$v"
}

manifest_query() {
    local -r query="$1"
    if [ -z "$query" ]; then
        log error "manifest: query not found"
        return
    fi

    local -r v=$(yq "$query" < "$(manifest_path)")
    if [ "$v" == "null" ]; then
        log warn "manifest: field not found: $query"
        return
    fi
    echo "$v"
}

manifest_apiversion() {
    local -r v=$(manifest_query '.apiVersion')
    if [ "$v" == "null" ]; then
        log critical "manifest: '.apiVersion' not found"
    fi
    echo "$v"
}

manifest_kind() {
    local -r v=$(manifest_query '.kind')
    if [ "$v" == "null" ]; then
        log critical "manifest: '.kind' not found"
    fi
    echo "$v"
}

manifest_name() {
    local -r v=$(manifest_query '.metadata.name')
    if [ "$v" == "null" ]; then
        log critical "manifest: '.metadata.name' not found"
    fi
}

manifest_version() {
    pushd "$(manifest_dir)" > /dev/null || exit 1
    echo "$(git rev-parse --short HEAD)$(git diff-index --quiet HEAD -- || echo "-dirty")"
    popd > /dev/null || exit 1
}
