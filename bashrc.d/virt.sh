#!/bin/bash

function vm_list() {
    sudo virsh list
}

function vm_addrs() {
    sudo virsh domifaddr --full "$1"
}

function vssh() {
    local name="$(vm_list | grep "$1" | awk '{print $2}')"
    local lines="$(wc -l <<< "$name")"
    if (( lines != 1 )); then
        echo "$name"
        return 1
    fi

    local addr="$(vm_addrs "$name" | grep -o '192.168.122.[0-9]*' | head -n 1)"

    local user="$2"
    if [ "x$user" == "x" ]; then
        user="root"
    fi

    ssh-copy-id "$user"@"$addr"
    ssh "$user"@"$addr"
}
