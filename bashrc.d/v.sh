#!/bin/bash

# v is an interface over vim supporting a few useful features:
#
#   - Editing a file from a line number, supporting both grep and GitHub
#     line number notations.
#   - Detecting if trailing whitespace exists and not clobbering it if
#     it does.
#   - Detecting if a path is relative to the root of a git repo.
#   - Sequentially edits multiple files at once.
function v() {(
    shopt -s extglob
    shopt -s globstar
    shopt -s checkwinsize

    local vconfig="$HOME/.vimrc"
    local svconfig="$HOME/.SpaceVim.d/init.toml"
    local reload=false
    local git_root="$(git rev-parse --show-toplevel 2>/dev/null)"
    local hg_root="$(hg root 2>/dev/null)"
    local root="$git_root"
    if [ -z "$root" ]; then
        root="$hg_root"
    fi

    function find_filter() {
        sed '/\(\/.git\/\|\.git[a-z]*$\)/d' |
        sed '/\(\/.hg\/\|\.hg[a-z]*$\)/d' |
        sed '/\/build\//d' |
        sed '/\/out\//d' |
        sed '/\/dist\//d' |
        sed '/\/\.pytest_cache\//d' |
        sed '/\/\.mypy_cache\//d' |
        sed '/\/__pycache__\//d' |
        sed '/\.pyc$/d' |
        sed '/\/target\//d' |
        sed '/\/node_modules\//d' |
        sed '/\/\.jar$/d' |
        sed '/\/\.class$/d'
    }

    function __v_compute_index() {
        local index_location=""

        if [ -n "$git_root" ]; then
            index_location="$root/.git/v-git-document-index"
        elif [ -n "$hg_root" ]; then
            index_location="$root/.hg/v-hg-document-index"
        else
            return 1
        fi

        echo "$index_location"

        if [ -e "$index_location" ]; then
            local modified="$(stat --format=%Y "$index_location")"
            local current_time="$(date +%s)"
            local difference=$(( current_time - modified ))

            # If the file is older than 5 minutes out of date, regenerate it
            if [ "$reload" == "false" ] && (( difference <= 300 )); then
                return 0
            fi
        fi

        echo "Generating file index at $index_location" 1>&2

        # Ignore the contents of .git and build directories.
        find "$root" -type f 2>/dev/null |
            find_filter > "$index_location"
    }

    function __v_find_file() {
        local raw_candidate="$1"
        local candidate="$(sed 's/\(:[0-9]\+[:]*\|#[Ll_]*[0-9]\+[-]*[0-9]*\)$//g' <<< "$raw_candidate")"

        if [ "x$raw_candidate" == "x-R" ]; then
            return 1
        fi

        if [ -e "$candidate" ] && [ ! -d "$candidate" ]; then
            echo "$candidate"
            return 0
        fi

        if [ -e "../$candidate" ] && [ ! -d "../$candidate" ]; then
            echo "../$candidate"
            return 0
        fi

        if [ "x$root" != "x" ] &&  [ -e "$root/$candidate" ] && [ ! -d "$root/$candidate" ]; then
            echo "$root/$candidate"
            return 0
        fi

        local find="$(find . -maxdepth 2 -type f 2>/dev/null | find_filter | grep -i -- "$candidate")"
        local find_count="$(wc -l <<< "$find")"
        if (( find_count == 1 )) && [ -e "$find" ]; then
            echo "$find"
            return 0
        elif (( find_count > 1 )); then
            find . -maxdepth 2 -type f 2>/dev/null | find_filter | grep -i -- "$candidate" 1>&2
            return 2
        fi

        # Fast options don't exist. Let's try a few other options before
        # giving up...
        if [ "x$root" != "x" ]; then
            # Compute and store an index of files in the git root. This allows
            # us to find a file in the git root, but not recompute this index
            # every time.

            local index_location="$(__v_compute_index)"
            local index="$(grep -F -- "$candidate" < "$index_location")"
            local index_count="$(wc -l <<< "$index")"

            # Note that we have to validate that the file exists before we try
            # to edit it -- sometimes the index is out of date and a file has
            # been recently removed.
            if (( index_count == 1 )) && [ -e "$index" ]; then
                echo "$index"
                return 0
            fi

            # Try again with regex matching...
            index="$(grep -- "$candidate" < "$index_location")"
            index_count="$(echo "$index" | wc -l)"
            if [ "x$index_count" == "x1" ] && [ -e "$index" ]; then
                echo "$index"
                return 0
            elif (( index_count > 1 )); then
                grep -- "$candidate" < "$index_location" >&2
                return 2
            fi
        fi

        local glob="$(ls ./*/"$candidate" 2>/dev/null | wc -l)"
        if [ "x$glob" == "x1" ]; then
            ls ./*/"$candidate"
            return 0
        fi

        local glob_fuzzy="$(ls ./*/*"$candidate"* 2>/dev/null | wc -l)"
        if [ "x$glob" == "x1" ]; then
            ls ./*/"$candidate"
            return 0
        fi

        return 1
    }

    function __v_line_num() {
        local candidate="$1"
        local c_colons="$(grep -o ':[0-9]\+[:]*$' <<< "$candidate" | sed 's/://g')"
        local c_pounds="$(grep -o '#[Ll_]*[0-9]\+[-]*[0-9]*$' <<< "$candidate" | grep -o '[0-9]*' | head -n 1)"

        if [ "x$c_colons" != "x" ]; then
            echo "$c_colons"
            return 0
        elif [ "x$c_pounds" != "x" ]; then
            echo "$c_pounds"
            return 0
        fi

        return 1
    }

    function __preserve_whitespace() {
        if [ -e "$vconfig" ]; then
            sed 's/^\(autocmd BufWritePre\)/" \1/g' "$vconfig" -i
        fi
    }

    function __no_preserve_whitespace() {
        if [ -e "$vconfig" ]; then
            sed 's/^" \(autocmd BufWritePre\)/\1/g' "$vconfig" -i
        fi
    }

    function __use_tabs() {
        if [ -e "$vconfig" ]; then
            sed 's/^set expandtab/set noexpandtab/g' "$vconfig" -i
            sed 's/^\(set softtabstop\)/" \1/g' "$vconfig" -i
        fi

        if [ -e "$svconfig" ]; then
            sed 's/expand_tab.*/expand_tab = false/g' "$svconfig" -i
        fi
    }

    function __use_spaces() {
        if [ -e "$vconfig" ]; then
            sed 's/^set noexpandtab/set expandtab/g' "$vconfig" -i
            sed 's/^" \(set softtabstop\)/\1/g' "$vconfig" -i
        fi

        if [ -e "$svconfig" ]; then
            sed 's/expand_tab.*/expand_tab = true/g' "$svconfig" -i
        fi
    }

    function __set_width() {
        local width="$1"

        if [ -e "$vconfig" ]; then
            sed "s/shiftwidth=[0-9]/shiftwidth=$width/g" "$vconfig" -i
            sed "s/softtabstop=[0-9]/softtabstop=$width/g" "$vconfig" -i
        fi

        if [ -e "$svconfig" ]; then
            sed "s/default_indent.*/default_indent = $width/g" "$svconfig" -i
        fi
    }

    function __count_spaces() {
        local k="$1"
        # This python one-liner takes input in the form occurrences -> length
        # (from the awk output in __detect_spaces) and returns True iff the
        # selected k value is the most common divisor of the line length.
        # This is better than the earlier function which didn't weight by line
        # length occurrence.
        python3 -c "import collections, sys ; k=$k ; result = collections.defaultdict(lambda: 0)
for z in map(lambda y: ( y[1] % k, y[0] ), (map(lambda x: tuple(map(int, x.strip().split(' '))), sys.stdin.readlines()))):
    result[z[0]] += z[1]
print(result[0] == max(result.values()))"
    }

    function __detect_spaces() {
        local file="$1"

        local spaces="$(grep -o '^[ ]*' "$file" | awk '{ print length($0) }' | sort | uniq -c)"
        local two="$(__count_spaces 2 <<< "$spaces")"
        local four="$(__count_spaces 4 <<< "$spaces")"
        local eight="$(__count_spaces 8 <<< "$spaces")"

        if [ "$eight" == "True" ]; then
            __set_width 8
        elif [ "$four" == "True" ]; then
            __set_width 4
        elif [ "$two" == "True" ]; then
            __set_width 2
        else
            __set_width 4
        fi
    }

    function __do_update_vimrc() {
        local file="$1"

        grep -q '[[:space:]]$' "$file"
        local ret=$?

        if [ $ret == 0 ]; then
            __preserve_whitespace
        else
            __no_preserve_whitespace
        fi

        local count_spaces="$(grep -c '^ ' "$file" 2>/dev/null)"
        local count_tabs="$(grep -c '^	' "$file" 2>/dev/null)"
        if (( count_spaces > count_tabs )); then
            __use_spaces
            __detect_spaces "$file"
        elif (( count_tabs > count_spaces )); then
            __use_tabs
        fi
    }

    local editor_args=()
    local editor_files=()
    local editor_lines=()

    for arg in "$@"; do
        path="$(__v_find_file "$arg")"
        path_ret=$?
        line="$(__v_line_num "$arg")"
        line_ret=$?

        if (( path_ret == 2 )); then
            return 0
        fi

        if [ "x$arg" == "x--reload" ] ; then
            reload="true"
        elif [ $path_ret == 0 ]; then
            editor_files+=("$path")
            if (( line_ret == 0 )); then
                editor_lines+=("+$line")
            else
                editor_lines+=("")
            fi
        else
            editor_args+=("$arg")
        fi
    done

    local max_seq=${#editor_files[@]}

    # If we have no known files, edit the arguments anyways
    if (( max_seq == 0 )); then
        echo vim "${editor_args[@]}" 1>&2
        exec vim "${editor_args[@]}"
        return $?
    fi

    max_seq=$(( max_seq - 1 ))

    for i in $(seq 0 ${#editor_files[@]}); do
        local file="${editor_files[$i]}"
        local line="${editor_lines[$i]}"
        local gofmt_clean="true"

        __do_update_vimrc "$file"

        if [[ "$file" == *".go" ]] && command -v gofmt >/dev/null; then
            local gofmt="$(gofmt -l -d "$file" 2>&1 | wc -l)"
            if (( gofmt > 0 )); then
                gofmt_clean="false"
            fi
        fi

        (
            echo vim "${editor_args[@]}" $line "$file" 1>&2
            exec vim "${editor_args[@]}" $line "$file"
        )
        ret=$?
        if [ $ret != 0 ]; then
            return $ret
        fi

        if [[ "$file" == *".go" ]] && command -v gofmt >/dev/null && [ "$gofmt_clean" == "true" ]; then
            echo gofmt -l -w "$file" 1>&2
            gofmt -l -w "$file"
        fi

        if [ "x$((i + 1))" == "x${#editor_files[@]}" ]; then
            break
        fi

        sleep 0.5
    done
)}
