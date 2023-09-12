#!/usr/bin/env bash

utils::clone() {
    local func="$1"
    local name="$2"
    eval "$(printf '%q()' "$name"; declare -f "$func" | tail -n +2)"
}
