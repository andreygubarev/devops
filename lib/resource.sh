#!/usr/bin/env bash
# namespace: manifest

resource::new() {
    local -r v=$(readlink -f "$1")
    if [ ! -f "$v" ]; then
        log critical "manifest: not found: $1"
    fi

    log debug "manifest: new $v"
    manifest_path="$v"
    manifest="$(cat "$manifest_path")"

    api::new "$(resource::apiversion)"
}

resource::path() {
    echo "$manifest_path"
}

resource::dir() {
    local -r v=$(dirname "$(resource::path)")
    if [ ! -d "$v" ]; then
        log critical "manifest: directory not found: $v"
    fi
    echo "$v"
}

resource::query() {
    local -r query="$1"
    if [ -z "$query" ]; then
        log error "manifest: query not found"
        return
    fi

    local -r v=$(echo "$manifest" | yq "$query")
    if [ "$v" == "null" ]; then
        log warn "manifest: field not found: $query"
        return
    fi
    echo "$v"
}

resource::apiversion() {
    local -r v=$(resource::query '.apiVersion')
    if [ "$v" == "null" ]; then
        log critical "manifest: '.apiVersion' not found"
    fi
    echo "$v"
}

resource::kind() {
    local -r v=$(resource::query '.kind')
    if [ "$v" == "null" ]; then
        log critical "manifest: '.kind' not found"
    fi
    echo "$v"
}

resource::name() {
    local -r v=$(resource::query '.metadata.name')
    if [ "$v" == "null" ]; then
        log critical "manifest: '.metadata.name' not found"
    fi
}

resource::version() {
    pushd "$(resource::dir)" > /dev/null || exit 1
    echo "$(git rev-parse --short HEAD)$(git diff-index --quiet HEAD -- || echo "-dirty")"
    popd > /dev/null || exit 1
}
