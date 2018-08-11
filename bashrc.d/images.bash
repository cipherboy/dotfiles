#!/bin/bash

IMAGE_PREFIX="DSC_"

function renum() {
    local const="$1"
    if [ "x$const" == "x" ]; then
        const=1000
    fi

    for num in `seq 1 1000`; do
        local nnum=$(( const + num ))
        local pnum="$(pad "$num")"
        local pnnum="$(pad "$nnum")"

        if [ -e "$IMAGE_PREFIX$pnum.jpg" ]; then
            mv "$IMAGE_PREFIX$pnum.jpg" "$IMAGE_PREFIX$pnnum.jpg"
        fi
    done
}

function ext() {
    rename JPG jpg *.JPG
    return $?
}

function pad() {
    local number="$1"
    if (( ${#number} == 0 )); then
        echo "0000"
    elif (( ${#number} == 1 )); then
        echo "000$number"
    elif (( ${#number} == 2 )); then
        echo "00$number"
    elif (( ${#number} == 3 )); then
        echo "0$number"
    else
        echo "$number"
    fi
}

function k() {
    local number="$(pad "$1")"

    if [ ! -d "all" ]; then
        echo "Refusing to work: directory all does not exist" 1>&2
        return 1
    fi

    if [ ! -d "keep" ]; then
        mkdir -p "keep"
    fi

    cp "all/$IMAGE_PREFIX$number.jpg" -v "keep/$IMAGE_PREFIX$number.jpg"
}

function r50() {
    local name="$1"
    if [ "x$name" == "x" ]; then
        name="all"
    fi

    if [ ! -d "$name" ]; then
        echo "Refusing to work: directory $name does not exist" 1>&2
        return 1
    fi

    mkdir -p "$name"_50
    cp "$name"/*.jpg -rv "$name"_50/

    pushd "$name"_50
        for file in *.jpg; do
            convert -resize 50% $file $file
        done
    popd
}

function k50() {
    r50 "keep"
}

function pano() {
    local pano_num="$1"
    local min_num="$2"
    local max_num="$3"
    local pano_dir="pano_$pano_num"

    if [ ! -d "all" ]; then
        echo "Refusing to work: directory all does not exist" 1>&2
        return 1
    fi

    if [ ! -d "$pano_dir" ]; then
        mkdir "$pano_dir"
    fi

    for num in $(seq $min_num $max_num); do
        local pad_num="$(pad "$num")"
        cp "all/$IMAGE_PREFIX$pad_num.jpg" -v "$pano_dir/$IMAGE_PREFIX$pad_num.jpg"
    done
}

function person() {
    local name="$1"
    local number="$(pad "$2")"

    if [ ! -d "all" ]; then
        echo "Refusing to work: directory all does not exist" 1>&2
        return 1
    fi

    if [ ! -d "$name" ]; then
        mkdir -p "$name"
    fi

    cp -v "all/$IMAGE_PREFIX$number.jpg" -v "$name/$IMAGE_PREFIX$number.jpg"
}
