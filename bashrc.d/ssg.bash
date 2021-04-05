#!/bin/bash

function re() {
    local rule="$1"
    v "$rule.*/rule.yml:3"
}

export PYTHONPATH="$(gtcd):$PYTHONPATH"
export PATH="$PATH:$(gtcd)/utils"
export BUILD_CMAKE_ARGS=("-DSSG_PRODUCT_DEFAULT=OFF" "-DSSG_PRODUCT_UBUNTU2004=ON")
