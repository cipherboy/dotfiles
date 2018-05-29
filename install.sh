#!/bin/sh

if [ x"$HOME" == x ]; then
    echo "\$HOME IS NOT SET. REFUSING TO MAKE CHANGES"
    exit 1
fi

cp bashrc $HOME/.bashrc
cp gitconfig $HOME/.gitconfig
cp vimrc $HOME/.vimrc
cp tmux.conf $HOME/.tmux.conf
cp abcde.conf $HOME/.abcde.conf

if [ x"$1" == "xagents" ]; then
    bash ./agents/*.sh
fi
