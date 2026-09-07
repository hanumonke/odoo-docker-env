# base-docker-odoo - Odoo 17.0 Debug Base

Copy this folder to start a new local Odoo project, or (preferred) use the
generator in the parent folder: `./create-odoo-project.sh`.

All names, credentials and ports are **placeholders** with generic defaults.
Nothing in this template is tied to a specific project. Override them in
`.env` (e.g. `PROJECT_NAME`, `DB_USER`, `PGADMIN_EMAIL`). The `*-odoo`
placeholders below remain generic when `PROJECT_NAME` is empty.

Base layout, with the VS Code / VSCodium debugger pre-configured
(forward attach via debugpy).

## Quick Start

```bash
cp -r base-docker-odoo my-project && cd my-project
docker compose up -d
```

- **Odoo:** http://localhost:8069
- **PgAdmin:** http://localhost:5050 (admin@example.com / admin)

## Debugging

```bash
DEBUGPY=1 docker compose up -d odoo
```

Then in VS Code / Codium: **Debug: Select and Start Debugging** →
**"Attach to Odoo (Docker)"** (connects in to `localhost:5678`).

- Breakpoints in `custom/` work out of the box.
- Breakpoints in **core Odoo code** work after mirroring the running image's
  source: `./refresh_odoo_src.sh` (creates `odoo-src/`).
- In debug mode the entrypoint swaps `--dev=all` for `--dev=xml,qweb`
  (Odoo's `reload` flag re-execs the process via `os.execve` and would kill
  the debugger). Python changes need `docker compose restart odoo`.

Read the full workflow in the parent `README.md`.