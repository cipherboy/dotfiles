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

    function __v_find_file() {
        local raw_candidate="$1"
        local candidate="$(echo "$raw_candidate" | sed 's/\(:[0-9]\+[:]*\|#[Ll_]*[0-9]\+[-]*[0-9]*\)$//g')"
        local git_root="$(git rev-parse --show-toplevel 2>/dev/null)"

        local glob="$(ls */"$candidate" 2>/dev/null | wc -l)"
        local glob_star="$(ls **/"$candidate" 2>/dev/null | wc -l)"
        local glob_fuzzy="$(ls */*"$candidate"* 2>/dev/null | wc -l)"
        local glob_star_fuzzy="$(ls **/*"$candidate"* 2>/dev/null | wc -l)"

        local git_glob="$(ls "$git_root"/*/"$candidate" 2>/dev/null | wc -l)"
        local git_glob_star="$(ls "$git_root"/**/"$candidate" 2>/dev/null | wc -l)"
        local git_glob_fuzzy="$(ls "$git_root"/*/*"$candidate"* 2>/dev/null | wc -l)"
        local git_glob_star_fuzzy="$(ls "$git_root"/**/*"$candidate"* 2>/dev/null | wc -l)"

        if [ -e "$candidate" ]; then
            echo "$candidate"
            return 0
        elif [ -e "../$candidate" ]; then
            echo "../$candidate"
            return 0
        elif [ -e "$git_root/$candidate" ]; then
            echo "$git_root/$candidate"
            return 0
        elif [ $glob == 1 ]; then
            echo */"$candidate"
            return 0
        elif [ $glob_star == 1 ]; then
            echo **/"$candidate"
            return
        elif [ $glob_fuzzy == 1 ]; then
            echo */*"$candidate"*
            return 0
        elif [ $glob_star_fuzzy == 1 ]; then
            echo **/*"$candidate"*
            return 0
        elif [ $git_glob == 1 ]; then
            echo "$git_root"/*/"$candidate"
            return 0
        elif [ $git_glob_star == 1 ]; then
            echo "$git_root"/**/"$candidate"
            return
        elif [ $git_glob_fuzzy == 1 ]; then
            echo "$git_root"/*/*"$candidate"*
            return 0
        elif [ $git_glob_star_fuzzy == 1 ]; then
            echo "$git_root"/**/*"$candidate"*
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

        if [ $path_ret == 0 ]; then
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
        vim "${editor_args[@]}"
        return $?
    fi

    max_seq=$(( max_seq - 1 ))

    for i in $(seq 0 ${#editor_files[@]}); do
        local file="${editor_files[$i]}"
        local line="${editor_lines[$i]}"

        __do_update_vimrc "$file"

        echo vim "${editor_args[@]}" $line "$file"
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
