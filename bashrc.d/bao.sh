#!/bin/bash

# Muscle memory.
alias vault=bao

function baoenv() {
    export DATA_ROOT="${XDG_DATA_HOME:-$HOME/.local/share}"
    export BAO_DIR="$DATA_ROOT/openbao"
    export LOG_DIR="$BAO_DIR/logs"
    if [ ! -e "$LOG_DIR" ]; then
        mkdir -p "$LOG_DIR"
    fi
}

function devbao() {
    local port="${BAO_PORT:-8200}"

    (
        set -euxo pipefail

        baoenv

        if [ -z "${BAO_NO_KILL:-}" ]; then
            pkill bao || true
        fi

        # Start OpenBao
        (
            bao server -dev -dev-listen-address="0.0.0.0:$port" -dev-root-token-id=devroot 2>&1 | tee "$LOG_DIR/vault.log"
        ) &

        # Wait for it to start up.
        local ok="false"
        for i in `seq 1 10`; do
            echo "Retrying connection $i..."
            if ! nc -w 1 127.0.0.1 "$port" </dev/null; then
                sleep 1
                continue
            fi
            ok="true"
            break
        done

        if [ "$ok" == "false" ]; then
            cat "$LOG_DIR/vault.log" 1>&2
            exit 1
        fi
    )

    echo 'export VAULT_ADDR="http://127.0.0.1:$port"'
    echo 'export VAULT_TOKEN="devroot"'
    export VAULT_ADDR="http://127.0.0.1:$port"
    export VAULT_TOKEN="devroot"
}
