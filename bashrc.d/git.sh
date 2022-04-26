# git aliases
function gtdb() {
    local ref=""
    local ret=0

    for remote in "$(git remote)"; do
        ref="$(git symbolic-ref refs/remotes/"$remote"/HEAD 2>/dev/null)"
        ret=$?

        if (( ret == 0 )); then
            sed 's@^refs/remotes/'"$remote"'/@@' <<< "$ref"
            return $?
        fi
    done

    for branch in hashicorp-main canonical main default trunk master latest devel dev development; do
        ref="$(git branch --list "$branch" 2>/dev/null)"
        ret=$?

        if (( ret == 0 )); then
            if [ "x$ref" != "x" ]; then
                echo "$branch"
                return 0
            fi
        fi
    done

    return 1
}

alias gta='git add'
function gtac() {
    for file in "$@"; do
        if [ ! -e "$file" ]; then
            echo "Usage: gtac <file>"
            echo "Adds and commits a fixup to <file>"
            return 1
        fi

        git add "$file" && git commit --signoff -m "FIXUP $file"
    done
}
alias gtb='git branch  --sort=committerdate'
function gtbc() {
    local commit="$1"
    git branch --all --contains "$commit"  --sort=committerdate | sed 's#remotes/[^/]*/# #g' | awk '{print $NF}' | sort -u
}
alias gtbn='basename "$(gtcd)"'
alias gtc='git clone'
function gtcd() {
    # Changes to the root of the git repository
    local git_root="$(git rev-parse --show-toplevel 2>/dev/null)"
    pushd "$git_root" 1>/dev/null 2>&2
    echo "$git_root"
}
alias gtcp='git cherry-pick'
alias gtcpc='git cherry-pick --continue'
alias gtd='git diff'
alias gtdt='git difftool'
alias gtdc='git diff --cached'
alias gtdh='git diff HEAD~'
function gtdm() {
    git diff "$(gtdb)"
}
alias gtdf='git diff --name-only'
function gtdfm() {
    git diff --name-only "$(gtdb)"
}
alias gtdfh='git diff --name-only HEAD~'
alias gtfa='git fetch --all'
alias gtfp='git push --force'
alias gtl='git log'
alias gtm='git commit -s'
alias gtma='git commit -s --amend --reset-author'
alias gtme='git commit -s --allow-empty'
alias gto='git checkout'
alias gtob='git checkout -b'
function gtom() {
    git checkout "$(gtdb)"
}
function gtp() {
    git push "$@"
}
function gtpom() {
    gtp origin "$@"
}
function gtpum() {
    gtp "upstream" "$(gtdb)"
}
alias gtpsu='git push --set-upstream origin $(git rev-parse --abbrev-ref HEAD)'
alias gtpob='git push origin $(git rev-parse --abbrev-ref HEAD):cipherboy-$(git rev-parse --abbrev-ref HEAD)'
alias gtpub='git push upstream $(git rev-parse --abbrev-ref HEAD):cipherboy-$(git rev-parse --abbrev-ref HEAD)'
alias gtr='git rebase'
alias gtra='git rebase --abort ; gts'
alias gtrb='git rebase -i'
alias gtrc='git rebase --continue ; gts'
alias gtrs='git rebase --skip'
alias gtre='git reset'
alias gtrh='git reset HEAD'
alias gtrv='git remote -v'
alias gtrr='git remote remove'
function gtrm() {
    git rebase -i "$(gtdb)"
}
function gtrma() {
    git rebase "$(gtdb)"
}
alias gtrau='git remote add upstream'
alias gtrso='git remote set-url origin'
alias gtrsu='git remote set-url upstream'
alias gts='git status'
alias gtsl='git shortlog -s -n'
alias gtsmi='git submodule init'
alias gtsmu='git submodule update'
alias gtu='git pull'

function gtbs() {
    # Skips current commit in bisect
    local git_root="$(git rev-parse --show-toplevel 2>/dev/null)"
    pushd $git_root >/dev/null 2>/dev/null
        git bisect skip
    popd >/dev/null 2>/dev/null
}

function gtbg() {
    # Marks current commit as good in bisect
    local git_root="$(git rev-parse --show-toplevel 2>/dev/null)"
    pushd $git_root >/dev/null 2>/dev/null
        git bisect good
    popd >/dev/null 2>/dev/null
}

function gtbb() {
    # Marks current commit as bad in bisect
    local git_root="$(git rev-parse --show-toplevel 2>/dev/null)"
    pushd $git_root >/dev/null 2>/dev/null
        git bisect bad
    popd >/dev/null 2>/dev/null
}

function gtcpb() {
    # For given branch ($1), cherry-picks the remaining arguments to
    # that branch.
    local current="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
    local branch=$1
    shift
    git checkout "$branch"
    for arg in "$@"; do
        git cherry-pick "$arg"
    done
    git checkout "$current"
}

function gtuf() {
    # Force updating the branch
    local branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
    git fetch origin "$branch"
    git reset --hard "origin/$branch"
    git status
}

