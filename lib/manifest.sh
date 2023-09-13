#!/usr/bin/env bash

manifest::new() {
    local -r v=$(readlink -f "$1")
    if [ ! -f "$v" ]; then
        log critical "manifest: not found: $1"
    fi

    log debug "manifest: new $v"
    manifest_path="$v"
    manifest="$(cat "$manifest_path")"

    new_api "$(manifest::apiversion)"
}

manifest::path() {
    echo "$manifest_path"
}

manifest::dir() {
    local -r v=$(dirname "$(manifest::path)")
    if [ ! -d "$v" ]; then
        log critical "manifest: directory not found: $v"
    fi
    echo "$v"
}

manifest::query() {
    local -r query="$1"
    if [ -z "$query" ]; then
        log error "manifest: query not found"
        return
    fi

    local -r v=$(echo "$manifest" | yq "$query" -)
    if [ "$v" == "null" ]; then
        log warn "manifest: field not found: $query"
        return
    fi
    echo "$v"
}

manifest::apiversion() {
    local -r v=$(manifest::query '.apiVersion')
    if [ "$v" == "null" ]; then
        log critical "manifest: '.apiVersion' not found"
    fi
    echo "$v"
}

manifest::kind() {
    local -r v=$(manifest::query '.kind')
    if [ "$v" == "null" ]; then
        log critical "manifest: '.kind' not found"
    fi
    echo "$v"
}

manifest::name() {
    local -r v=$(manifest::query '.metadata.name')
    if [ "$v" == "null" ]; then
        log critical "manifest: '.metadata.name' not found"
    fi
}

manifest::version() {
    pushd "$(manifest::dir)" > /dev/null || exit 1
    echo "$(git rev-parse --short HEAD)$(git diff-index --quiet HEAD -- || echo "-dirty")"
    popd > /dev/null || exit 1
}
