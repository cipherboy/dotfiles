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
        for file in *; do
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

function getnextseries() {
    local path="$1"
    local filename="$(basename "$path")"
    local directory="$(dirname "$path")"
    local name="${filename/.jpg/}"
    if ! grep -q '[[:digit:]]\+$' <<< "$name"; then
        return 1
    fi

    local number="$(grep -o '[[:digit:]]\+$' <<< "$name")"
    local nextnumber=$(( number + 1 ))

    if [ "$directory" != "." ]; then
        echo -n "$directory/"
    fi
    echo -n "${name/$number/}"
    echo -n "$nextnumber"
    echo ".jpg"
}

function baseseries() {
    local path="$1"
    local filename="$(basename "$path")"
    local directory="$(dirname "$path")"
    local name="${filename/.jpg/}"
    if ! grep -q '[[:digit:]]\+$' <<< "$name"; then
        return 1
    fi

    local number="$(grep -o '[[:digit:]]\+$' <<< "$name")"
    local nextnumber=$(( number + 1 ))
    echo -n "${name/-$number/}"
}

function startseries() {
    local path="$1"
    echo "${path/.jpg/-1.jpg}"
}

function getcopyname() {
    local path="$1"
    local destination="$2"

    local src_size="$(stat --printf="%s" "$path")"
    local src_hash=""

    local series="$(baseseries "$path")"
    for count in `seq 1 1000`; do
        local dest_path="$destination/$series-$count.jpg"
        if [ ! -e "$dest_path" ]; then
            echo "$series-$count.jpg"
            return 0
        fi

        local dest_size="$(stat --printf="%s" "$dest_path")"
        if [ "$src_size" == "$dest_size" ]; then
            if [ -z "$src_hash" ]; then
                src_hash="$(openssl md5 -hex < "$path")"
            fi

            local dest_hash="$(openssl md5 -hex < "$dest_path")"
            if [ "$src_hash" == "$dest_hash" ]; then
                return 1
            fi
        fi
    done

    return 1
}

function copynext() {
    local source="$1"
    local dest="$2"

    if [ ! -d "$source" ] || [ ! -d "$dest" ]; then
        echo "Usage: copynext /path/to/sourcedir /path/to/destdir" 1>&2
        return 1
    fi

    for path in "$source"/*; do
        if [ ! -f "$path" ]; then
            echo "Skipping non-file $path..."
            continue
        fi

        local filename="$(basename "$path")"
        if [ -e "$dest/$filename" ]; then
            local next="$(getnextseries "$filename")"
            local copy="true"
            if [ -z "$next" ]; then
                local source_digest="$(openssl md5 -hex < "$path")"
                local dest_digest="$(openssl md5 -hex < "$dest/$filename")"
                if [ "$source_digest" != "$dest_digest" ]; then
                    # File already exists; copy to series and then increment.
                    local series_start="$(startseries "$filename")"
                    mv -v "$dest/$filename" "$dest/$series_start"

                    next="$(getnextseries "$series_start")"
                else
                    # Exists
                    copy="false"
                fi
            else
                next="$(getcopyname "$path" "$dest")"
                if [ -z "$next" ]; then
                    # Exists
                    copy="false"
                fi
            fi

            if [ "$copy" == "true" ]; then
                cp -v "$source/$filename" "$dest/$next"
            fi
        else
            cp -v "$path" "$dest/$filename"
        fi
    done
}

function copyunique() {
    local source="$1"
    local dest="$2"

    if [ ! -d "$source" ] || [ ! -d "$dest" ]; then
        echo "Usage: copyunique /path/to/sourcedir /path/to/destdir" 1>&2
        return 1
    fi

    for source_path in "$source"/*; do
        if [ ! -f "$source_path" ]; then
            echo "Skipping non-file $source_path..."
            continue
        fi

        local source_size="$(stat --printf="%s" "$source_path")"
        local source_hash="$(openssl md5 -hex < "$source_path")"
        local found_source="false"
        for dest_path in "$dest"/*; do
            local dest_size="$(stat --printf="%s" "$dest_path")"
            if [ "$source_size" != "$dest_size" ]; then
                continue
            fi

            local dest_hash="$(openssl md5 -hex < "$dest_path")"
            if [ "$dest_hash" == "$source_hash" ]; then
                found_source="true"
                break
            fi
        done

        if [ "$found_source" == "false" ]; then
            local filename="$(basename "$source_path")"
            cp -v "$source_path" "$dest/$filename"
        fi
    done
}
