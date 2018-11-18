#!/bin/bash

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
    pass show -c 1 "$account"
}

alias upl="pass ls"
