#!/bin/bash

function re() {
    # Edit a rule.
    local rule="$1"
    v "$rule.*/rule.yml:3"
}

function nr() {
    # Create and commit a new rule for CIS.
    local r="$1"
    local c="$2"

    mkdir "$r" && vim "$r/rule.yml" && gta "$r" && gtm -m "Add $r for $2"
}

function rdir() {
    # Change into a rule's directory.
    local rule="$1"
    local rule_yml="$(find "$(gtcd)" -type f | sed '/\/build\//d' | sed '/\/\.git\//d' | grep -i "$rule" | grep -i 'rule\.yml')"
    local dir="$(dirname "$rule_yml")"
    echo "$dir"
    cd "$dir"
}

function cis() {
    # Find CIS references in a rule.
    local rule="$1"
    local dir="$(rdir "$rule")"
    grep 'cis@ubuntu' "$dir/rule.yml"
}

function acis() {
    # Find all files matching a specified CIS reference.
    local identifier="$1"
    grep -ir "cis@ubuntu.*$identifier" "$(gtcd)" | grep -i 'rule\.yml:'
}

function new_oval() {
    # Create a new OVAL file with the given description.
    local description="$1"
    shift

    local platform="${1:-ubuntu}"
    local oval="oval/$platform.xml"

    mkdir oval

    echo '<def-group>' > "$oval"
    echo '  <definition class="compliance" id="{{{ rule_id }}}" version="1">' >> "$oval"
    echo '    {{{ oval_metadata("'"$description"'") }}}' >> "$oval"

    v "$oval"
}

function rdj() {
    # Generate the rule directory json mapping.
    (
        gtcd
        ./utils/rule_dir_json.py
    )
}

export PYTHONPATH="$(gtcd):$PYTHONPATH"
export PATH="$PATH:$(gtcd)/utils"
export BUILD_CMAKE_ARGS=("-DSSG_PRODUCT_DEFAULT=OFF" "-DSSG_PRODUCT_UBUNTU2004=ON")

alias ery='python3 ./tools/extract_rule_yml.py cisbenchmark/audit/Canonical_Ubuntu_20.04_CIS_Benchmark-xccdf.xml'

function eo() {
    # Export contained OVAL from existing benchmark.
    python3 ./tools/extract_oval.py cisbenchmark/audit/Canonical_Ubuntu_20.04_CIS_Benchmark-oval.xml "$1" | sed 's/^  //'
}
