# odoo-docker-env

Docker-based Odoo development environment with a **fully working debugger**
for the official `odoo:*` images (no modification of the image's Odoo core).

- `create-odoo-project.sh` - generate a new Odoo project with the debug setup
- `base-docker-odoo/` - ready-to-copy base project (same setup, all names/credentials are placeholders overridable in `.env`)

## What "debug setup" means here

Debugging an official-image container is done with **forward attach**:

1. The container runs Odoo under `debugpy` and *listens* on port `5678`.
2. VS Code / VSCodium connects in to `localhost:5678` and pauses at your
   breakpoints.

Two Odoo quirks are handled automatically:

- **`reload` dev mode kills the debugger.** Odoo's `--dev` `reload` option
  re-executes the process via `os.execve` the moment a `.py` file changes;
  that destroys the debugpy session. In debug mode the entrypoint replaces
  `--dev=all` with `--dev=xml,qweb` (xml/qweb auto-reload is preserved).
- **Core breakpoints need a source mirror.** Odoo core ships only inside the
  image (`/usr/lib/python3/dist-packages/odoo`). `refresh_odoo_src.sh` copies
  the exact running source (only `.py` files) into `./odoo-src`, which
  `launch.json` maps via `pathMappings` — so you can step into `models.py`,
  `fields.py`, base module inheritances, etc.

## Requirements

- Docker Engine (Compose v2) on Linux (also works on macOS/Windows Docker
  Desktop; port `5678` is published to the host).
- VS Code or VSCodium with the Python extension (`ms-python.python`).

## Usage

### Option A - Generate a new project (recommended)

```bash
./create-odoo-project.sh -n my-project -v 17.0
cd my-project
docker compose up -d
```

Options: `-n|--name`, `-v|--version`, `-d|--db`, `-p|--port`, `--dbport`,
`--debug codium|pycharm|none`, `-i` (interactive), `-h`.

### Option B - Copy the base template

```bash
cp -r base-docker-odoo my-project && cd my-project
docker compose up -d
```

## Debugging workflow

```bash
# 1. Start Odoo paused for the debugger
DEBUGPY=1 docker compose up -d odoo
```

```text
>>> [debugpy] Odoo debugger listening on 0.0.0.0:5678. Start 'Attach to Odoo (Docker)' in VS Code.
>>> [debugpy] Waiting for VS Code to attach before starting Odoo ...
```

```text
# 2. In VS Code / Codium
#    Debug: Select and Start Debugging  ->  "Attach to Odoo (Docker)"
```

3. Odoo boots and pauses at your breakpoints.

Where you can put breakpoints:

- your addons in `custom/` → mapped to `/mnt/extra-addons`
- core Odoo code in `odoo-src/` → mapped to `/usr/lib/python3/dist-packages/odoo`
  (run `./refresh_odoo_src.sh` first; refresh again after pulling a new image)

### Round-trip / stop

```bash
docker compose up -d odoo        # DEBUGPY=0 -> normal mode (--dev=all)
docker compose restart odoo      # during a debug session, reload python changes
```

## Debug knobs (`.env`)

| Variable | Default | Meaning |
|----------|---------|---------|
| `DEBUGPY` | `0` | `1` = run Odoo under the debugger |
| `DEBUGPY_PORT` | `5678` | port the container listens on |
| `DEBUGPY_WAIT` | `1` | `1` = pause at startup until attached; `0` = start immediately, pause only at breakpoints |

## Troubleshooting

**"Debugger never attaches" / VS Code says waiting forever**
- Make sure no other VSCode/VS Codium debug session (or leftover `debugpy
  adapter` process) is holding port `5678` on the host. Check with
  `ss -tlnp | grep 5678` and stop the stale session / kill the PID.
- Confirm the container printed `>>> [debugpy] ... listening` in
  `docker compose logs odoo`.

**Breakpoints in core don't resolve** → line numbers drift after an image
update. Re-run `./refresh_odoo_src.sh` (files are copied verbatim from the
running container, so they match exactly).

**Container still fails to boot in debug mode** → check `docker compose logs
odoo`; if the debug entrypoint never runs, your image may predate the
`debugpy` install: rebuild with `docker compose build odoo`.

**PyCharm** → not implemented yet, a placeholder (`config/pycharm_debug_TODO.md`)
is generated when using `--debug pycharm`.

## Files

| File | Purpose |
|------|---------|
| `create-odoo-project.sh` | project generator |
| `base-docker-odoo/` | copyable base project |
| `base-docker-odoo/debug_entrypoint.sh` | switches normal vs debug mode; drops `reload` in debug |
| `base-docker-odoo/debug_launcher.py` | `debugpy.listen` then boots Odoo |
| `base-docker-odoo/refresh_odoo_src.sh` | mirrors exact core sources into `odoo-src/` |
| `base-docker-odoo/.vscode/launch.json` | `Attach to Odoo (Docker)` + path mappings |