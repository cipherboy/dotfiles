#!/bin/bash

if [ -e /etc/profile ]; then
    source /etc/profile
fi

for i in /etc/profile.d/*.sh; do
    source $i
done

if [ "$TILIX_ID" ] || [ "$VTE_VERSION" ]; then
    source /etc/profile.d/vte.sh
fi

# Shell Options
shopt -s checkwinsize
shopt -s globstar 2> /dev/null
if [ -t 1 ]; then
    bind "set show-all-if-ambiguous on"
fi

# Keep all history
shopt -s histappend
shopt -s cmdhist
if (( BASH_VERSINFO[0] > 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] >= 3 ) )); then
    HISTSIZE=-1
    HISTFILESIZE=-1
else
    HISTSIZE=999999999
    HISTFILESIZE=999999999
fi

HISTCONTROL="ignoredups:erasedups"
export HISTIGNORE="reload:exit:ls:bg:fg:history:clear"

# Vim helpers
export VISUAL="vim"
export EDITOR="$VISUAL"
export GIT_EDITOR="$VISUAL"
function vnpw() {
    sed 's/^" \(autocmd BufWritePre\)/\1/g' ~/.vimrc -i
}
function vpw() {
    sed 's/^\(autocmd BufWritePre\)/" \1/g' ~/.vimrc -i
}


# Force pretty colors
eval "$(dircolors)"
alias ls="ls --color=auto --group-directories-first"
alias grep="grep --color=auto"

## Common aliases
# emacs alias to fix x-keypass
alias emacs='GPG_AGENT_INFO="" emacs --display "" --no-window-system '

# youtube audio download
alias yaudio='youtube-dl -x --audio-quality 0 --audio-format best -f bestaudio'
alias yvideo='youtube-dl -x --audio-quality 0 --audio-format best -f best -k'

## PS1
PS1="[\\u@\\h \\W]\\$ "

function __DEDUPE_PATH() {
    local _old_path="${1//:/$'\n'}"
    local _new_path=""

    local _old_IFS="$IFS"
    IFS=$'\n'

    for _old_part in $_old_path; do
        local _have_part="false"
        for _new_part in ${_new_path//:/$'\n'}; do
            if [ "x$_old_part" == "x$_new_part" ]; then
                _have_part="true"
                break
            fi
        done

        if [ "$_have_part" == "false" ]; then
            if [ "x$_new_path" == "x" ]; then
                _new_path="$_old_part"
            else
                _new_path="$_new_path:$_old_part"
            fi
        fi
    done

    IFS="$_old_IFS"
    echo "$_new_path"
}

export PATH="$(__DEDUPE_PATH "/usr/lib64/ccache:/usr/games/bin:$HOME/bin:/usr/sbin:/usr/local/go/bin:/usr/local/bin:/usr/local/sbin:$PATH:$HOME/go/bin")"

alias allpdflatex="echo *.tex | entr -r pdflatex -halt-on-error ./*.tex"

# project aliases
alias actags='ctags -R  --c-kinds=+cdefglmnpstuvx --langmap=c:+.cin.hin'

# Laptop aliases
ldock() {
    dconf write /org/gnome/settings-daemon/plugins/xsettings/overrides "{'Gdk/WindowScalingFactor': <1>}"
    dconf write /org/gnome/desktop/interface/text-scaling-factor 0.75
}

lundock() {
    dconf write /org/gnome/settings-daemon/plugins/xsettings/overrides "{'Gdk/WindowScalingFactor': <2>}"
    dconf write /org/gnome/desktop/interface/text-scaling-factor 0.65
}

# Upload images to cipherboy.com
upload() {
    img="$1"
    extension="${img##*.}"
    rimg="$RANDOM-$RANDOM.$extension"
    echo "$img->$rimg"
    scp "$img" "cipherboy:/home/website/cipherboy.com/i/$rimg"
    echo "https://cipherboy.com/i/$rimg"
}

function load() {
    local rcdir="$HOME/.bashrc.d"

    if (( $# == 0 )); then
        echo "Usage: load <module>"
        echo ""

        echo "Bash modules:"
        ls "$rcdir" | grep '\.bash$' | sed 's/\.bash$//g' | ecolor 'so'
        echo ""

        echo "Shell modules:"
        ls "$rcdir" | grep '\.sh$' | sed 's/\.sh$//g' | ecolor 'so'

        return 0
    fi

    local base="$rcdir/$1"

    if [ -e "$base.bash" ]; then
        source "$base.bash"
    elif [ -e "$base.sh" ]; then
        source "$base.sh"
    else
        source "$base"
    fi
}

alias reload='source $HOME/.bashrc'

for script in $HOME/.bashrc.d/*.sh; do
    source "$script"
done

if [ ! -f "$HOME/.no_powerline" ] && [ -f "$(which powerline-daemon)" ]; then
    powerline-daemon -q
    POWERLINE_BASH_CONTINUATION=1
    POWERLINE_BASH_SELECT=1
    if [ -e /usr/share/powerline/bash/powerline.sh ]; then
        . /usr/share/powerline/bash/powerline.sh
    else
        . /usr/share/powerline/integrations/powerline.sh
    fi
fi
