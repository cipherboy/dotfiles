#!/bin/sh

if [ x"$HOME" == x ]; then
    echo "\$HOME IS NOT SET. REFUSING TO MAKE CHANGES"
    exit 1
fi

cp bashrc $HOME/.bashrc
cp gitconfig $HOME/.gitconfig
