function __codeql-dbi() {
    # Generate database identifier for the current git checkout.
    local language="$1"

    local git_root="$(gtcd)"
    local git_name="$(basename "$git_root")"
    local git_hash="$(git rev-parse HEAD)"

    if ! git diff --quiet ; then
        git_hash="$git_hash-dirty"
    fi

    echo "$git_name-$git_hash-$language"
}

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

    local codeql_dir="$(__codeql-dbi "$language")"

    if [ -e "$codeql_root/$codeql_dir" ] && [ "$codeql_dir" = *"dirty-$language" ]; then
        rm -rf "$codeql_root/$codeql_dir"
    fi

    if [ ! -e "$codeql_root/$codeql_dir" ]; then
        codeql database create --threads=0 --language="$language" "$codeql_root/$codeql_dir"
    fi
)}

function codeql-query() {(
    local language="$1"
    local query="$2"
    local codeql_root="$HOME/Documents/CodeQL"
    local codeql_git="$HOME/GitHub/github/codeql"
    local codeql_go_git="$HOME/GitHub/github/codeql-go"

    if [ "x$language" == "xgo" ]; then
        # Create a temporary $GOPATH to use for building
        export GOPATH="/tmp/codeql-gopath-$RANDOM-$RANDOM-$RANDOM"
        mkdir -p "$GOPATH"/{bin,src}
    fi

    local codeql_dir="$(__codeql-dbi "$language")"
    if [ ! -e "$codeql_root/$codeql_dir" ]; then
        codeql-dbc "$language"
        ret=$?

        if (( ret != 0 )); then
            return $ret
        fi
    fi

    query_path="x"
    if [ "x$language" == "xgo" ]; then
        pushd "$codeql_go_git/ql/src" >/dev/null
        local num_results="$(gff -- "$query"'.*\.ql$' | wc -l)"
        if (( num_results != 1 )); then
            echo "Expected 1 result but found $num_results" 1>&2
            gff -- "$query"'.*\.ql$'
            return 1
        fi

        query_path="$(pwd)/$(gff -- "$query"'.*\.ql$')"

        popd > /dev/null
    else
        pushd "$codeql_git/$language/ql/src" > /dev/null

        local num_results="$(gff -- "$query"'.*\.ql$' | wc -l)"
        if (( num_results != 1 )); then
            echo "Expected 1 result but found $num_results" 1>&2
            gff -- "$query"'.*\.ql$'
            return 1
        fi

        query_path="$(pwd)/$(gff -- "$query"'.*\.ql$')"
        echo "Set query path"

        popd > /dev/null
    fi

    if [ "x$query_path" == "xx" ]; then
        echo "Unable to find specified query: $query!" 1>&2
        return 1
    fi

    local tmpout="/tmp/codeql-query-$RANDOM-$RANDOM-$RANDOM"
    codeql database analyze --threads=0 "$codeql_root/$codeql_dir" --additional-packs="$codeql_git:$codeql_go_git" --format=sarif-latest --output="$tmpout" "$query_path" && cat "$tmpout"
)}
