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

# Screen
alias slist='screen -list'
alias srd='screen -r -d'
alias sS='screen -S'

# vim
alias r="v -R"

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

# Ansible
function ap() {
    local name="$1"
    shift
    local ret=0

    name="$(ffind --files --depth 1 yml "$name")"
    ret=$?
    if (( ret != 0 )); then
        echo "$name"
        return $ret
    fi

    echo ansible-playbook "$name" "$@"
    ansible-playbook "$name" "$@"
}

function aph() {
    local name="$1"
    shift

    ap "$name" -i hosts "$@"
}

function rte() {
    local role="$1"
    local path="roles/$role/tasks/main.yml"
    local bn="$(basename "$(pwd)")"

    if [ ! -e "$path" ] && [ -e "$role/tasks/main.yml" ]; then
        path="$role/tasks/main.yml"
    elif [ ! -e "$path" ] && [ "x$role" == "x$bn" ]; then
        path="tasks/main.yml"
    fi

    if [ ! -e "$path" ]; then
        echo "Unable to find tasks/main.yml for $role" 1>&2
        return 1
    fi
    "$EDITOR" "$path"
}

function rve() {
    local role="$1"
    local path="roles/$role/vars/main.yml"
    local bn="$(basename "$(pwd)")"

    if [ ! -e "$path" ] && [ -e "$role/vars/main.yml" ]; then
        path="$role/vars/main.yml"
    elif [ ! -e "$path" ] && [ "x$role" == "x$bn" ]; then
        path="vars/main.yml"
    fi

    if [ ! -e "$path" ]; then
        echo "Unable to find vars/main.yml for $role" 1>&2
        return 1
    fi
    "$EDITOR" "$path"
}

# Temporary directories
function tcd() {
    local num="$1"
    if [ "x$num" == "x" ]; then
        for i in `seq 1 1000`; do
            if [ ! -d "$HOME/tmp/$i" ]; then
                num="$i"
                break
            fi
        done
    fi

    mkdir -p "$HOME/tmp/$num" 2>/dev/null
    pushd "$HOME/tmp/$num"
}

# sort | uniq -c | sort -n
alias sun="sort | uniq -c | sort -n"
