#!/bin/bash

if [ "x$HOME" == "x" ]; then
    echo "\$HOME IS NOT SET. REFUSING TO MAKE CHANGES"
    exit 1
fi

function __do_install() {
    local do_install_agents="false"
    local do_install_bash="false"
    local do_install_vimrc="false"
    local do_install_spacevim="false"
    local do_install_tmux="false"
    local do_install_abcde="false"
    local do_install_git="false"
    local do_install_tlp="false"
    local do_install_ccache="false"

    for arg in "$@"; do
        if [ "x$arg" == "xall" ]; then
            do_install_agents="true"
            do_install_bash="true"
            do_install_vimrc="true"
            do_install_tmux="true"
            do_install_abcde="true"
            do_install_git="true"
            do_install_tlp="true"
            do_install_ccache="true"
        elif [ "x$arg" == "xbash" ]; then
            do_install_bash="true"
        elif [ "x$arg" == "xvimrc" ]; then
            do_install_vimrc="true"
        elif [ "x$arg" == "xspacevim" ]; then
            do_install_spacevim="true"
        elif [ "x$arg" == "xtmux" ]; then
            do_install_tmux="true"
        elif [ "x$arg" == "xabcde" ]; then
            do_install_abcde="true"
        elif [ "x$arg" == "xgit" ]; then
            do_install_git="true"
        elif [ "x$arg" == "xagents" ]; then
            do_install_agents="true"
        elif [ "x$arg" == "xtlp" ]; then
            do_install_tlp="true"
        elif [ "x$arg" == "xccache" ]; then
            do_install_ccache="true"
        fi
    done

    if [ "$do_install_bash" == "true" ]; then
        echo "Installing bash..."
        cp -v bashrc "$HOME/.bashrc"
        mkdir -p "$HOME/.bashrc.d"
        pushd bashrc.d
            for file in *; do
                rm -vf "$HOME/.bashrc.d/$file"
                cp -rv "$file" "$HOME/.bashrc.d/"
            done
        popd
    fi

    if [ "$do_install_git" == "true" ]; then
        echo "Installing git..."
        cp -v gitconfig "$HOME/.gitconfig"
        mkdir -pv "$HOME/.git"
        rm -vf "$HOME/.git/vimrc"
        cp -v vimrc "$HOME/.git/vimrc"
    fi

    if [ "$do_install_vimrc" == "true" ]; then
        echo "Installing vimrc..."
        cp -v vimrc "$HOME/.vimrc"
        mkdir -pv "$HOME/.vim/swapfiles" "$HOME/.vim/spell"
    fi

    if [ "$do_install_spacevim" == "true" ]; then
        echo "Installing spacevim..."
        rm -vf "$HOME/.SpaceVim.d/"
        cp -rv SpaceVim.d "$HOME/.SpaceVim.d"
        curl -sLf https://spacevim.org/install.sh | bash
    fi

    if [ "$do_install_tmux" == "true" ]; then
        echo "Installing tmux..."
        cp -v tmux.conf "$HOME/.tmux.conf"
    fi

    if [ "$do_install_abcde" == "true" ]; then
        echo "Installing abcde..."
        cp -v abcde.conf "$HOME/.abcde.conf"
    fi

    if [ "$do_install_tlp" == "true" ]; then
        echo "Installing tlp..."
        cp -v tlp /etc/default/tlp
    fi

    if [ "$do_install_ccache" == "true" ]; then
        echo "Installing ccache..."
        mkdir -p -v "$HOME/.ccache"
        cp -v ccache.conf "$HOME/.ccache/ccache.conf"
    fi

    if [ "$do_install_agents" == "true" ]; then
        echo "Installing agents..."
        bash ./agents/*.sh
    fi
}

__do_install "$@"
