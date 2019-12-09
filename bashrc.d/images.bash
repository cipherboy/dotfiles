#!/bin/bash

IMAGE_PREFIX="AMS_"

function renum() {
    local const="$1"
    if [ "x$const" == "x" ]; then
        const=1000
    fi

    for num in `seq 1 1000`; do
        local nnum=$(( const + num ))
        local pnum="$(pad "$num")"
        local pnnum="$(pad "$nnum")"

        echo "$num | $nnum | $pnum | $pnnum"

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

function kpass() {
    local num="$1"
    mkdir "keep_pass_$num"
    mkdir "keep_pass_$num"_50
    rm keep keep_50
    ln -s "keep_pass_$num" keep
    ln -s "keep_pass_$num"_50 keep_50
}

function k() {
    local number="$(pad "$1")"

    if [ ! -d "all" ]; then
        echo "Refusing to work: directory all does not exist" 1>&2
        return 1
    fi

    if [ ! -d "keep" ]; then
        echo "Refusing to work: directory keep does not exist" 1>&2
        return 1
    fi

    cp "all/$IMAGE_PREFIX$number.jpg" -v "keep/$IMAGE_PREFIX$number.jpg"
    cp "all_50/$IMAGE_PREFIX$number.jpg" -v "keep_50/$IMAGE_PREFIX$number.jpg"
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

    pushd "$name"
        parallel -j 150% convert -resize 50% '{}' ../"$name"_50/'{}' ::: *.jpg
    popd
}

function o50() {
    ln -s orig all
    r50 all
    mv all_50 orig_50
    ln -s orig_50 all_50
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

function ccpy() {
    local src="$(realpath "$1")"
    local dst="$(realpath "$2")"

    if [ ! -d "$src" ]; then
        echo "Usage: ccpy /path/to/camera-card /path/to/destination" 1>&2
        echo "Unable to find source!" 1>&2
        return 1
    fi

    if [ ! -d "$dst" ]; then
        mkdir -p "$dst"
    fi

    pushd "$src"
        for file in *.JPG; do
            local shash="$(sha512sum < "$src/$file")"
            local dhash="$(sha512sum < "$dst/$file")"

            while [ "x$shash" != "x$dhash" ]; do
                if [ -e "$dst/$file" ]; then
                    rm "$dst/$file"
                fi
                cp -prv "$src/$file" "$dst/$file"

                shash="$(sha512sum < "$src/$file")"
                dhash="$(sha512sum < "$dst/$file")"
            done
        done
    popd
}
