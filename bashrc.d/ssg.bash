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
    local extension="$1"
    local base_dir="$(git rev-parse --show-toplevel 2>/dev/null)"
    for _file in "$base_dir"/*/checks/oval/*."$extension" "$base_dir"/*/fixes/*/*."$extension"; do
        local file="$(basename "$_file")"
        local object="$(echo "$file" | sed "s/\\.$extension\$//g")"
        local found="$(find "$base_dir"/*/guide -path "*.git*" -prune -o -print | grep "\\/$object\\.")"
        if [ "x$found" == "x" ]; then
            echo "object without rule/group/var: $object"
        fi
    done
}

function find_profiles() {
    local extension="$1"
    local base_dir="$(git rev-parse --show-toplevel 2>/dev/null)"
    for _file in "$base_dir"/*/checks/oval/*."$extension" "$base_dir"/*/fixes/*/*."$extension"; do
        local file="$(basename "$_file")"
        local object="$(echo "$file" | sed "s/\\.$extension\$//g")"
        local found=""
        for profile in "$base_dir"/*/profiles/*.profile; do
            profile_found="$(grep "$object" "$profile")"
            found="$found$profile_found"
            if [ "x$found" != "x" ]; then
                break
            fi
        done
        if [ "x$found" == "x" ]; then
            echo "unused object: $object"
        fi
    done
}
