#!/bin/bash

if [ "x$HOME" == "x" ]; then
    echo "\$HOME IS NOT SET. REFUSING TO MAKE CHANGES"
    exit 1
fi

function __do_update() {
    local do_update_agents="false"
    local do_update_bash="false"
    local do_update_vimrc="false"
    local do_update_tmux="false"
    local do_update_abcde="false"
    local do_update_git="false"
    local do_update_tlp="false"
    local do_update_ccache="false"

    for arg in "$@"; do
        if [ "x$arg" == "xall" ]; then
            do_update_agents="true"
            do_update_bash="true"
            do_update_vimrc="true"
            do_update_tmux="true"
            do_update_abcde="true"
            do_update_git="true"
            do_update_tlp="true"
            do_update_ccache="true"
        elif [ "x$arg" == "xbash" ]; then
            do_update_bash="true"
        elif [ "x$arg" == "xvimrc" ]; then
            do_update_vimrc="true"
        elif [ "x$arg" == "xtmux" ]; then
            do_update_tmux="true"
        elif [ "x$arg" == "xabcde" ]; then
            do_update_abcde="true"
        elif [ "x$arg" == "xgit" ]; then
            do_update_git="true"
        elif [ "x$arg" == "xagents" ]; then
            do_update_agents="true"
        elif [ "x$arg" == "xtlp" ]; then
            do_update_tlp="true"
        elif [ "x$arg" == "xccache" ]; then
            do_update_ccache="true"
        fi
    done


    if [ "$do_update_bash" == "true" ]; then
        echo "Updating bash..."
        cp -v "$HOME/.bashrc" bashrc

        for bashrc_obj in "$HOME/.bashrc.d/"*; do
            cp -rv "$bashrc_obj" bashrc.d/
        done
    fi

    if [ "$do_update_git" == "true" ]; then
        echo "Updating git..."
        cp -v "$HOME/.gitconfig" gitconfig
    fi

    if [ "$do_update_vimrc" == "true" ]; then
        echo "Updating vimrc..."
        cp -v "$HOME/.vimrc" vimrc
    fi

    if [ "$do_update_tmux" == "true" ]; then
        echo "Updating tmux..."
        cp -v "$HOME/.tmux.conf" tmux.conf
    fi

    if [ "$do_update_abcde" == "true" ]; then
        echo "Updating abcde..."
        cp -v "$HOME/.abcde.conf" abcde.conf
    fi

    if [ "$do_update_tlp" == "true" ]; then
        echo "Updating tlp..."
        cp -v /etc/default/tlp tlp
    fi

    if [ "$do_update_ccache" == "true" ]; then
        echo "Updating ccache..."
        cp -v "$HOME/.ccache/ccache.conf" ccache.conf
    fi

}

__do_update "$@"
