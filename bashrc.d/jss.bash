#!/bin/bash

function rebuild_docs() {
    local user="cipherboy"
    local remote="https://github.com/$user/jss"
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
    git checkout "upstream/gh-pages" || return 7
    git branch -D "gh-pages"
    git checkout -b "gh-pages" || return 9
    (rm -rf "javadoc" && cp "../dist/jssdoc" "javadoc" -rv) || return 10
    (git add --all && git commit -m "Update javadocs from master at $(date '+%Y-%m-%d %H:%M')" && git push --set-upstream origin gh-pages --force) || return 11
    popd
    rm -rf "$sandbox"

    echo ""
    echo ""
    echo "All done! To open a PR, click the following link:"
    echo "https://github.com/dogtagpki/jss/compare/gh-pages...$user:gh-pages"
}
