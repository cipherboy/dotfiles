function codeql-dbc() {(
    local language="$1"
    if [ -z "$language" ]; then
        echo "Must specify language" 2>&1
        return 1
    fi

    if [ "x$language" == "xgo" ]; then
        # Create a temporary $GOPATH to use for building
        export GOPATH="/tmp/codeql-gopath-$RANDOM-$RANDOM-$RANDOM"
        mkdir -p "$GOPATH"/{bin,src}
    fi

    local codeql_root="$HOME/Documents/CodeQL"
    if [ ! -e "$codeql_root" ]; then
        mkdir -p "$codeql_root"
    fi

    local git_root="$(gtcd)"
    local git_name="$(basename "$git_root")"
    local git_hash="$(git rev-parse HEAD)"

    if ! git diff --quiet ; then
        git_hash="$git_hash-dirty"
    fi

    local codeql_dir="$git_name-$git_hash-$language"
    codeql database create --language="$language" "$codeql_root/$codeql_dir"
)}
