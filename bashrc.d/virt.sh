#!/bin/bash

function svirsh() {
    virsh -c 'qemu:///system' "$@"
}

function vm_list() {
    svirsh list
}

function vm_addrs() {
    svirsh domifaddr --full "$1"
}

function vssh_addr() {
    local search="$1"
    shift

    local name="$(vm_list | grep -i "$search" | awk '{print $2}')"
    local lines="$(wc -l <<< "$name")"

    # When we have more than one line, check if our name is an exact match
    if (( lines != 1 )); then
        local exact="$(grep "^$search$" <<< "$name")"

        if [ "x$exact" == "x" ]; then
            echo "$name"
            return 1
        fi

        # Exact match; keep it.
        name="$1"
    fi

    local addr="$(vm_addrs "$name" | grep -o '192.168.122.[0-9]*' | tail -n 1)"
    echo "$addr"
    return 0
}

function vssh() {
    local search=""
    local user="root"
    local echo="true"
    local seen_remainder="false"
    local remainder=()

    while (( $# > 0 )); do
        local arg="$1"
        shift

        if [ "x$arg" == "x-l" ]; then
            if [ "$seen_remainder" == "false" ]; then
                user="$1"
                shift
            else
                remainder+=("$arg")
            fi
        elif [ "x$arg" == "x--silent" ]; then
            if [ "$seen_remainder" == "false" ]; then
                echo="false"
            else
                remainder+=("$arg")
            fi
        elif [ "x$arg" == "--" ]; then
            seen_remainder="true"
            remainder+=("$arg")
        elif [ -z "$search" ] && [ "x${arg[0]}" != "x-" ]; then
            search="$arg"
        else
            remainder+=("$arg")
        fi
    done

    local addr=""
    addr="$(vssh_addr "$search")"
    ret=$?

    if (( ret != 0 )); then
        echo "$addr"
        return 1
    fi

    if [ "$echo" == "true" ]; then
        echo ssh -o StrictHostKeyChecking=no "$user"@"$addr" "${remainder[@]}"
    fi

    ssh -o StrictHostKeyChecking=no "$user"@"$addr" "${remainder[@]}"
}

function vsftp() {
    local search="$1"
    shift

    local addr=""
    addr="$(vssh_addr "$search")"
    ret=$?

    if (( ret != 0 )); then
        echo "$addr"
        return 1
    fi

    local user="root"
    local remainder=()

    while (( $# > 0 )); do
        local arg="$1"
        shift

        if [ "x$arg" == "x-l" ]; then
            user="$1"
            shift
        else
            remainder+=("$arg")
        fi
    done

    echo sftp -o StrictHostKeyChecking=no "$user"@"$addr" "${remainder[@]}"
    sftp -o StrictHostKeyChecking=no "$user"@"$addr" "${remainder[@]}"
}

function vsci() {
    local search="$1"
    local user="$2"

    if [ "x$user" == "x" ]; then
        user="root"
    fi

    local addr=""
    addr="$(vssh_addr "$search")"
    ret=$?

    if (( ret != 0 )); then
        echo "$addr"
        return 1
    fi

    echo ssh-copy-id "$user"@"$addr"
    ssh-copy-id "$user"@"$addr"
}

function mechid() {
    dd status=none if=/dev/urandom bs=128 count=1 | md5sum | awk '{print $1}'
}

function vmechid() {
    echo -n "Before: "
    vssh --silent "$@" -- cat /etc/machine-id
    mechid | vssh --silent "$@" -- bash -c 'cat -  > /etc/machine-id'
    echo -n "After: "
    vssh --silent "$@" -- cat /etc/machine-id
}
