#!/bin/bash

for i in /etc/profile.d/*.sh; do
	source $i
done

if [ $TILIX_ID ] || [ $VTE_VERSION ]; then
        source /etc/profile.d/vte.sh
fi

# Keep all history
HISTSIZE=-1
HISTFILESIZE=-1

# Force pretty colors
eval "`dircolors`"
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

PANEL_FIFO="/tmp/panel-fifo"

export PATH="$GOPATH/bin:$HOME/.rbenv/bin:/usr/local/go/bin:/opt/bin:/opt/node/bin:/usr/games/bin:$HOME/bin:/usr/local/racket/bin:$PATH"

alias allpdflatex="echo *.tex | entr -r pdflatex -halt-on-error ./*.tex"

alias cms="$HOME/GitHub/cryptominisat/cryptominisat5 ./problem.cnf"

# git aliases
alias gtc='git clone'
alias gtr='git rebase -i '
alias gtrc='git rebase --continue'
alias gta='git add'
alias gtm='git commit -s'
alias gtp='git push'
alias gts='git status'
alias gtd='git diff'

# grep aliases
alias gir='grep --exclude=tags -iIr'
alias gic='grep --exclude=tags -nIHr'
alias gif='grep --exclude=tags -iInHr'

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

if [ -f `which powerline-daemon` ]; then
  powerline-daemon -q
  POWERLINE_BASH_CONTINUATION=1
  POWERLINE_BASH_SELECT=1
  . /usr/share/powerline/bash/powerline.sh
fi
