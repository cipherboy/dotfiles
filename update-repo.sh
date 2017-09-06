#!/bin/sh

if [ x"$HOME" == x ]; then
    echo "\$HOME IS NOT SET. REFUSING TO MAKE CHANGES"
    exit 1
fi

cp $HOME/.bashrc bashrc
cp $HOME/.gitconfig gitconfig
cp $HOME/.vimrc vimrc
cp $HOME/.tmux.conf tmux.conf
