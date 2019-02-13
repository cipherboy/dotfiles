#!/bin/bash

function gh_pr_commits() {
    local user="$1"
    local repo="$2"
    local pull="$3"

    local commits="$(curl -s https://api.github.com/repos/$user/$repo/pulls/$pull/commits 2>/dev/null | jq length)"
    echo "$user/$repo pr#$pull has $commits commits"

    local commit_sha="$(curl -s https://api.github.com/repos/$user/$repo/pulls/$pull | jq '.["merge_commit_sha"]' | sed 's/"//g')"
    for i in $(seq 1 $commits); do
        echo "$commit_sha"

        local commit_info="$(curl -s https://api.github.com/repos/$user/$repo/git/commits/$commit_sha)"
        local parent_count="$(echo "$commit_info" | jq '.["parents"]' | jq length)"
        if [ "x$parent_count" != "x1" ]; then
            echo "Can't process commit $commit_sha: merge commit with multiple parents."
            return 1
        fi
        commit_sha="$(echo "$commit_info" | jq '.["parents"][0]["sha"]' | sed 's/"//g')"
    done

    return 0
}

function gh_keys() {
    local user="$1"

    curl "https://api.github.com/users/$user/keys" 2>/dev/null | jq -r '.[].key' | sed "s/\$/ github-$user/g"
}
