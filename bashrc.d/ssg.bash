function s() {
    export rdir="$1"
    n
    d
}

function k() {
    cp "$file" "$rdir/$file"
    re
    git add "$rdir/$file"
    git commit -m "Add $file to linux_os"
    n
    d
}

function r() {
    rm "$file"
    n
    d
}

function d() {
    echo "$file"
    diff "$file" "$rdir/$file"
}

function re() {
    vi "$rdir/$file"
}

function ur() {
    git add "$rdir/$file"
    git commit -m "Update $file in linux_os"
}

function e() {
    vi "$file"
}

function c() {
    cat "$file"
}

function rc() {
    cat "$rdir/$file"
}

function n() {
    next_file="$(find . -not -path '*/\.*' -type f | head -n 1 | sed 's/^\.\///g')"
    export file="$next_file"
}

function r6r() {
    for file in $(gts | grep 'deleted:[[:space:]]*rhel6' | sed 's/deleted://'); do
        git add "$file"
        git commit -m "Remove $file"
    done
}

function find_rules() {
    local guide_path="$1"
    for oval_file in *.xml; do
        local object="$(echo "$oval_file" | sed 's/\.xml$//g')"
        local found="$(find "$guide_path" -path "*.git*" -prune -o -print | grep "$object")"
        if [ "x$found" == "x" ]; then
            echo "Missing rule for oval: $object"
        fi
    done
}
