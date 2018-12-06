#!/bin/bash

function koji_rpms() {
    local url="$1"
    local arch="$2"
    curl -s "$url" | grep '\.rpm' | grep -o 'href="[^"]*\.rpm"' | sed 's/^href="//g' | sed 's/"$//g' | grep "$arch"
}