function gtff() {
    local abspath="$(gtcd)"
    local relpath="$(realpath --relative-to="$(pwd)" "$abspath")"

    find "$relpath" '(' \
        -path '*/build/*' -o \
        -path '*/.git*' -o \
        -path '*/.hg/*' -o \
        -path '*/.mypy_cache/*' \
        -o -path '*/.pytest_cache/*' \
        -o -path '*/node_modules/*' \
        -o -path '*/.yarn/*' \
    ')' -prune -o -print | grep -i "$@"
}

function gthr() {
    # Checks if repository has a remote named $1.
    local remote="$1"
    local result="$(git remote 2>/dev/null | grep -o "^$remote$")"

    if [ "x$result" == "x$remote" ]; then
        return 0
    fi

    return 1
}

function gtum() {
    # Updates the default branch
    gtub "$(gtdb)"
}

function gtub() {
    # Fully updates the remote branch $1, syncing with upstream if it exists

    local local_branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
    local remote_branch="$1"
    if [ "$remote_branch" == "x" ]; then
        remote_branch="$(gtdb)"
    fi

    git checkout "$remote_branch"
    local ret="$?"
    if (( ret != 0 )); then
        return $ret
    fi

    git fetch --all
    local ret="$?"
    if (( ret != 0 )); then
        return $ret
    fi

    git pull origin "$remote_branch"

    gthr "internal"
    ret="$?"
    if (( ret == 0 )); then
        git pull internal "$remote_branch"
        git reset --hard "internal/$remote_branch"
    else
        gthr "upstream"
        ret="$?"
        if (( ret == 0 )); then
            git pull upstream "$remote_branch"
            git reset --hard "upstream/$remote_branch"
        fi
    fi

    git push
    git checkout "$local_branch"
    git status
}

function ghcd() {
    # Change to a given repository if it exists.
    #
    # Usage:
    # ghcd hash_framework -> changes to "$HOME/GitHub/cipherboy/hash_framework"
    # ghcd c2 hash_framework -> changes to "$HOME/cipherboy/c2/hash_framework"

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

    local all_paths=""
    local base="$gitbase/$provider"
    local path="$(ffind --location "$base" --base-location "$base" --depth 2 --only-dirs --basename "$repository" "$username" "$repository")"
    all_paths="$all_paths
$path"
    if [ -d "$base/$path/.git" ]; then
        pushd "$base/$path"
        git status
        return 0
    fi

    path="$(ffind --location "$base" --base-location "$base" --depth 2 --only-dirs --basename "$repository" "$repository")"
    all_paths="$all_paths
$path"
    if [ -d "$base/$path/.git" ]; then
        pushd "$base/$path"
        git status
        return 0
    fi

    path="$(ffind --location "$base" --base-location "$base" --depth 2 --only-dirs "$username" "$repository")"
    all_paths="$all_paths
$path"
    if [ -d "$base/$path/.git" ]; then
        pushd "$base/$path"
        git status
        return 0
    fi

    path="$(ffind --location "$base" --base-location "$base" --depth 2 --only-dirs "$repository")"
    all_paths="$all_paths
$path"
    if [ -d "$base/$path/.git" ]; then
        pushd "$base/$path"
        git status
        return 0
    fi

    echo "$all_paths" | sort -u | sed '/^$/d'

    return 1
}

function ghr() {
    # Opens a branch for review

    local owner="$1"
    local project="$2"
    local branch="$3"

    mkdir -p "$HOME/GitHub/$owner"
    cd "$HOME/GitHub/$owner"
    if [ ! -d "$project" ]; then
        git clone "https://github.com/$owner/$project"
    fi

    cd "$project"
    local ret="$?"
    if (( ret != 0 )); then
        return $ret
    fi

    if [ "x$branch" == "x" ]; then
        branch="$(gtdb)"
    fi

    git checkout "$(gtdb)"
    git pull origin
    git checkout "$branch"
    ret="$?"
    if (( ret != 0 )); then
        return $ret
    fi

    # Do a force update of this branch
    gtuf
    ret="$?"
    if (( ret != 0 )); then
        return $ret
    fi

    build all
}

function ghpr() {
    local number="$1"
    local branch="$2"

    if [ -z "$branch" ]; then
        branch="pr-$number"
    fi

    git rev-parse "$branch" >/dev/null 2>/dev/null
    exists=$?
    if (( exists == 0 )); then
        echo "Updating branch $name..."
        git checkout "$branch"
    fi

    for remote in $(git remote); do
        git fetch "$remote" "pull/$number/head" >/dev/null 2>/dev/null
        ret=$?

        if (( ret != 0 )); then
            continue
        fi

        if (( exists == 0 )); then
            git reset --hard FETCH_HEAD
        else
            git checkout -b "$branch" FETCH_HEAD
        fi

        return
    done

    echo "No remotes matching this pull request exist: $number" 1>&2
}

