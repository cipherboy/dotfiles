#!/bin/bash

for i in /etc/profile.d/*.sh; do
	source $i
done

if [ "$TILIX_ID" ] || [ "$VTE_VERSION" ]; then
        source /etc/profile.d/vte.sh
fi

# Shell Options
shopt -s checkwinsize
shopt -s globstar 2> /dev/null
bind "set show-all-if-ambiguous on"

# Keep all history
shopt -s histappend
shopt -s cmdhist
HISTSIZE=-1
HISTFILESIZE=-1
HISTCONTROL="ignoredups:erasedups"
export HISTIGNORE="reload:exit:ls:bg:fg:history:clear"

# Vim helpers
export VISUAL=vim
export EDITOR="$VISUAL"
export GIT_EDITOR="$EDITOR"
function vimnpw() {
    sed 's/^" \(autocmd BufWritePre\)/\1/g' ~/.vimrc -i
}
function vimpw() {
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

# Generate a new password
alias genpass="tr -cd '[:alnum:]' < /dev/urandom | fold -w30 | head -n1"

## PS1
PS1='[\u@\h \W]\$ '

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

export PATH="$(__DEDUPE_PATH "/usr/lib64/ccache:/usr/games/bin:$HOME/bin:$PATH")"

alias allpdflatex="echo *.tex | entr -r pdflatex -halt-on-error ./*.tex"


# grep aliases
alias gir='grep --exclude=tags --exclude-dir=.git --exclude-dir=build -iIr'
alias gic='grep --exclude=tags --exclude-dir=.git --exclude-dir=build -nIHr'
alias gif='grep --exclude=tags --exclude-dir=.git --exclude-dir=build -iInHr'
alias gff="find . -path '*/build/*' -prune -path '*.git*' -prune -o -print | grep -i"

function vgff() {
    local query="$1"
    for file in $(find . -path '*/build/*' -prune -path '*.git*' -prune -o -print | grep -i "$query"); do
        if [ -f "$file" ]; then
            vi "$file"
        fi
    done
}

function gitc() {
    local query="$1"
    grep -ro "$query" | wc -l
}

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
    scp "$img" "cipherboy:/home/website/cipherboy-website/i/$rimg"
    echo "https://cipherboy.com/i/$rimg"
}

function load() {
    source "$HOME/.bashrc.d/$1.bash"
}

alias reload='source $HOME/.bashrc'

for script in $HOME/.bashrc.d/*.sh; do
    source "$script"
done

if [ ! -f "$HOME/.no_powerline" ] && [ -f "$(which powerline-daemon)" ]; then
  powerline-daemon -q
  POWERLINE_BASH_CONTINUATION=1
  POWERLINE_BASH_SELECT=1
  . /usr/share/powerline/bash/powerline.sh
fi
