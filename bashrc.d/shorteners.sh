#!/bin/sh

# Python
alias p2="python2"
alias p3="python3"

# SSH
alias sr7="ssh recon7"
alias sr7m="ssh recon7 -t 'screen -r -d media'"
alias sr7r="ssh recon7r"
alias pr7="sftp recon7"
alias pr7r="sftp recon7r"

function sirc() {
    local host="$1"
    if [ "x$host" = "x" ]; then
        host="cipherboy"
    fi

    ssh "chat@$host" -t 'screen -r -d'
}

# vim
alias v="vim"

# podman

function cr() {
    local version="$1"
    if [ "x$version" = "x" ]; then
        version="fedora:rawhide"
    fi

    podman run -ti "$version" /bin/bash
}

function crc() {
    local version="$1"
    if [ "x$version" = "x" ]; then
        version="fedora:rawhide"
    fi

    cr "cipherboy_$version"
}
