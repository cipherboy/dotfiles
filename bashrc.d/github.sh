#!/bin/bash

function gh_pr_commits() {
    local user="$1"
    local repo="$2"
    local pull="$3"

    if [ -z "$user" ] || [ -z "$repo" ] || [ -z "$pull" ]; then
        echo "Usage: gh_pr_commits user repo pull"
        return 1
    fi

    local commits="$(curl -s "https://api.github.com/repos/$user/$repo/pulls/$pull/commits" 2>/dev/null | jq length)"
    echo "$user/$repo pr#$pull has $commits commits"

    local commit_sha="$(curl -s "https://api.github.com/repos/$user/$repo/pulls/$pull" | jq '.["merge_commit_sha"]' | sed 's/"//g')"
    for i in $(seq 1 "$commits"); do
        echo "$i: $commit_sha"

        local commit_info="$(curl -s "https://api.github.com/repos/$user/$repo/git/commits/$commit_sha")"
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

    if [ -z "$user" ]; then
        echo "Usage: gh_keys user"
        return 1
    fi

    curl "https://api.github.com/users/$user/keys" 2>/dev/null | jq -r '.[].key' | sed "s/\$/ github-$user/g"
}

function gh_vault_artifact() {
    local pr="$1"
    local repo="${2:-$(basename "$(gtrv | head -n 1 | awk '{print $2}')")}"
    local artifact_selector="${3:-linux_amd64.zip}"

    if [ -z "$repo" ]; then
        echo "unable to detect repo; provide it in \$2"
    fi
    tcd

    (
        set -euxo pipefail

        mkdir .apis/
        local repo_url="https://api.github.com/repos/hashicorp/$repo/pulls/$pr"
        curl -sSL "$repo_url" > .apis/repo
        local commits_url="$(jq -r '.commits_url' .apis/repo)"
        curl -sSL "$commits_url" > .apis/commits
        local last_commit="$(jq -r '.[-1].sha' .apis/commits)"
        local check_runs_url="https://api.github.com/repos/hashicorp/$repo/commits/$last_commit/check-runs"
        curl -sSL "$check_runs_url" > .apis/check_runs
        local check_run_id="$(jq -r '.check_runs[] | select(.name | endswith("linux amd64 build")).id' .apis/check_runs)"
        local check_run_url="https://github.com/hashicorp/$repo/runs/$check_run_id?check_suite_focus=true"
        curl -sSL "$check_run_url" > .apis/check-run.html
        local action_id="$(grep -io '/actions/runs/[0-9]*' .apis/check-run.html | sort -u | head -n 1 | grep -o '[0-9]*')"
        local artifacts_url="https://api.github.com/repos/hashicorp/$repo/actions/runs/$action_id/artifacts"
        curl -u "${GITHUB_USERNAME:-cipherboy}" -sSL "$artifacts_url" > .apis/artifacts
        local artifact_url="$(jq -r '.artifacts[] | select(.name | endswith("'"$artifact_selector"'")).archive_download_url' .apis/artifacts)"
        mkdir .artifacts/
        curl -u "${GITHUB_USERNAME:-cipherboy}" -sSL "$artifact_url" > .artifacts/archive.zip
        unzip .artifacts/archive.zip
    )

    if [ -e *.zip ]; then
        unzip *.zip
    fi
}
