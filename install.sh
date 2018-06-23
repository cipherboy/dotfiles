#!/bin/sh

if [ x"$HOME" == x ]; then
    echo "\$HOME IS NOT SET. REFUSING TO MAKE CHANGES"
    exit 1
fi

function __do_install() {
    local do_install_agents="false"
    local do_install_bash="false"
    local do_install_vimrc="false"
    local do_install_tmux="false"
    local do_install_abcde="false"
    local do_install_git="false"

    for arg in "$@"; do
        if [ "x$arg" == "xbash" ]; then
            local do_install_bash="true"
        elif [ "x$arg" == "xvimrc" ]; then
            local do_install_vimrc="true"
        elif [ "x$arg" == "xtmux" ]; then
            local do_install_tmux="true"
        elif [ "x$arg" == "xabcde" ]; then
            local do_install_abcde="true"
        elif [ "x$arg" == "xgit" ]; then
            local do_install_git="true"
        elif [ "x$arg" == "xagents" ]; then
            local do_install_agents="true"
        fi
    done

    if [ "$do_install_bash" == "true" ]; then
        echo "Installing bash..."
        cp -v bashrc $HOME/.bashrc
        rm -vrf $HOME/.bashrc.d
        cp -rv bashrc.d $HOME/.bashrc.d
    fi

    if [ "$do_install_git" == "true" ]; then
        echo "Installing git..."
        cp -v gitconfig $HOME/.gitconfig
    fi

    if [ "$do_install_vimrc" == "true" ]; then
        echo "Installing vimrc..."
        cp -v vimrc $HOME/.vimrc
    fi

    if [ "$do_install_tmux" == "true" ]; then
        echo "Installing tmux..."
        cp -v tmux.conf $HOME/.tmux.conf
    fi

    if [ "$do_install_abcde" == "true" ]; then
        echo "Installing abcde..."
        cp -v abcde.conf $HOME/.abcde.conf
    fi

    if [ "$do_install_agents" == "true" ]; then
        echo "Installing agents..."
        bash ./agents/*.sh
    fi
}

__do_install "$@"
