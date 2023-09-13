#!/usr/bin/env bash
# namespace: snapshot

snapshot::path() {
    echo "$snapshot_path/$INFRACTL_WORKSPACE/$snapshot_hash"
}

snapshot::new() {
    snapshot_file="$1"
    snapshot_path=$(readlink -f "$snapshot_file")
    if [ -f "$snapshot_path" ]; then
        snapshot_path=$(dirname "$snapshot_path")
        log debug "snapshot: new: $snapshot_path"
    else
        log critical "snapshot: not found: $snapshot_file"
    fi

    snapshot_archive="$(mktemp)"
    tar -czf "$snapshot_archive" -C "$snapshot_path" --exclude="$INFRACTL_WORKSPACE" .
    log debug "snapshot: archive: $snapshot_archive"

    snapshot_hash=$(sha1sum "$snapshot_archive" | awk '{print $1}')
    log debug "snapshot: hash: $snapshot_hash"

    log debug "snapshot: dir: $(snapshot::path)"
    mkdir -p "$(snapshot::path)/snapshot"
    tar -xzf "$snapshot_archive" -C "$(snapshot::path)/snapshot"

    snapshot::path
}
