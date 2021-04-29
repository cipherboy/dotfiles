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
    local dir="$(rc "$rule")"
    grep 'cis@ubuntu' "$dir/rule.yml"
}

function acis() {
    # Find all files matching a specified CIS reference.
    local identifier="$1"
    grep -ir "cis@ubuntu.*$identifier" "$(gtcd)" | grep -i 'rule\.yml:'
}

export PYTHONPATH="$(gtcd):$PYTHONPATH"
export PATH="$PATH:$(gtcd)/utils"
export BUILD_CMAKE_ARGS=("-DSSG_PRODUCT_DEFAULT=OFF" "-DSSG_PRODUCT_UBUNTU2004=ON")

alias ery='python3 ./tools/extract_rule_yml.py cisbenchmark/audit/Canonical_Ubuntu_20.04_CIS_Benchmark-xccdf.xml'
alias eo='python3 ./tools/extract_oval.py cisbenchmark/audit/Canonical_Ubuntu_20.04_CIS_Benchmark-oval.xml'
