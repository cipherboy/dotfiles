#!/bin/bash

# Convert to mp3
alias ape2mp3='for a in *.ape; do ffmpeg -i "$a" -qscale:a 320k -b 320k "${a[@]/%ape/mp3}" && rm "$a"; done'
alias flac2mp3='parallel avconv -i {} -qscale:a 320k -b 320k {.}.mp3 ::: *.flac'
alias m4a2mp3='parallel avconv -i {} -qscale:a 320k -b 320k {.}.mp3 ::: *.m4a'
alias wav2mp3='parallel avconv -i {} -qscale:a 320k -b 320k {.}.mp3 ::: *.wav'

# Transcode to FLAC
alias m4a2flac='parallel ffmpeg -i {} {.}.flac ::: *.m4a'
alias wav2flac='parallel ffmpeg -i {} {.}.flac ::: *.wav'

