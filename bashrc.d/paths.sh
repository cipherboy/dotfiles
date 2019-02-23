function ffind() {
    local names=()

    local filter=""
    local dir="."
    local base_dir=""
    local seen_base_dir="false"

    local min_depth="0"
    local max_depth="2"
    local find_type=""

    local basename=""
    local seen_basename="false"

    local use_stdin="false"
    local allow_hidden="false"

    while (( $# > 0 )); do
        local arg="$1"
        shift

        if [ "x$arg" == "x--location" ] || [ "x$arg" == "x-l" ]; then
            dir="$1"
            shift
        elif [ "x$arg" == "x--base-location" ] || [ "x$arg" == "x-b" ]; then
            base_dir="$1"
            shift

            seen_base_dir="true"
        elif [ "x$arg" == "x--max-depth" ] || [ "x$arg" == "x-ma" ]; then
            max_depth="$1"
            shift
        elif [ "x$arg" == "x--min-depth" ] || [ "x$arg" == "x-mi" ]; then
            min_depth="$1"
            shift
        elif [ "x$arg" == "x--depth" ]; then
            max_depth="$1"
            min_depth="$1"
            shift
        elif [ "x$arg" == "x--filter" ] || [ "x$arg" == "x-f" ]; then
            filter="$1"
            shift
        elif [ "x$arg" == "x--only-dirs" ] || [ "x$arg" == "x--dirs" ] ||
                [ "x$arg" == "x-d" ]; then
            find_type="-type d"
        elif [ "x$arg" == "x--only-files" ] || [ "x$arg" == "x--files" ] ||
                [ "x$arg" == "x-f" ]; then
            find_type="-type f"
        elif [ "x$arg" == "x--stdin" ]; then
            use_stdin="true"
        elif [ "x$arg" == "x--hidden" ]; then
            allow_hidden="true"
        elif [ "x$arg" == "x--basename" ]; then
            basename="$1"
            shift

            seen_basename="true"
        else
            names+=("$arg")
        fi
    done

    if [ "$seen_base_dir" == "false" ]; then
        if [ "x$dir" == "x." ]; then
            base_dir="$dir/"
        elif [ "x$dir" == "x./" ]; then
            base_dir="$dir"
        fi
    else
        if [ "x${base_dir:${#base_dir}-1:1}" != "x/" ]; then
            base_dir="$base_dir/"
        fi
    fi

    if [ "$use_stdin" == "false" ]; then
        mapfile -t results < <(find "$dir" -mindepth "$min_depth" -maxdepth "$max_depth" $find_type)
    else
        mapfile -t results < <(cat -)
    fi

    if (( ${#results[@]} == 0 )); then
        return 1
    fi

    if [ "x$base_dir" != "x" ]; then
        local new_results=()
        for result in "${results[@]}"; do
            line="${result#$base_dir}"
            if [ "x$line" != "x" ]; then
                if [ "$allow_hidden" == "true" ] || [[ "/$line" != *"/."* ]]; then
                    new_results+=("$line")
                fi
            fi
        done

        results=("${new_results[@]}")
        new_results=()
    fi

    if (( ${#names[@]} > 0 )); then
        local new_results=()
        for result in "${results[@]}"; do
            add_line="true"
            for name in "${names[@]}"; do
                if [[ "$result" != *"$name"* ]]; then
                    add_line="false"
                    break
                fi
            done

            if [ "$add_line" == "true" ] && [ "$seen_basename" == "true" ]; then
                if [[ "$result" != *"/$basename" ]]; then
                    add_line="false"
                fi
            fi

            if [ "$add_line" == "true" ]; then
                new_results+=("$result")
            fi
        done

        results=("${new_results[@]}")
    fi

    if (( ${#results[@]} == 0 )); then
        return 1
    elif (( ${#results[@]} == 1 )); then
        echo "${results[0]}"
        return 0
    fi

    for result in "${results[@]}"; do
        echo "$result"
    done
    return 2
}
