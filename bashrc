#!/bin/bash

for i in /etc/profile.d/*.sh; do
	source $i
done

if [ "$TILIX_ID" ] || [ "$VTE_VERSION" ]; then
        source /etc/profile.d/vte.sh
fi

# Keep all history
HISTSIZE=-1
HISTFILESIZE=-1

# Force pretty colors
eval "$(dircolors)"
alias ls="ls --color=auto --group-directories-first"
alias grep="grep --color=auto"

export GOPATH="$HOME/Development/go/"

## Common aliases
# emacs alias to fix x-keypass
alias emacs='GPG_AGENT_INFO="" emacs --display "" --no-window-system '

# youtube audio download
alias yaudio='youtube-dl -x --audio-quality 0 --audio-format best -f bestaudio'
alias yvideo='youtube-dl -x --audio-quality 0 --audio-format best -f best -k'

# Convert to mp3
alias ape2mp3='for a in *.ape; do ffmpeg -i "$a" -qscale:a 320k -b 320k "${a[@]/%ape/mp3}" && rm "$a"; done'
alias flac2mp3='parallel avconv -i {} -qscale:a 320k -b 320k {.}.mp3 ::: *.flac'
alias m4a2mp3='parallel avconv -i {} -qscale:a 320k -b 320k {.}.mp3 ::: *.m4a'
alias wav2mp3='parallel avconv -i {} -qscale:a 320k -b 320k {.}.mp3 ::: *.wav'

# Generate a new password
alias genpass="tr -cd '[:alnum:]' < /dev/urandom | fold -w30 | head -n1"

## PS1
PS1='[\u@\h \W]\$ '

export PATH="/usr/lib64/ccache:$GOPATH/bin:$HOME/.rbenv/bin:/usr/local/go/bin:/opt/bin:/opt/node/bin:/usr/games/bin:$HOME/bin:/usr/local/racket/bin:$PATH"

alias allpdflatex="echo *.tex | entr -r pdflatex -halt-on-error ./*.tex"

# git aliases
alias gta='git add'
alias gtb='git branch'
alias gtc='git clone'
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
alias gtum='git checkout master && git pull upstream master && git push'
function gtub() {
    local branch=$1
    git checkout "$branch" && git pull upstream "$branch" && git push
}
function ghr() {
    local project="$1"
    local owner="$2"
    local branch="$3"
    mkdir -p "$HOME/GitHub/$owner"
    cd "$HOME/GitHub/$owner"
    if [ ! -d "$project" ]; then
        git clone "https://github.com/$owner/$project"
    fi

    cd "$project"
    git checkout master
    git pull origin
    git checkout "$branch"
    build
}
function ghlink() {
    local path="$1"
    local line="$2"

    local url="$(git config --get remote.upstream.url)"
    if [ "x$url" == "x" ]; then
        url="$(git config --get remote.origin.url)"
    fi

    local branch="$(git rev-parse --abbrev-ref HEAD)"

    echo "$url/blob/$branch/$path#L$line"
}


# grep aliases
alias gir='grep --exclude=tags --exclude-dir=.git -iIr'
alias gic='grep --exclude=tags --exclude-dir=.git -nIHr'
alias gif='grep --exclude=tags --exclude-dir=.git -iInHr'
function gitc() {
    local query=$1
    grep -ro "$query" | wc -l
}

# project aliases
alias actags='ctags -R  --c-kinds=+cdefglmnpstuvx --langmap=c:+.cin.hin'
alias fbuild='rm build -rf ; mkdir build ; cd build ; touch .gitkeep ; cmake .. && time make -j5'
alias fcbuild='rm build -rf ; mkdir build ; cd build ; touch .gitkeep ; cmake -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ .. && make -j5'
alias fdbuild='rm build -rf ; mkdir build ; cd build ; touch .gitkeep ; CFLAGS="-Wall -Wextra -Og -ggdb" CXXFLAGS="-Wall -Wextra -Og -ggdb" cmake -DMMAKE_BUILD_TYPE=Debug .. && make -j5'
alias fcdbuild='rm build -rf ; mkdir build ; cd build ; touch .gitkeep ; CFLAGS="-Wall -Wextra -Og -ggdb" CXXFLAGS="-Wall -Wextra -Og -ggdb" cmake -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -D CMAKE_BUILD_TYPE=Debug .. && make -j5'

# Build SCAP Security Guide
alias sgbuild='rm build -rf ; mkdir build ; cd build ; touch .gitkeep ; time cmake -G Ninja -DSSG_JINJA2_CACHE_DIR=~/.ssg_jinja_cache .. && time ninja'
alias sgcbuild='rm build -rf ; mkdir build ; cd build ; touch .gitkeep ; cmake -G Ninja -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -DSSG_JINJA2_CACHE_DIR=~/.ssg_jinja_cache .. && ninja'
alias sgdbuild='rm build -rf ; mkdir build ; cd build ; touch .gitkeep ; CFLAGS="-Wall -Wextra -Og -ggdb" CXXFLAGS="-Wall -Wextra -Og -ggdb" cmake -G Ninja -DCMAKE_BUILD_TYPE=Debug -DSSG_JINJA2_CACHE_DIR=~/.ssg_jinja_cache .. && ninja'
alias sgcdbuild='rm build -rf ; mkdir build ; cd build ; touch .gitkeep ; CFLAGS="-Wall -Wextra -Og -ggdb" CXXFLAGS="-Wall -Wextra -Og -ggdb" cmake -G Ninja -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -D CMAKE_BUILD_TYPE=Debug -DSSG_JINJA2_CACHE_DIR=~/.ssg_jinja_cache .. && ninja'


# Build SCAP Workbench
alias swbuild='rm build -rf ; mkdir build ; cd build ; touch .gitkeep ; cmake -G Ninja .. && time ninja'
alias sw1build='rm build -rf ; mkdir build ; cd build ; touch .gitkeep ; cmake .. && time make'
alias swcbuild='rm build -rf ; mkdir build ; cd build ; touch .gitkeep ; cmake -G Ninja -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ .. && ninja'
alias swdbuild='rm build -rf ; mkdir build ; cd build ; touch .gitkeep ; CFLAGS="-Wall -Wextra -Og -ggdb" CXXFLAGS="-Wall -Wextra -Og -ggdb" cmake -G Ninja -DCMAKE_BUILD_TYPE=Debug .. && ninja'
alias swcdbuild='rm build -rf ; mkdir build ; cd build ; touch .gitkeep ; CFLAGS="-Wall -Wextra -Og -ggdb" CXXFLAGS="-Wall -Wextra -Og -ggdb" cmake -G Ninja -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -D CMAKE_BUILD_TYPE=Debug .. && ninja'

alias pep8='python3-pep8 *.py'

function build() {
    local which_ninja="$(which ninja)"
    if [ "x$which_ninja" == "x" ]; then
        which_ninja="$(which ninja-build)"
    fi

    local which_clang="$(which clang)"
    local which_clangpp="$(which clang++)"

    local do_prep=false
    local do_build=false
    local do_debug=false
    local do_cmake_debug=false
    local use_clang=false
    local cmake_args=""

    if [[ $# -eq 0 ]]; then
        do_prep=true
        do_build=true
    else
        for arg in "$@"; do
            if [ "x$arg" == "xprep" ]; then
                do_prep=true
            elif [ "x$arg" == "xbuild" ]; then
                do_build=true
            elif [ "x$arg" == "xclang" ]; then
                use_clang=true
            elif [ "x$arg" == "xdebug" ]; then
                cmake_args="$cmake_args -DCMAKE_BUILD_TYPE=Debug"
                do_debug=true
            elif [ "x$arg" == "xmake" ]; then
                which_ninja=""
            elif [ "x$arg" == "xpython2" ]; then
                cmake_args="$cmake_args -DPYTHON_EXECUTABLE=/usr/bin/python2"
            elif [ "x$arg" == "xpython3" ]; then
                cmake_args="$cmake_args -DPYTHON_EXECUTABLE=/usr/bin/python3"
            fi
        done
    fi

    if [ "$do_prep" == "false" ] && [ "$do_build" == "false" ]; then
        do_prep="true"
        do_build="true"
    fi

    if [ $use_clang ] && [ "x$which_clang" == "x" ]; then
        use_clang=false
    fi

    if [ "$use_clang" == "true" ]; then
        if [ "x$which_clang" != "x" ]; then
            cmake_args="$cmake_args -DCMAKE_C_COMPILER=clang"
        elif [ "x$which_clangpp" != "x" ]; then
            cmake_args="$cmake_args -DCMAKE_CXX_COMPILER=clang++"
        fi
    fi 

    function __build_cd() {
        local pwd="$(pwd)"
        local git_root="$(git rev-parse --show-toplevel)"
        if [ "x$pwd" != "x$git_root" ]; then
            cd "$git_root"
        fi
    }

    function __build_prep_cmake_ninja() {
        time cmake $cmake_args -G Ninja .. 
    }

    function __build_prep_cmake_make() {
        time cmake $cmake_args -G "Unix Makefiles" ..
    }

    function __build_prep_cmake() {
        local have_build_gitkeep=false
        if [ -e "build/.gitkeep" ]; then
            have_build_gitkeep=true
        fi

        rm -rf build && mkdir -p build && cd build
        if [ $have_build_gitkeep ]; then
            touch .gitkeep
        fi

        if [ "x$which_ninja" == "x" ]; then
            echo "Prepping with cmake/make"
            __build_prep_cmake_make
        else
            echo "Prepping with cmake/ninja"
            __build_prep_cmake_ninja
        fi
    }

    function __build_prep() {
        if [ -e "CMakeLists.txt" ]; then
            __build_prep_cmake
        else
            echo "Cannot build: unknown build system"
        fi 
    }

    function __build_make() {
        time make
    }

    function __build_ninja() {
        time $which_ninja
    }

    function __build() {
        if [ "x$which_ninja" == "x" ] && [ ! -e "build.ninja" ]; then
            echo "Building with make"
            __build_make
        else
            echo "Building with ninja"
            __build_ninja
        fi
    }

    __build_cd

    if [ "$do_prep" == "true" ]; then
        __build_prep
    fi
    if [ "$do_build" == "true" ]; then
        __build
    fi
}

# Laptop aliases
ldock() {
    dconf write /org/gnome/settings-daemon/plugins/xsettings/overrides "{'Gdk/WindowScalingFactor': <1>}"
    dconf write /org/gnome/desktop/interface/text-scaling-factor 0.75
}

lundock() {
    dconf write /org/gnome/settings-daemon/plugins/xsettings/overrides "{'Gdk/WindowScalingFactor': <2>}"
    dconf write /org/gnome/desktop/interface/text-scaling-factor 0.65
}

# Upload images
upload() {
    img="$1"
    extension="${img##*.}"
    rimg="$RANDOM-$RANDOM.$extension"
    echo "$img->$rimg"
    scp "$img" "cipherboy:/home/website/cipherboy-website/i/$rimg"
    echo "https://cipherboy.com/i/$rimg"
}

if [ ! -f "$HOME/.no_powerline" ] && [ -f `which powerline-daemon` ]; then
  powerline-daemon -q
  POWERLINE_BASH_CONTINUATION=1
  POWERLINE_BASH_SELECT=1
  . /usr/share/powerline/bash/powerline.sh
fi
