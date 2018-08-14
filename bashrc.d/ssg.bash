#!/bin/bash

function s() {
    export rdir="$1"
    n
    d
}

function k() {
    cp "$file" "$rdir/$file"
    re
    git add "$rdir/$file"
    git commit -m "Add $file to linux_os"
    n
    d
}

function r() {
    rm "$file"
    n
    d
}

function d() {
    echo "$file"
    diff "$file" "$rdir/$file"
}

function re() {
    vi "$rdir/$file"
}

function ur() {
    git add "$rdir/$file"
    git commit -m "Update $file in linux_os"
}

function e() {
    vi "$file"
}

function c() {
    cat "$file"
}

function rc() {
    cat "$rdir/$file"
}

function n() {
    next_file="$(find . -not -path '*/\.*' -type f | head -n 1 | sed 's/^\.\///g')"
    export file="$next_file"
}

function r6r() {
    for file in $(gts | grep 'deleted:[[:space:]]*rhel6' | sed 's/deleted://'); do
        git add "$file"
        git commit -m "Remove $file"
    done
}

function find_rules() {
    local extension="$1"
    local base_dir="$(git rev-parse --show-toplevel 2>/dev/null)"
    for _file in "$base_dir"/*/checks/oval/*."$extension" "$base_dir"/*/fixes/*/*."$extension"; do
        local file="$(basename "$_file")"
        local object="$(echo "$file" | sed "s/\\.$extension\$//g")"
        local found="$(find "$base_dir"/*/guide -path "*.git*" -prune -o -print | grep "\\/$object\\.")"
        if [ "x$found" == "x" ]; then
            echo "object without rule/group/var: $object"
        fi
    done
}

function find_profiles() {
    local extension="$1"
    local base_dir="$(git rev-parse --show-toplevel 2>/dev/null)"
    for _file in "$base_dir"/*/checks/oval/*."$extension" "$base_dir"/*/fixes/*/*."$extension"; do
        local file="$(basename "$_file")"
        local object="$(echo "$file" | sed "s/\\.$extension\$//g")"
        local found=""
        for profile in "$base_dir"/*/profiles/*.profile; do
            profile_found="$(grep "$object" "$profile")"
            found="$found$profile_found"
            if [ "x$found" != "x" ]; then
                break
            fi
        done
        if [ "x$found" == "x" ]; then
            echo "unused object: $object"
        fi
    done
}

function find_profile_rules() {
    local profile="$1"
    local base_dir="$(git rev-parse --show-toplevel 2>/dev/null)"

    local profile_rules="$(grep '^    - ' "$profile" | sed 's/^    - //g' | sed 's/=.*$//g')"
    for rule in $profile_rules; do
        local found="$(find "$base_dir"/*/guide | grep "\\/$rule\\.")"
        local found_count="$(find "$base_dir"/*/guide | grep "\\/$rule\\." | wc -l)"
        if [ "x$found" == "x" ]; then
            echo "$rule - NOTFOUND"
        elif [ "x$found_count" != "x1" ]; then
            echo "$rule - $found_count"
        else
            echo "$rule - $found"
        fi
    done
}

function list_shared_ovals_multiplatform() {
    local base_dir="$(git rev-parse --show-toplevel 2>/dev/null)"
    for _file in "$base_dir"/*/checks/oval/*.xml; do
        local file="$(basename "$_file")"
        local object="${file%.xml}"
        local usages="$(grep -l " - $object$" "$base_dir"/*/profiles/*.profile | sed 's/\/profiles\/[^\.]*\.profile$//g' | sort -u | wc -l)"
        if (( usages > 1 )); then
            echo "$_file"
        fi
    done
}

function pcd() {
    local base_dir="$(git rev-parse --show-toplevel 2>/dev/null)"
    local new_product="$1"
    local current_dir="$(pwd)"
    local current_prod_path="${current_dir#$base_dir}"
    current_prod_path="${current_prod_path#/}"
    local new_path="$base_dir/$new_product/${current_prod_path#*/}"
    pushd "$new_path"
}

function rrme() {
    gtcd
    gtum
    gto reorganize-rules
    gtrm
    git clean -xdf
    python3 ./utils/move_rules.py `pwd` > /tmp/rrme-script.sh
    bash /tmp/rrme-script.sh
    git add -A
    git commit -m "Move everything"
}
