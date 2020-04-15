#!/bin/bash

curl -sLf https://spacevim.org/install.sh | bash
if [ ! -e /usr/share/fonts/source-code-pro ]; then
  if mkdir -p /usr/share/fonts/source-code-pro; then
    wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.0.0/SourceCodePro.zip -O /tmp/SCP.zip
    pushd /usr/share/fonts/source-code-pro
      unzip /tmp/SCP.zip
    popd
    rm /tmp/SCP.zip
  fi
fi
