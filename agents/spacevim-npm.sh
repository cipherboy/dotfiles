#!/usr/bin/env bash

if command -v npm; then
    npm install --global vscode-html-languageserver-bin
    npm install --global vscode-css-languageserver-bin
    npm install --global vscode-json-languageserver-bin
    npm install --global remark
    npm install --global remark-cli
    npm install --global remark-stringify
    npm install --global remark-frontmatter
    npm install --global wcwidth
    npm install --global prettier
    npm install --global bash-language-server
    npm install --global javascript-typescript-langserver
    npm update --global
fi
