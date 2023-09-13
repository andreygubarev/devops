#!/usr/bin/env bash

build::path::dist() {
    local -r v="$(resource::dir)/.infractl/dist/$(resource::metadata::name)"
    mkdir -p "$v"
    echo "$v" | sed 's/\/$//'
}

build::path::output() {
    echo "$(build::path::dist)/$(resource::version)"
}

build::path::config() {
    echo "$(build::path::output).config.yaml"
}

build::source_using_file() {
    log info "copying source: $(resource::source::path)"

    local source=$(resource::source::path)

    if [[ $source != /* ]]; then
        source="$(resource::dir)/$source"
    fi

    if [ -d "$source" ]; then
        source="${source%/}/"
    fi

    rm -rf "$(build::path::output)/src"
    cp -r "$source" "$(build::path::output)/src/"
}

build::push_source() {
    cp "$(resource::path)" "$(build::path::output)/manifest.yaml"

    case "$(resource::source::scheme)" in
        "file")
            build::source_using_file
            ;;
        *)
            log critical "Unsupported build provider: $(resource::source::scheme)"
            ;;
    esac
}

build::push_environment() {
    if [ -f "$(resource::dir)/.envrc" ]; then
        cat "$(resource::dir)/.envrc" >> "$(build::path::output)/.envrc"
    fi
    direnv allow "$(build::path::output)"
}

build::new() {
    api::template::render_config "$(build::path::config)"
    api::template::render "$(build::path::config)" "$(build::path::dist)"
    build::push_environment
    build::push_source

    build::path::output
}
