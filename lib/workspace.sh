#!/usr/bin/env bash
# namespace: workspace

workspace::new() {
    workspace=$(readlink -f "$1")
    log info "workspace: new: $workspace"

    if [ -f "$workspace" ]; then
        workspace_dir=$(dirname "$workspace")
        log debug "workspace: dir: $workspace_dir"
    else
        log critical "workspace: not found: $workspace"
    fi
}

workspace::version() {
    pushd "$workspace_dir" > /dev/null || exit 1
    git rev-parse --short HEAD
    popd > /dev/null || exit 1
}

workspace::path() {
    local -r v="$workspace_dir/$INFRACTL_WORKSPACE/$(workspace::version)"
    if [ ! -d "$v" ]; then
        mkdir -p "$v"
    fi
    log debug "workspace: path: $v"
}
