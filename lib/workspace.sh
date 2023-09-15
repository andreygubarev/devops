#!/usr/bin/env bash
# namespace: workspace

workspace::new() {
    manifest_path=$(readlink -f "$1")
    log info "workspace: new: $manifest_path"

    if [ -f "$manifest_path" ]; then
        manifest_dir=$(dirname "$manifest_path")
        log debug "workspace: dir: $manifest_dir"
        manifest_file=$(basename "$manifest_path")
        log debug "workspace: file: $manifest_file"
    else
        log critical "workspace: not found: $manifest_path"
    fi

    pushd "$manifest_dir" > /dev/null || exit 1
    manifest_version=$(git rev-parse --short HEAD)
    popd > /dev/null || exit 1

    workspace::snapshot::new
    workspace::resource::new
}

workspace::dir() {
    local -r v="$manifest_dir/$INFRACTL_WORKSPACE/$manifest_version"
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

workspace::snapshot::new() {
    snapshot_archive="$(mktemp)"
    trap 'rm -f "$snapshot_archive"' EXIT
    tar -czf "$snapshot_archive" -C "$(workspace::manifest::dir)" --exclude="$INFRACTL_WORKSPACE" .
    log debug "workspace: snapshot archive: $snapshot_archive"
    tar -xzf "$snapshot_archive" -C "$(workspace::snapshot::dir)"
}

workspace::manifest::file() {
    echo "$manifest_file"
}

workspace::manifest::dir() {
    workspace::snapshot::dir
}

workspace::manifest::path() {
    echo "$(workspace::snapshot::dir)/$manifest_file"
}

workspace::resource::dir() {
    local -r v="$(workspace::dir)/resource"
    if [ ! -d "$v" ]; then
        mkdir -p "$v"
    fi
    log debug "workspace: resource dir: $v"
    echo "$v"
}

workspace::resource::new() {
    yq --prettyPrint --no-colors "$(workspace::manifest::path)" > "$(workspace::resource::dir)/resource.yml"
    pushd "$(workspace::resource::dir)" > /dev/null || exit 1
    # shellcheck disable=SC2016
    yq -s '"resource.part" + $index + ".yml"' resource.yml
    popd > /dev/null || exit 1
}
