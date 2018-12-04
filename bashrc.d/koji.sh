#!/bin/bash

function koji_rpms() {
    local url="$1"
    local arch="$2"
    wget -O- "$url" | grep '\.rpm' | grep -o 'href="[^"]*\.rpm"' | sed 's/^href="//g' | sed 's/"$//g' | grep "$arch" > /tmp/urls
}
