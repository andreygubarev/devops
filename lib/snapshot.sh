#!/usr/bin/env bash
# namespace: snapshot

snapshot::path() {
    echo "$snapshot_path/.infractl/$snapshot_hash"
}

snapshot::new() {
    snapshot_path=$(readlink -f "$1")
    if [ -f "$snapshot_path" ]; then
        snapshot_path=$(dirname "$snapshot_path")
        log debug "snapshot: new: $snapshot_path"
    else
        log critical "snapshot: not found: $1"
    fi

    snapshot_archive="$(mktemp)"
    tar -czf "$snapshot_archive" -C "$snapshot_path" .
    log debug "snapshot: archive: $snapshot_archive"

    snapshot_hash=$(sha1sum "$snapshot_archive" | awk '{print $1}')
    log debug "snapshot: hash: $snapshot_hash"

    snapshot_dir=$(snapshot::path)
    log debug "snapshot: dir: $snapshot_dir"

    mkdir -p "$snapshot_dir"
    tar -xzf "$snapshot_archive" -C "$snapshot_dir"
}
