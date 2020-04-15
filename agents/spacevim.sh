#!/bin/bash

curl -sLf https://spacevim.org/install.sh | bash
if command -v sudo; then
    sudo ./spacevim-fonts.sh
fi
