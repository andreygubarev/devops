#!/usr/bin/env bash

build::path::dir() {
    local -r v="$(workspace::dir)/build/$(resource::metadata::name)"
    if [ ! -d "$v" ]; then
        mkdir -p "$v"
    fi
    log debug "build: dir: $v"
    echo "$v"
}

build::path::config() {
    echo "$(build::path::dir).config.yaml"
}

build::copy::file() {
    log debug "build: source: $(resource::source::path)"

    cp "$(resource::path)" "$(build::path::dir)/resource.yml"

    local src=$(resource::source::path)
    if [[ $src != /* ]]; then
        src="$(workspace::snapshot::dir)/$src"
    fi
    if [ -d "$src" ]; then
        src="${src%/}/"
    fi
    rm -rf "$(build::path::dir)/src"
    cp -r "$src" "$(build::path::dir)/src"
}

build::source() {
    case "$(resource::source::scheme)" in
        "file")
            build::copy::file
            ;;
        *)
            log critical "Unsupported build provider: $(resource::source::scheme)"
            ;;
    esac
}

build::environment() {
    if [ ! -f "$(build::path::dir)/.envrc" ]; then
        touch "$(build::path::dir)/.envrc"
    fi

    api::environment >> "$(build::path::dir)/.envrc"

    local -r envrc="$(resource::query '.metadata.annotations["direnv.net/envrc"]')"
    if [ -n "$envrc" ]; then
        echo "$envrc" >> "$(build::path::dir)/.envrc"
    fi

    direnv allow "$(build::path::dir)"
}

build::new() {
    api::template::render_config "$(build::path::config)"
    api::template::render "$(build::path::config)" "$(workspace::dir)/build/"
    build::environment
    build::source

    build::path::dir
}
