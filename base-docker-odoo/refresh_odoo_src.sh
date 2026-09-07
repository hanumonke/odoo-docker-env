#!/bin/bash

# Mirror the exact Odoo core Python source (only .py files) from the running
# container into ./odoo-src so VS Code can resolve breakpoints in core Odoo
# code (pathMapping: ./odoo-src -> /usr/lib/python3/dist-packages/odoo).
#
# Refresh it when you pull/rebuild a new odoo image. Requires the odoo
# container to be up (normal mode is fine).

set -euo pipefail

CONTAINER="${1:-${PROJECT_NAME:-odoo}}"
DEST="$(dirname "$0")/odoo-src"

docker cp "${CONTAINER}:/usr/lib/python3/dist-packages/odoo" /tmp/odoo-src-full
rm -rf "${DEST}"
mkdir -p "${DEST}"
find /tmp/odoo-src-full -name '*.py' -printf '%P\n' | while read -r f; do
    mkdir -p "${DEST}/$(dirname "$f")"
    cp -p "/tmp/odoo-src-full/$f" "${DEST}/$f"
done
rm -rf /tmp/odoo-src-full

echo "Odoo core source mirrored to ${DEST} ($(find "${DEST}" -name '*.py' | wc -l) files)."