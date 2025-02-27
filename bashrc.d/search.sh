# grep aliases
GREP_EXCLUDE="--exclude=tags --exclude-dir=http/web_ui --exclude-dir=web_ui --exclude-dir=.docusaurus --exclude-dir=.hg --exclude-dir=.git --exclude-dir=build --exclude-dir=.mypy_cache --exclude-dir=.pytest_cache --exclude-dir=node_modules --exclude-dir=.yarn --exclude=*chunk*.js --exclude=*chunk*.js.map --exclude=.eslintcache --exclude=yarn.lock --exclude=openapi.json"
alias gir="grep $GREP_EXCLUDE -iIr"
alias gic="grep $GREP_EXCLUDE -nIHr"
alias gif="grep $GREP_EXCLUDE -iInHr"
alias gih="grep --include=*.h -nir"
alias gig="grep --include=*.go -nir"
alias gin="grep $GREP_EXCLUDE -iHrl"
alias gff="find . \( -path '*/build/*' -o -path '*/.git*' -o -path '*/.hg/*' -o -path '*/.mypy_cache/*' -o -path '*/.pytest_cache/*' -o -path '*/node_modules/*' -o -path '*/.yarn/*' \) -prune -o -print | grep -i"

function vgff() {
    local query="$1"
    for file in $(find . '(' -path '*/build/*' -o -path '*/.git*' -o -path '*/.hg/*' -o -path '*/.mypy_cache/*' -o -path '*/.pytest_cache/*' -o -path '*/node_modules/*' -o -path '*/.yarn/*' ')' -prune -o -print | grep -i "$query"); do
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

    gif "\(^\|[^0-9\.]\)$query\($\|[^0-9\.]\)" "$@"
}

function gitc() {
    local query="$1"
    grep -ro "$query" | wc -l
}
