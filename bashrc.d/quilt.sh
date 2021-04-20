#!/bin/bash

function qup() {
    # Find absolute directory of patches in a debian/patches setup. Export
    # it as QUILT_PATCHES=<dir> so that quilt can find it automagically.

    if [ -e patches ]; then
        export QUILT_PATCHES="$(pwd)/patches"
    elif [ -e debian/patches ]; then
        export QUILT_PATCHES="$(pwd)/debian/patches"
    elif [ -e ../debian/patches ]; then
        export QUILT_PATCHES="$(pwd)/../debian/patches"
    elif [ -e ../../debian/patches ]; then
        export QUILT_PATCHES="$(pwd)/../../debian/patches"
    elif [ -e ../../../debian/patches ]; then
        export QUILT_PATCHES="$(pwd)/../../../debian/patches"
    elif [ -e ../../../../debian/patches ]; then
        export QUILT_PATCHES="$(pwd)/../../../../debian/patches"
    fi
}

alias qa='qup ; quilt applied'
alias qi='qup ; quilt import'
alias qs='qup ; quilt series'

function qip() {
    local patch="$1"
    if [ ! -z "$QUILT_RELATIVE" ] && [ -e "$QUILT_RELATIVE" ]; then
        patch="$QUILT_RELATIVE/$patch"
    fi

    qup
    quilt import "$patch" && quilt push
}

function qipa() {
    for arg in "$@"; do
        qip "$arg"
        local ret="$?"
        if (( ret != 0 )); then
            echo "qip $arg returned: $ret" 1>&2
            return $ret
        fi
    done
}
