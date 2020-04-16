#!/bin/bash

curl -sLf https://spacevim.org/install.sh | bash

if command -v sudo; then
    if [ ! -e /usr/share/fonts/source-code-pro ]; then
        sudo bash ./agents/spacevim-fonts.sh
    fi

    sudo bash ./agents/spacevim-npm.sh
fi

if command -v go; then
    go get -u github.com/jstemmer/gotags
    go get -u github.com/sourcegraph/go-langserver
    vim +GoInstallBinaries +qall
fi

if command -v pip3; then
    pip3 install --user flake8
    pip3 install --user autoflake
    pip3 install --user isort
    pip3 install --user coverage
    pip3 install --user python-language-server
fi
