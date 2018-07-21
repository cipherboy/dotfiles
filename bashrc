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

export GOPATH="$HOME/Development/go"

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

export PATH="/usr/lib64/ccache:/usr/games/bin:$HOME/bin:$PATH"

alias allpdflatex="echo *.tex | entr -r pdflatex -halt-on-error ./*.tex"


# grep aliases
alias gir='grep --exclude=tags --exclude-dir=.git --exclude-dir=build -iIr'
alias gic='grep --exclude=tags --exclude-dir=.git --exclude-dir=build -nIHr'
alias gif='grep --exclude=tags --exclude-dir=.git --exclude-dir=build -iInHr'
alias gff='find . -path "*.git*" -prune -o -print | grep -i'

function vgff() {
    local query="$1"
    for file in $(find . -path "*.git*" -prune -o -print | grep -i "$query"); do
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
alias pep8='python3-pep8 *.py'

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

for script in $HOME/.bashrc.d/*.sh; do
    source "$script"
done

if [ ! -f "$HOME/.no_powerline" ] && [ -f `which powerline-daemon` ]; then
  powerline-daemon -q
  POWERLINE_BASH_CONTINUATION=1
  POWERLINE_BASH_SELECT=1
  . /usr/share/powerline/bash/powerline.sh
fi
