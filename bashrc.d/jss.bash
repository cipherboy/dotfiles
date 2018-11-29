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

function frs1() {(
    set -e

    local tag="$1"
    local base_dir="$HOME/releases/jss/$tag"

    rm -rf "$base_dir"
    mkdir -p "$base_dir/upstream" 2>/dev/null
    cd "$base_dir/upstream"

    pwd
    wget "https://github.com/dogtagpki/jss/archive/$tag.tar.gz"
    tar -xf "$tag.tar.gz"

    cd "$base_dir"
    git clone "ssh://cipherboy@pkgs.fedoraproject.org/forks/cipherboy/rpms/jss.git"
    cd jss
    git checkout -b "$tag"
    meld jss.spec ../upstream/*/jss.spec
)}

function frs2() {(
    set -e

    local tag="$1"
    local base_dir="$HOME/releases/jss/$tag"
    local work_dir="$base_dir/build"

    cd "$base_dir"/upstream
    pwd

    rm -rf "$base_dir/upstream/jss"
    git clone https://github.com/dogtagpki/jss && cd jss
    git checkout "$tag"
    ./build.sh --source-tag="$tag" --work-dir="$work_dir" src

    cd "$base_dir/jss"
    fedpkg new-sources "$work_dir"/SOURCES/jss*.tar.gz
)}

function frs3() {(
    set -e

    source /etc/os-release

    local tag="$1"
    local base_dir="$HOME/releases/jss/$tag"
    local work_dir="$base_dir/build"

    cd "$base_dir/jss"

    fedpkg --release="f$VERSION_ID" local

    git add .gitignore
    git add jss.spec
    git add sources

    git commit -s -m "Rebased to JSS $tag"

    fedpkg copr-build @pki/10.6 --nowait

    echo "When this finishes, pick the changes into release branches."
)}

function frs4() {(
    set -e

    local tag="$1"
    local branch="$2"
    local base_dir="$HOME/releases/jss/$tag"

    rm -rf "$base_dir/downstream"
    mkdir -p "$base_dir/downstream"
    cd "$base_dir/downstream"
    pwd

    git clone https://src.fedoraproject.org/rpms/jss && cd jss
    git checkout "$branch"
    fedpkg build --nowait
)}
