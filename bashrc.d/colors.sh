#!/bin/bash

function ls_color() {
    local key="$1"
    IFS=":" read -r -a LS_COLORS_ARRAY <<< "$LS_COLORS"

    for color in "${LS_COLORS_ARRAY[@]}"; do
        color_key="${color/=*/}"
        color_value="${color/*=/}"
        if [ "x$color_key" == "x$key" ]; then
            echo "$color_value"
        fi
    done

    unset key
    unset LS_COLORS_ARRAY
}

function ecode() {
    for arg in "$@"; do
        if [ "x$arg" != "xreset" ]; then
            echo "\e[${arg}m"
        else
            echo "\e[0m"
        fi
    done
}

function ecolor() {
    echo -n -e "$(ecode "$(ls_color "$1")")"
    cat -
    echo -n -e "$(ecode "$(ls_color rs)")"
}
