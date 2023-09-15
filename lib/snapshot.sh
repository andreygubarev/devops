#!/usr/bin/env bash
# namespace: snapshot

snapshot::new() {
    snapshot_archive="$(mktemp)"
    trap 'rm -f "$snapshot_archive"' EXIT
    tar -czf "$snapshot_archive" -C "$(workspace::manifest::dir)" --exclude="$INFRACTL_WORKSPACE" .
    log debug "snapshot: archive: $snapshot_archive"
    tar -xzf "$snapshot_archive" -C "$(workspace::snapshot::dir)"
}
