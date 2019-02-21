#!/bin/bash

function wcrb() {
    local playlist="https://streams.audio.wgbh.org:8204/classical-hi"

    mplay "$playlist"
}

function wcrb_bso() {
    local playlist="https://streams.audio.wgbh.org:8107/BSOConcert-8106"

    mplay "$playlist"
}

function wcrb_early() {
    local playlist="https://streams.audio.wgbh.org:8113/BostonEarlyMusic-8112"

    mplay "$playlist"
}

function wcrb_bach() {
    local playlist="https://streams.audio.wgbh.org:8208/Bach-8108"

    mplay "$playlist"
}

function cmpr() {
    local playlist="https://cms.stream.publicradio.org/cms.mp3"

    mplay "$playlist"
}

function mplay() {
    local player="$AUDIO_PLAYER"
    if [ "x$player" == "x" ]; then
        player="$(which nvlc)"
    fi

    $player "$@"
}

function mmount() {
    mkdir -p "$HOME/rmusic"

    if ssh recon7 exit 0 2>/dev/null >/dev/null; then
        sshfs recon7:/media/large/Music "$HOME/rmusic"
    else
        sshfs recon7r:/media/large/Music "$HOME/rmusic"
    fi
}
