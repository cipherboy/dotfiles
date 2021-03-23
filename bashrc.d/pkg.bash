alias _fedpkg30='fedpkg --release f30'
alias _fedpkg29='fedpkg --release f29'
alias _fedpkg28='fedpkg --release f28'
alias _rhpkg8='rhpkg-sha512 --release rhel-8.0.0'
alias _rhpkg7='rhpkg --release rhel-7.7'

alias f30b='_fedpkg30 build'
alias f29b='_fedpkg29 build'
alias f28b='_fedpkg28 build'
alias r8b='_rhpkg8 build'
alias r7b='_rhpkg7 build'

alias f30l='_fedpkg30 local'
alias f29l='_fedpkg29 local'
alias f28l='_fedpkg28 local'
alias r8l='_rhpkg8 local'
alias r7l='_rhpkg7 local'

function rgetsrc() {
    rpmspec -P *.spec | grep -i 'Source[0-9]*:\s*\(http\|ftp\)' | awk '{print $NF}' | xargs wget
}

function dbdeps() {
    local ctrl="control"

    if ! command -v equivs; then
        sudo apt install equivs
    fi

    if [ ! -e "$ctrl" ]; then
        ctrl="debian/control"
    fi

    if [ -e "$ctrl" ]; then
        sudo mk-build-deps --install "$ctrl"
    else
        echo "Unable to find control or debian/control" 2>&1
        return 1
    fi
}

function dbuild() {
    dpkg-buildpackage -us -uc
}
