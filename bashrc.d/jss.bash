#!/bin/bash

function rebuild_docs() {
    local remote_repo="jss-javadoc"
    local remote="https://github.com/cipherboy/$remote_repo"

    local sandbox="/tmp/jssdocs-sandbox-$RANDOM-$RANDOM"
    (rm -rf "$sandbox" && mkdir -p "$sandbox") || return 1
    pushd "$sandbox" || return 2

    (hg clone https://hg.mozilla.org/projects/nspr && hg clone https://hg.mozilla.org/projects/nss && git clone "$remote" jss) || return 3
    cd "jss" || return 4

    export JAVA_HOME=/etc/alternatives/java_sdk_1.8.0_openjdk
    export USE_64=1
    make javadoc || return 5
    git checkout "gh-pages" || return 6
    cp "../dist/jssdoc" "javadoc" -rv || return 7
    (git add --all && git commit -m "Update javadocs from master at $(date '+%Y-%m-%d %H:%M')" && git push) || return 8
    popd
    rm -rf "$sandbox"
}
