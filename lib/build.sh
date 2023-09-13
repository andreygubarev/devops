#!/usr/bin/env bash

build_dist() {
    local -r v="$(manifest::dir)/.infractl/dist/$(manifest::name)"
    mkdir -p "$v"
    echo "$v"
}

build_output() {
    echo "$(build_dist)/$(manifest::version)"
}

build_config() {
    echo "$(build_output).config.yaml"
}

build_provider() {
    manifest::kind | cut -d':' -f1
}

build_source_path() {
    manifest::kind | cut -d':' -f2 | cut -d'/' -f2- | cut -d'/' -f2-
}

build_source_using_file() {
    log info "copying source: $(build_source_path)"

    local source=$(build_source_path)

    if [[ $source != /* ]]; then
        source="$(manifest::dir)/$source"
    fi

    if [ -d "$source" ]; then
        source="${source%/}/"
    fi

    rm -rf "$(build_output)/src"
    cp -r "$source" "$(build_output)/src/"
}

build_source() {
    cp "$(manifest::path)" "$(build_output)/manifest.yaml"

    case "$(build_provider)" in
        "file")
            build_source_using_file
            ;;
        *)
            log critical "Unsupported build provider: $(build_provider)"
            ;;
    esac
}

build_environment() {
    if [ -f "$(manifest::dir)/.envrc" ]; then
        cat "$(manifest::dir)/.envrc" >> "$(build_output)/.envrc"
    fi
    direnv allow "$(build_output)"
}

build::new() {
    api::render_template_config "$(build_config)"
    api::render_template "$(build_config)" "$(build_dist)"
    build_environment
    build_source

    build_output
}
