#!/usr/bin/env bash
# namespace: snapshot

snapshot::path() {
    echo "$snapshot_dir/$INFRACTL_WORKSPACE/$snapshot_hash"
}

snapshot::resources() {
    echo "$(snapshot::path)/resources"
}

snapshot::new() {
    snapshot_file="$1"
    snapshot_path=$(readlink -f "$snapshot_file")
    if [ -f "$snapshot_path" ]; then
        snapshot_dir=$(dirname "$snapshot_path")
        log debug "snapshot: new: $snapshot_path"
    else
        log critical "snapshot: not found: $snapshot_file"
    fi

    snapshot_archive="$(mktemp)"
    tar -czf "$snapshot_archive" -C "$snapshot_dir" --exclude="$INFRACTL_WORKSPACE" --exclude="$(basename "$snapshot_file")" .
    log debug "snapshot: archive: $snapshot_archive"

    snapshot_hash=$(sha1sum "$snapshot_archive" | awk '{print $1}')
    log debug "snapshot: hash: $snapshot_hash"

    log debug "snapshot: dir: $(snapshot::path)"
    mkdir -p "$(snapshot::path)/snapshot"
    tar -xzf "$snapshot_archive" -C "$(snapshot::path)/snapshot"

    mkdir -p "$(snapshot::path)/resources"
    pushd "$(snapshot::path)/resources" > /dev/null || exit 1
    yq -s '"resource." + $index + ".yaml"' "$snapshot_path"
    popd > /dev/null || exit 1

    snapshot::path
}
