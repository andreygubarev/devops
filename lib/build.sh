#!/usr/bin/env bash

build::dist() {
    local -r v="$(resource::dir)/.infractl/dist/$(resource::metadata::name)"
    mkdir -p "$v"
    echo "$v" | sed 's/\/$//'
}

build::output() {
    echo "$(build::dist)/$(resource::version)"
}

build::config() {
    echo "$(build::output).config.yaml"
}

build::provider() {
    resource::metadata::kind | cut -d':' -f1
}

build::source_path() {
    resource::metadata::kind | cut -d':' -f2 | cut -d'/' -f2- | cut -d'/' -f2-
}

build::source_using_file() {
    log info "copying source: $(build::source_path)"

    local source=$(build::source_path)

    if [[ $source != /* ]]; then
        source="$(resource::dir)/$source"
    fi

    if [ -d "$source" ]; then
        source="${source%/}/"
    fi

    rm -rf "$(build::output)/src"
    cp -r "$source" "$(build::output)/src/"
}

build::source() {
    cp "$(resource::path)" "$(build::output)/manifest.yaml"

    case "$(build::provider)" in
        "file")
            build::source_using_file
            ;;
        *)
            log critical "Unsupported build provider: $(build::provider)"
            ;;
    esac
}

build::environment() {
    if [ -f "$(resource::dir)/.envrc" ]; then
        cat "$(resource::dir)/.envrc" >> "$(build::output)/.envrc"
    fi
    direnv allow "$(build::output)"
}

build::new() {
    api::render_template_config "$(build::config)"
    api::render_template "$(build::config)" "$(build::dist)"
    build::environment
    build::source

    build::output
}
