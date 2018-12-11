#!/bin/bash

function vm_list() {
    sudo virsh list
}

function vm_addrs() {
    sudo virsh domifaddr --full "$1"
}
