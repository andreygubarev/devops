#!/usr/bin/env bash
# namespace: resource

resource::new() {
    local -r v=$(readlink -f "$1")
    if [ ! -f "$v" ]; then
        log critical "resource: not found: $1"
    fi

    log debug "resource: new $v"
    resource="$(cat "$v")"
}

resource::query() {
    local -r query="$1"
    if [ -z "$query" ]; then
        log error "resource: query not found"
        return
    fi

    local -r v=$(echo "$resource" | yq "$query")
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
    echo "$v"
}

resource::source::scheme() {
    resource::metadata::kind | cut -d':' -f1
}

resource::source::path() {
    resource::metadata::kind | cut -d':' -f2 | cut -d'/' -f2- | cut -d'/' -f2-
}
