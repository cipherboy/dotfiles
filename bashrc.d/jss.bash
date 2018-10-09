#!/bin/bash

function rebuild_docs() {
    local remote="https://github.com/cipherboy/jss-javadoc"
    local upstream="https://github.com/dogtagpki/jss"

    # Setup sandbox with dependencies
    local sandbox="/tmp/jssdocs-sandbox"
    (rm -rf "$sandbox" && mkdir -p "$sandbox") || return 1
    pushd "$sandbox" || return 2
    (hg clone https://hg.mozilla.org/projects/nspr && hg clone https://hg.mozilla.org/projects/nss && git clone "$remote" jss) || return 3
    cd "jss" || return 4

    # Build upstream/master's javadocs
    (git remote add upstream "$upstream" && git fetch --all && git checkout "upstream/master") || return 5
    export JAVA_HOME=/etc/alternatives/java_sdk_1.8.0_openjdk
    export USE_64=1
    (make javadoc && git clean -xdf) || return 6

    # Updates gh-pages with javadocs
    git checkout "gh-pages" || return 7
    (rm -rf "javadoc" && cp "../dist/jssdoc" "javadoc" -rv) || return 8
    (git add --all && git commit -m "Update javadocs from master at $(date '+%Y-%m-%d %H:%M')" && git push) || return 9
    popd
    rm -rf "$sandbox"
}
