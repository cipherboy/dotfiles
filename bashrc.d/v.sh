#!/bin/bash

# v is an interface over vim supporting a few useful features:
#
#   - Editing a file from a line number, supporting both grep and GitHub
#     line number notations.
#   - Detecting if trailing whitespace exists and not clobbering it if
#     it does.
#   - Detecting if a path is relative to the root of a git repo.
#   - Sequentially edits multiple files at once.
function v() {
    shopt -s extglob
    shopt -s globstar

    local reload=false
    local git_root="$(git rev-parse --show-toplevel 2>/dev/null)"

    function __v_compute_git_index() {
        local index_location="$git_root/.git/v-git-document-index"

        if [ "x$git_root" == "x" ]; then
            return 1
        fi

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
        find "$git_root" -type f |
            sed '/\(\/.git\/\|\.git[a-z]*$\)/d' |
            sed '/\/build\//d' |
            sed '/\/__pycache__\//d' |
            cat - > $index_location
    }

    function __v_find_file() {
        local raw_candidate="$1"
        local candidate="$(echo "$raw_candidate" | sed 's/\(:[0-9]\+[:]*\|#[Ll_]*[0-9]\+[-]*[0-9]*\)$//g')"

        if [ -e "$candidate" ]; then
            echo "$candidate"
            return 0
        fi
        if [ -e "../$candidate" ]; then
            echo "../$candidate"
            return 0
        fi
        if [ "x$git_root" != "x" ] &&  [ -e "$git_root/$candidate" ]; then
            echo "$git_root/$candidate"
            return 0
        fi

        # Fast options don't exist. Let's try a few other options before
        # giving up...
        if [ "x$git_root" != "x" ]; then
            # Compute and store an index of files in the git root. This allows
            # us to find a file in the git root, but not recompute this index
            # every time.

            __v_compute_git_index "$git_root"
            local index_location="$git_root/.git/v-git-document-index"
            local result="$(cat "$index_location" | grep -F "$candidate")"
            local result_count="$(echo "$result" | wc -l)"

            # Note that we have to validate that the file exists before we try
            # to edit it -- sometimes the index is out of date and a file has
            # been recently removed.
            if [ "x$result_count" == "x1" ] && [ -e "$result" ]; then
                echo "$result"
                return 0
            fi

            # Try again with regex matching...
            result="$(cat "$index_location" | grep "$candidate")"
            result_count="$(echo "$result" | wc -l)"
            if [ "x$result_count" == "x1" ] && [ -e "$result" ]; then
                echo "$result"
                return 0
            elif (( result_count > 1 )); then
                cat "$index_location" | grep "$candidate" >&2
                return 2
            fi
        fi

        local glob="$(ls */"$candidate" 2>/dev/null | wc -l)"
        if [ "x$glob" == "x1" ]; then
            ls */"$candidate"
            return 0
        fi

        local glob_fuzzy="$(ls */*"$candidate"* 2>/dev/null | wc -l)"
        if [ "x$glob" == "x1" ]; then
            ls */"$candidate"
            return 0
        fi

        return 1
    }

    function __v_line_num() {
        local candidate="$1"
        local c_colons="$(echo "$candidate" | grep -o ':[0-9]\+[:]*$' | sed 's/://g')"
        local c_pounds="$(echo "$candidate" | grep -o '#[Ll_]*[0-9]\+[-]*[0-9]*$' | grep -o '[0-9]*' | head -n 1)"

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
        sed 's/^\(autocmd BufWritePre\)/" \1/g' ~/.vimrc -i
    }

    function __no_preserve_whitespace() {
        sed 's/^" \(autocmd BufWritePre\)/\1/g' ~/.vimrc -i
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
            if [ $line_ret == 0 ]; then
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
    if [ $max_seq == 0 ]; then
        echo vim "${editor_args[@]}" 1>&2
        vim "${editor_args[@]}"
        return $?
    fi

    max_seq=$(( max_seq - 1 ))

    for i in $(seq 0 ${#editor_files[@]}); do
        local file="${editor_files[$i]}"
        local line="${editor_lines[$i]}"

        __do_update_vimrc "$file"

        echo vim "${editor_args[@]}" $line "$file" 1>&2
        vim "${editor_args[@]}" $line "$file"
        ret=$?
        if [ $ret != 0 ]; then
            return $ret
        fi

        if [ "x$((i + 1))" == "x${#editor_files[@]}" ]; then
            break
        fi

        sleep 0.5
    done
}
