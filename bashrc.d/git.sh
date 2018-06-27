# git aliases
alias gta='git add'
alias gtb='git branch'
alias gtc='git clone'
function gtcd() {
    local git_root="$(git rev-parse --show-toplevel 2>/dev/null)"
    cd "$git_root"
}
alias gtcp='git cherry-pick'
alias gtcpc='git cherry-pick --continue'
alias gtd='git diff'
alias gtdt='git difftool'
alias gtdc='git diff --cached'
alias gtdh='git diff HEAD~'
alias gtdf='git diff --name-only'
alias gtdfh='git diff --name-only HEAD~'
alias gtfp='git push --force'
alias gtl='git log'
alias gtm='git commit -s'
alias gtma='git commit -s --amend'
alias gto='git checkout'
alias gtob='git checkout -b'
alias gtp='git push'
alias gtpsu='git push --set-upstream origin $(git rev-parse --abbrev-ref HEAD)'
alias gtr='git rebase'
alias gtrb='git rebase -i'
alias gtrc='git rebase --continue'
alias gtre='git reset'
alias gtrh='git reset HEAD'
alias gtrm='git rebase -i master'
alias gts='git status'
alias gtsl='git shortlog -s -n'
alias gtu='git pull'

function gtum() {
    local branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
    git checkout master && git pull origin master && git pull upstream master && git push
    git checkout "$branch"
}

function gtub() {
    local current="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
    local branch=$1
    git checkout "$branch" && git pull origin $branch && git pull upstream "$branch" && git push
    git checkout "$current"
}

function ghcd() {
    local gitbase="$HOME"
    local provider="GitHub"
    local username="cipherboy"
    local repository="dotfiles"

    if (( $# == 1 )); then
        repository="$1"
    elif (( $# == 2 )); then
        username="$1"
        repository="$2"
    elif (( $# == 3 )); then
        provider="$1"
        username="$2"
        repository="$3"
    elif (( $# == 4 )); then
        gitbase="$1"
        provider="$2"
        username="$3"
        repository="$4"
    fi

    local path="$gitbase/$provider/$username/$repository"
    if [ -d "$path" ]; then
        cd "$path"
    else
        path=""
        for d in "$gitbase"/"$provider"/*/"$repository"; do
            if [ -d "$d/.git" ]; then
                path="$d"
                break
            fi
        done

        if [ "x$path" != "x" ] && [ -d "$path" ]; then
            cd "$path"
        fi
    fi
}

function ghr() {
    local owner="$1"
    local project="$2"
    local branch="$3"

    mkdir -p "$HOME/GitHub/$owner"
    cd "$HOME/GitHub/$owner"
    if [ ! -d "$project" ]; then
        git clone "https://github.com/$owner/$project"
    fi

    if [ "x$branch" == "x" ]; then
        branch="master"
    fi

    cd "$project"
    git checkout master
    git pull origin
    git checkout "$branch"
    build
}

function ghl() {
    local path="$1"
    local line="$2"
    local branch="master"
    local url=""

    # Check if file exists in master
    git cat-file -e "master:$path" >/dev/null 2>/dev/null
    local catret="$?"
    if (( $catret != 0 )); then
        branch="$(git rev-parse --abbrev-ref HEAD)"
    fi

    if [ "x$branch" == "xmaster" ]; then
        url="$(git config --get remote.upstream.url)"
        if [ "x$url" == "x" ]; then
            url="$(git config --get remote.origin.url)"
        fi
    else
        url="$(git config --get remote.origin.url)"
    fi

    local urlpath="$url/blob/$branch/$path"
    if [ "x$line" != "x" ]; then
        urlpath="$urlpath#L$line"
    fi
    echo "$urlpath"
}
