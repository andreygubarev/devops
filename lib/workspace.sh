#!/usr/bin/env bash
# namespace: workspace

workspace::new() {
    manifest_path=$(readlink -f "$1")
    log info "workspace: new: $manifest_path"

    if [ -f "$manifest_path" ]; then
        manifest_dir=$(dirname "$manifest_path")
        log debug "workspace: dir: $manifest_dir"
    else
        log critical "workspace: not found: $manifest_path"
    fi

    pushd "$manifest_dir" > /dev/null || exit 1
    manifest_version=$(git rev-parse --short HEAD)
    popd > /dev/null || exit 1
}

workspace::manifest::path() {
    echo "$manifest_path"
}

workspace::manifest::dir() {
    echo "$manifest_dir"
}

workspace::dir() {
    local -r v="$(workspace::manifest::dir)/$INFRACTL_WORKSPACE/$manifest_version"
    if [ ! -d "$v" ]; then
        mkdir -p "$v"
    fi
    log debug "workspace: dir: $v"
    echo "$v"
}

workspace::snapshot::dir() {
    local -r v="$(workspace::dir)/snapshot"
    if [ ! -d "$v" ]; then
        mkdir -p "$v"
    fi
    log debug "workspace: snapshot dir: $v"
    echo "$v"
}
