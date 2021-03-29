#!/bin/bash

alias qa='quilt applied'
alias qi='quilt import'
alias qs='quilt series'

function qip() {
    local patch="$1"
    if [ ! -z "$QUILT_RELATIVE" ] && [ -e "$QUILT_RELATIVE" ]; then
        patch="$QUILT_RELATIVE/$patch"
    fi

    quilt import "$patch" && quilt push
}

function qipa() {
    for arg in "$@"; do
        qip "$arg"
    done
}
