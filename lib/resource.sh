#!/usr/bin/env bash
# namespace: manifest

resource::new() {
    local -r v=$(readlink -f "$1")
    if [ ! -f "$v" ]; then
        log critical "resource: not found: $1"
    fi

    log debug "resource: new $v"
    manifest_path="$v"
    manifest="$(cat "$manifest_path")"

    api::new "$(resource::metadata::apiversion)"
}

resource::path() {
    echo "$manifest_path"
}

resource::dir() {
    local -r v=$(dirname "$(resource::path)")
    if [ ! -d "$v" ]; then
        log critical "resource: directory not found: $v"
    fi
    echo "$v"
}

resource::version() {
    pushd "$(resource::dir)" > /dev/null || exit 1
    echo "$(git rev-parse --short HEAD)$(git diff-index --quiet HEAD -- || echo "-dirty")"
    popd > /dev/null || exit 1
}

resource::query() {
    local -r query="$1"
    if [ -z "$query" ]; then
        log error "resource: query not found"
        return
    fi

    local -r v=$(echo "$manifest" | yq "$query")
    if [ "$v" == "null" ]; then
        log warn "resource: field not found: $query"
        return
    fi
    echo "$v"
}

resource::metadata::apiversion() {
    local -r v=$(resource::query '.apiVersion')
    if [ "$v" == "null" ]; then
        log critical "resource: '.apiVersion' not found"
    fi
    echo "$v"
}

resource::metadata::kind() {
    local -r v=$(resource::query '.kind')
    if [ "$v" == "null" ]; then
        log critical "resource: '.kind' not found"
    fi
    echo "$v"
}

resource::metadata::name() {
    local -r v=$(resource::query '.metadata.name')
    if [ "$v" == "null" ]; then
        log critical "resource: '.metadata.name' not found"
    fi
}