function ghl() {
    # Create a link to a given file in a smart fashion
    local path="$1"
    local line="$2"
    local branch="$(gtdb)"
    local url=""

    # Check if file exists in default branch
    git cat-file -e "$(gtdb):$path" >/dev/null 2>/dev/null
    local catret="$?"
    if (( $catret != 0 )); then
        branch="$(git rev-parse --abbrev-ref HEAD)"
    fi

    if [ "x$branch" == "x$(gtdb)" ]; then
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

function gtpoffline() {
    # Do an offline push of this repository

    local git_root="$(git rev-parse --show-toplevel 2>/dev/null)"
    echo "$git_root" >> ~/.git_offline_push
    sort -u ~/.git_offline_push > ~/.git_offline_push.tmp
    mv ~/.git_offline_push.tmp ~/.git_offline_push
}

function gtponline() {
    # Push all repositories that were pushed when offline.

    cp ~/.git_offline_push ~/.git_offline_push.original
    local line="$(head -n 1 ~/.git_offline_push)"
    while [ "x$line" != "x" ]; do
        pushd "$line"
        git push
        popd
        tail -n -1 ~/.git_offline_push > ~/.git_offline_push.tmp
        mv ~/.git_offline_push.tmp ~/.git_offline_push
        line="$(head -n 1 ~/.git_offline_push)"
    done
    rm ~/.git_offline_push
}

function gtse() {
    # Set email for the repository to personal or work.

    local email="$1"
    if [ "x$email" == "xwork" ] || [ "x$email" == "xw" ]; then
        email="$(cat ~/.git_email_work)"
    elif [ "x$email" == "xpersonal" ] || [ "x$email" == "xp" ]; then
        email="$(cat ~/.git_email_personal)"
    fi
    git config user.email "$email"
}

function gtseg() {
    # Set email globally to personal or work.

    local email="$1"
    if [ "x$email" == "xwork" ] || [ "x$email" == "xw" ]; then
        email="$(cat ~/.git_email_work)"
    elif [ "x$email" == "personal" ] || [ "x$email" == "xp" ]; then
        email="$(cat ~/.git_email_personal)"
    fi
    git config --global user.email "$email"
}

function gtrsp() {
    # Rebase, resetting author and signoff

    local current="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
    git rebase -i "origin/$current"
    ret=$?
    while (( ret == 0 )); do
        git commit --amend --reset-author --signoff
        git rebase --continue
        ret=$?
    done
}

function gtbac() {
    # Rebase, building and testing commits using `build all`

    local base="$1"
    if [ "x$base" == "x" ]; then
        base="--fork-point"
    fi

    git rebase "$base" --exec "bash -c 'source ~/.bashrc ; build all'"
    return $?
}

function gtrbf() {
    local branch="$(git rev-parse --abbrev-ref HEAD)"
    (gtom && gtum && gto "$branch" && gtrm && gtom && gtrb "$branch") && (gtpom ; gtpum) ; gto "$branch"
}

function gtrbfa() {
    local branch="$(git rev-parse --abbrev-ref HEAD)"
    (gtom && gtum && gto "$branch" && gtrma && gtom && gtr "$branch") && (gtpom ; gtpum) ; gto "$branch"
}

function __gtp-hashicorp() {
    # Hashicorp prefers employees push directly to the core repository rather
    # than open pull requests across forks. This helper enables the fork
    # workflow, while transparently cluttering the main repository to mirror
    # internal preferences.
    local prefix="ascheel"
    local separator="-"
    local branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"

    for remote in $(git remote); do
        if [[ "$(git remote get-url "$remote")" != *"github.com/hashicorp/"* ]]; then
            continue
        fi

        git push --force "$remote" "$branch:$prefix$separator$branch" >/dev/null 2>/dev/null
    done
}

## Source git completion
if [ -f /usr/share/bash-completion/completions/git ]; then
   source /usr/share/bash-completion/completions/git
    __git_complete gta _git_add
    __git_complete gtb _git_branch
    __git_complete gtc _git_clone
    __git_complete gtcp _git_cherry_pick
    __git_complete gtd _git_diff
    __git_complete gtdh _git_diff
    __git_complete gtdf _git_diff
    __git_complete gtdfh _git_diff
    __git_complete gtl _git_log
    __git_complete gtm _git_commit
    __git_complete gtma _git_commit
    __git_complete gtme _git_commit
    __git_complete gto _git_checkout
    __git_complete gtob _git_checkout
    __git_complete gtp _git_push
    __git_complete gtpom _git_push
    __git_complete gtpum _git_push
    __git_complete gtpsu _git_push
    __git_complete gtpob _git_push
    __git_complete gtpub _git_push
    __git_complete gtr _git_rebase
    __git_complete gtrb _git_rebase
    __git_complete gtre _git_reset
    __git_complete gtsl _git_shortlog
    __git_complete gtu _git_pull
    __git_complete gtub _git_checkout
fi

### ALWAYS RUN FUNCTIONS ##
