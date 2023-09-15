#!/usr/bin/env bash

build::path::dir() {
    local -r v="$(workspace::dir)/build/$(resource::metadata::name)"
    if [ ! -d "$v" ]; then
        mkdir -p "$v"
    fi
    log trace "build: dir: $v"
    echo "$v"
}

build::path::config() {
    echo "$(build::path::dir)/config.yaml"
}

build::copy::file() {
    log debug "build: source: $(resource::source::path)"

    local src=$(resource::source::path)

    if [[ $src != /* ]]; then
        src="$(workspace::snapshot::dir)/$src"
    fi

    if [ -d "$src" ]; then
        src="${src%/}/"
    fi

    rm -rf "$(build::path::dir)"
    cp -r "$src" "$(build::path::dir)"
}

build::copy::source() {
    case "$(resource::source::scheme)" in
        "file")
            build::copy::file
            ;;
        *)
            log critical "Unsupported build provider: $(resource::source::scheme)"
            ;;
    esac
}

build::copy::environment() {
    if [ -f "$(workspace::snapshot::dir)/.envrc" ]; then
        cat "$(workspace::snapshot::dir)/.envrc" >> "$(build::path::dir)/.envrc"
        direnv allow "$(build::path::dir)"
    fi
}

build::new() {
    api::template::render_config "$(build::path::config)"
    api::template::render "$(build::path::config)" "$(build::path::dir)"
    build::copy::environment
    build::copy::source

    build::path::dir
}
