#!/bin/bash

set -e

# ============================================================
# Odoo debug entrypoint
# - Normal mode (DEBUGPY != 1): behaves like the official entrypoint
# - Debug mode  (DEBUGPY = 1): starts Odoo under debugpy (forward
#   attach). VS Code connects in to localhost:5678. The 'reload'
#   dev flag is dropped because it re-execs the process (os.execve),
#   which tears down the debugpy session; xml/qweb reload remain.
# ============================================================

if [ "${DEBUGPY:-0}" != "1" ]; then
    exec /entrypoint.sh "$@"
fi

: ${HOST:=${DB_PORT_5432_TCP_ADDR:='db'}}
: ${PORT:=${DB_PORT_5432_TCP_PORT:=5432}}
: ${USER:=${DB_ENV_POSTGRES_USER:=${POSTGRES_USER:='odoo'}}}
: ${PASSWORD:=${DB_ENV_POSTGRES_PASSWORD:=${POSTGRES_PASSWORD:='odoo'}}}

# Wait for the database to be ready
wait-for-psql.py --db_host "${HOST}" --db_port "${PORT}" \
                 --db_user "${USER}" --db_password "${PASSWORD}" --timeout=30

# Strip leading "odoo" if the command starts with it
if [ "$1" == "odoo" ]; then
    shift
fi

# Odoo 'reload' dev mode re-execs the process (os.execve) on python
# changes and kills the debugger. Replace --dev with xml,qweb only.
args=()
for a in "$@"; do
    case "$a" in
        --dev*)
            ;;
        *)
            args+=("$a")
            ;;
    esac
done

DB_ARGS=()
function check_config() {
    param="$1"
    value="$2"
    if grep -q -E "^\s*\b${param}\b\s*=" "$ODOO_RC" ; then
        value=$(grep -E "^\s*\b${param}\b\s*=" "$ODOO_RC" |cut -d " " -f3|sed 's/["\n\r]//g')
    fi;
    DB_ARGS+=("--${param}")
    DB_ARGS+=("${value}")
}
check_config "db_host" "$HOST"
check_config "db_port" "$PORT"
check_config "db_user" "$USER"
check_config "db_password" "$PASSWORD"

DEV_MODE="${ODOO_DEV_DEBUG:-xml,qweb}"
echo ">>> [debugpy] Launching Odoo under debugger: python3 /mnt/debug_launcher.py --dev=${DEV_MODE} ${DB_ARGS[@]} ${args[@]}"
exec python3 -u /mnt/debug_launcher.py "--dev=${DEV_MODE}" "${DB_ARGS[@]}" "${args[@]}"