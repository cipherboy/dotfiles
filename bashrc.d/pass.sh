#!/bin/bash

# This is useful for when the user arrives via sudo with left over environment
# variables floating around.
_cur_tty="$(tty)"
if [ "x$GPG_TTY" != "x" ] && [ "x$GPG_TTY" != "x$_cur_tty" ]; then
    # Sanity check: validate tty is owned by user, else reset it to `tty`.
    gpg_tty_owner="$(stat --format '%U' "$GPG_TTY")"
    if [ "x$gpg_tty_owner" != "x$USER" ]; then
        export GPG_TTY="$_cur_tty"
    fi
fi

function upd() {
    local subfolder="$1"
    pass init -p "$subfolder" "$(cat ~/.password-store/.gpg-id)"
}

function upi() {
    local account="$1"
    pass insert "$account"
}

function upe() {
    local account="$1"
    pass edit "$account"
}

function ups() {
    local account="$1"
    pass show "$account"
}

function upc() {
    local account="$1"
    pass show -c1 "$account"
}

alias upl="pass ls"
