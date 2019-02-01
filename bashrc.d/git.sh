# git aliases
alias gta='git add'
alias gtb='git branch'
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
alias gtdf='git diff --name-only'
alias gtdfh='git diff --name-only HEAD~'
alias gtfp='git push --force'
alias gtl='git log'
alias gtm='git commit -s'
alias gtma='git commit -s --amend'
alias gto='git checkout'
alias gtob='git checkout -b'
alias gtom='git checkout master'
alias gtp='git push'
alias gtpom='git push origin master'
alias gtpum='git push upstream master'
alias gtpsu='git push --set-upstream origin $(git rev-parse --abbrev-ref HEAD)'
alias gtr='git rebase'
alias gtrb='git rebase -i'
alias gtrc='git rebase --continue'
alias gtre='git reset'
alias gtrh='git reset HEAD'
alias gtrv='git remote -v'
alias gtrr='git remote remove'
alias gtrm='git rebase -i master'
alias gtrau='git remote add upstream'
alias gtrso='git remote set-url origin'
alias gtrsu='git remote set-url upstream'
alias gts='git status'
alias gtsl='git shortlog -s -n'
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
    # Updates the master branch
    gtub master
}

function gtub() {
    # Fully updates the remote branch $1, syncing with upstream if it exists

    local local_branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
    local remote_branch="$1"
    if [ "$remote_branch" == "x" ]; then
        remote_branch="master"
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

    gthr "upstream"
    ret="$?"
    if (( ret == 0 )); then
        git pull upstream "$remote_branch"
        git reset --hard "upstream/$remote_branch"
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

    local path="$gitbase/$provider/$username/$repository"
    if [ -d "$path/.git" ]; then
        pushd "$path"
    else
        path=""
        for d in "$gitbase"/"$provider"/*/"$repository"; do
            if [ -d "$d/.git" ]; then
                path="$d"
                break
            fi
        done

        if [ "x$path" == "x" ] || [ ! -d "$path" ]; then
            return 1
        fi

        pushd "$path"
    fi

    ghs
    ghh
    git status
}

function ghh() {
    # Source the local git repository
    return

    local git_root="$(git rev-parse --show-toplevel 2>/dev/null)"
    if [ "x$git_root" == "x" ]; then
        ghs
        return
    fi

    local new_histfile="$git_root/.git/bash_history"
    local old_histfile="$HISTFILE"

    if [ "x$new_histfile" == "x$old_histfile" ]; then
        return
    fi

    # Since we're changing histories, save and merge the old history
    ghs

    history -a
    export HISTFILE="$new_histfile"

    # If history file doesnt exist, seed it first with the global history.
    if [ ! -e "$new_histfile" ]; then
        cp "$HOME/.bash_history" "$new_histfile"
        echo "## GLOBAL_BASH_HISTORY_MARKER ##" >> "$new_histfile"
    fi

    history -c
    history -r
}

function ghs() {
    # Stop using local history and switch back to global history, appending
    # local history to the global history.
    return

    local old_histfile="$HISTFILE"
    local home_histfile="$HOME/.bash_history"

    if [ "x$old_histfile" == "x$home_histfile" ]; then
        return
    fi

    history -a
    export HISTFILE="$home_histfile"
    history -c

    grep -o GLOBAL_BASH_HISTORY_MARKER < "$old_histfile" >/dev/null 2>/dev/null
    local ret=$?
    if (( ret == 0 )); then
        sed -e '1,/GLOBAL_BASH_HISTORY_MARKER/d' "$old_histfile" > "$old_histfile.tmp"
        cat "$home_histfile" "$old_histfile.tmp" | uniq > "$home_histfile.tmp"
        rm -f "$old_histfile.tmp"
    else
        cat "$home_histfile" "$old_histfile" | uniq > "$home_histfile.tmp"
    fi

    mv "$home_histfile.tmp" "$home_histfile"

    history -r
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

    if [ "x$branch" == "x" ]; then
        branch="master"
    fi

    cd "$project"
    local ret="$?"
    if (( ret != 0 )); then
        return $ret
    fi

    git checkout master
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

function ghl() {
    # Create a link to a given file in a smart fashion
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
    elif [ "x$email" == "personal" ] || [ "x$email" == "xp" ]; then
        email="$(cat ~/.git_email_personal)"
    fi
    git config user.email "$email"
}

function gtseg() {
    # Set email globally to personal or work.

    local email="$1"
    if [ "x$email" == "xwork" ]; then
        email="$(cat ~/.git_email_work)"
    elif [ "x$email" == "personal" ]; then
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


### ALWAYS RUN FUNCTIONS ##

# Always source pre-repo bash history if we're in a git directory
#export PROMPT_COMMAND="ghh;$PROMPT_COMMAND"
