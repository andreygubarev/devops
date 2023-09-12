#!/usr/bin/env bash

### Functions #################################################################

new_context() {
    declare -gA context
}

context_set() {
    local -r key="$1"
    local -r value="$2"
    log debug "context: set $key=$value"
    context["$key"]="$value"
}

context_get() {
    local -r key="$1"
    echo "${context[$key]}"
}
