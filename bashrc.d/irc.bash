function irc_find_url() {
    local log=""
    local user=""
    local server=""
    local dir="$HOME/.weechat/logs"

    local extra=()

    while (( $# > 0 )); do
        local arg="$1"
        shift

        if [ "x$arg" == "x--user" ]; then
            user="$1"
            shift
        elif [ "x$arg" == "x--log" ]; then
            log="$1"
            shift
        elif [ "x$arg" == "x--server" ]; then
            server="$1"
            shift
        else
            extra+=("$arg")
        fi
    done

    local files="$(find "$dir" -type f)"

    if [ "x$server" != "x" ]; then
        new_files="$(grep -i "^irc\.$server\." <<< "$files")"
        if [ "x$new_files" != "x" ]; then
            files="$new_files"
        fi
    fi
    if [ "x$log" != "x" ]; then
        new_files="$(grep -i "$log\.weechatlog$" <<< "$files")"
        if [ "x$new_files" != "x" ]; then
            files="$new_files"
        fi
    fi

    (
        for file in $files; do
            local contents="$(cat "$file" | grep -i '\(http[s]\|ftp[s]\)://[^ ]*' | sort -u)"
            if [ "x$user" != "x" ]; then
                contents="$(awk "{ if (\$3 == \"$user\") { print } }" <<< "$contents")"
            fi

            for term in "${extra[@]}"; do
                contents="$(grep -i "$term" <<< "$contents")"
            done

            echo "$contents"
        done
    ) | sort -u | grep --color=auto -i '\(http[s]\|ftp[s]\)://[^ ]*'
}
