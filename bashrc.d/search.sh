# grep aliases
GREP_EXCLUDE="--exclude=tags --exclude-dir=.hg --exclude-dir=.git --exclude-dir=build --exclude-dir=.mypy_cache --exclude-dir=.pytest_cache"
alias gir="grep $GREP_EXCLUDE -iIr"
alias gic="grep $GREP_EXCLUDE -nIHr"
alias gif="grep $GREP_EXCLUDE -iInHr"
alias gih="grep --include=*.h -nir"
alias gin="grep $GREP_EXCLUDE -iHrl"
alias gff="find . -path '*/build/*' -prune -path '*.git*' -prune -o -print | grep -i"

function vgff() {
    local query="$1"
    for file in $(find . -path '*/build/*' -prune -path '*.git*' -prune -o -print | grep -i "$query"); do
        if [ -f "$file" ]; then
            vi "$file"
        fi
    done
}

function vgif() {
    v $(gif "$@" | grep -o '^[^:]*:[0-9]*:')
}

function vgifr() {
    count="$(gif "$@" | grep -o '^[^:]*:[0-9]*:' | wc -l)"
    for i in $(seq 1 "$count"); do
        ref="$(gif "$@" | grep -o '^[^:]*:[0-9]*:' | tail -n "+$i" | head -n 1)"
        v "$ref"
        sleep 0.3
    done
}

function vfgif() {
    v $(gif "$@" | grep -o '^[^:]*:[0-9]*:' | grep -o '^[^:]*' | sort -u)
}

function vgic() {
    v $(gic "$@" | grep -o '^[^:]*:[0-9]*:')
}

# Search for a rule/section
function rgif() {
    local query="${1//./\\.}"
    shift

    gif "\(^\|[^0-9\.]\)$query" "$@"
}

function gitc() {
    local query="$1"
    grep -ro "$query" | wc -l
}
