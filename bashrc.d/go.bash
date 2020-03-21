export GOPATH="$HOME/go"
mkdir -p "$GOPATH"

export PATH="$GOPATH/bin:$PATH"

function gcd() {
	if [ -e "$GOPATH/src/git.cipherboy.com/"*"/$1" ]; then
		pushd "$GOPATH/src/git.cipherboy.com/"*"/$1"
	elif [ -e "$GOPATH/src/github.com/cipherboy/$1" ]; then
		pushd "$GOPATH/src/github.com/cipherboy/$1"
	fi
}
