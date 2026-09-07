#!/usr/bin/env python3

import os
import sys

# set server timezone in UTC before time module imported
os.environ['TZ'] = 'UTC'

import debugpy

host = os.environ.get("DEBUGPY_HOST", "0.0.0.0")
port = int(os.environ.get("DEBUGPY_PORT", "5678"))
wait = os.environ.get("DEBUGPY_WAIT", "1") == "1"

# Forward attach: the container LISTENS, VS Code connects in to localhost:5678.
debugpy.listen((host, port))
print(">>> [debugpy] Odoo debugger listening on {}:{}. Start 'Attach to Odoo (Docker)' in VS Code.".format(host, port), flush=True)

if wait:
    print(">>> [debugpy] Waiting for VS Code to attach before starting Odoo (set DEBUGPY_WAIT=0 to skip)...", flush=True)
    debugpy.wait_for_client()
    print(">>> [debugpy] Debugger attached!", flush=True)

import odoo

if __name__ == "__main__":
    sys.argv[0] = "odoo"
    odoo.cli.main()