#!/bin/bash

function vm_list() {
    sudo virsh list
}

function vm_addrs() {
    sudo virsh domifaddr --full "$1"
}

function vssh() {
    local name="$(vm_list | grep -i "$1" | awk '{print $2}')"
    local lines="$(wc -l <<< "$name")"

    # When we have more than one line, check if our name is an exact match
    if (( lines != 1 )); then
        local exact="$(grep "^$1$" <<< "$name")"

        if [ "x$exact" == "x" ]; then
            echo "$name"
            return 1
        fi

        # Exact match; keep it.
        name="$1"
    fi

    local addr="$(vm_addrs "$name" | grep -o '192.168.122.[0-9]*' | head -n 1)"

    local user="$2"
    if [ "x$user" == "x" ]; then
        user="root"
    fi

    local command="$3"
    if [ "x$command" == "x" ]; then
        command="ssh"
    fi

    # ssh-copy-id "$user"@"$addr"
    echo ssh "$user"@"$addr"
    ssh "$user"@"$addr"
}
