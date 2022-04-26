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

    podman pull "$version" || true
    podman run --volume "$HOME/.ccache:/root/.ccache:shared" -ti "$version" /bin/bash
}

alias crl="podman container list"

function cra() {
    local name="$1"
    local matches="$(crl | grep -i "$name" | wc -l)"

    if (( matches == 0 )); then
        crl
        echo "No matching containers for $name"
        return 1
    elif (( matches > 1 )); then
        crl | grep -i "$name"
        return $matches
    fi

    local match="$(crl | grep -i "$name" | awk '{print $1}')"
    echo "Attaching to $match..."

    podman exec -ti "$match" bash -i
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
    local extra_args=()
    local ret=0

    if [ ! -e "$name" ]; then
        name="$(ffind --files --depth 1 yml "$name")"
        ret=$?
        if (( ret != 0 )); then
            echo "$name"
            return $ret
        fi
    fi

    if [ -e hosts ]; then
        extra_args+=("-i" "hosts")
    fi

    echo ansible-playbook "$name" "${extra_args[@]}" "$@"
    ansible-playbook "$name" "${extra_args[@]}" "$@"
    ret=$?

    rm -f ./*.retry

    return $ret
}

function ap8() {
    local name="$1"
    shift

    ap "$name" -e ansible_python_interpreter=/usr/libexec/platform-python "$@"
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
        ls --color=always -d roles/* | sed 's/roles\///g'
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
        ls --color=always -d roles/* | sed 's/roles\///g'
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

    local do_ls="false"
    if [ -e "$HOME/tmp/$num" ]; then
        do_ls="true"
    fi

    mkdir -p "$HOME/tmp/$num" 2>/dev/null
    pushd "$HOME/tmp/$num"

    if [ "$do_ls" == "true" ]; then
        ls
    fi
}

# sort | uniq -c | sort -n
alias sun="sort | uniq -c | sort -n"

# A shrug!
alias shrug="echo '¯\_(ツ)_/¯'"

# Kill from ps
function pskill() {
    awk '{print $2}' | xargs -l kill
}

# Do a lot of builds
alias badwc="build all warnings debug && build all warnings debug clang && build all && build all clang"

# Use Podman over Docker
function use_podman() {
    systemctl --user enable --now podman.socket
    export DOCKER_HOST=unix:///run/user/1000/podman/podman.sock
}
