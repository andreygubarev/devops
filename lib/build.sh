#!/usr/bin/env bash

build::dist() {
    local -r v="$(manifest::dir)/.infractl/dist/$(manifest::name)"
    mkdir -p "$v"
    echo "$v" | sed 's/\/$//'
}

build::output() {
    echo "$(build::dist)/$(manifest::version)"
}

build::config() {
    echo "$(build::output).config.yaml"
}

build::provider() {
    manifest::kind | cut -d':' -f1
}

build::source_path() {
    manifest::kind | cut -d':' -f2 | cut -d'/' -f2- | cut -d'/' -f2-
}

build::source_using_file() {
    log info "copying source: $(build::source_path)"

    local source=$(build::source_path)

    if [[ $source != /* ]]; then
        source="$(manifest::dir)/$source"
    fi

    if [ -d "$source" ]; then
        source="${source%/}/"
    fi

    rm -rf "$(build::output)/src"
    cp -r "$source" "$(build::output)/src/"
}

build::source() {
    cp "$(manifest::path)" "$(build::output)/manifest.yaml"

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
    if [ -f "$(manifest::dir)/.envrc" ]; then
        cat "$(manifest::dir)/.envrc" >> "$(build::output)/.envrc"
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
