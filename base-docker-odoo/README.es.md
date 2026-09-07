# base-docker-odoo - Base de depuración de Odoo 17.0

Copia esta carpeta para iniciar un nuevo proyecto local de Odoo, o
(preferido) usa el generador de la carpeta padre: `./create-odoo-project.sh`.

Todos los nombres, credenciales y puertos son **placeholders** con valores
genéricos por defecto. Nada de esta plantilla está ligado a un proyecto
concreto. Sobrescríbelos en `.env` (p. ej. `PROJECT_NAME`, `DB_USER`,
`PGADMIN_EMAIL`). Los placeholders tipo `*-odoo` se mantienen genéricos
cuando `PROJECT_NAME` está vacío.

Disposición base, con el depurador de VS Code / VSCodium preconfigurado
(forward attach vía debugpy).

## Inicio rápido

```bash
cp -r base-docker-odoo mi-proyecto && cd mi-proyecto
docker compose up -d
```

- **Odoo:** http://localhost:8069
- **PgAdmin:** http://localhost:5050 (admin@example.com / admin)

## Depuración

```bash
DEBUGPY=1 docker compose up -d odoo
```

Después, en VS Code / Codium: **Depurar: Seleccionar e iniciar depuración** →
**"Attach to Odoo (Docker)"** (se conecta a `localhost:5678`).

- Los breakpoints en `custom/` funcionan de inmediato.
- Los breakpoints del **núcleo de Odoo** funcionan tras reflejar el código
  fuente de la imagen en ejecución: `./refresh_odoo_src.sh` (crea
  `odoo-src/`).
- En modo debug, el entrypoint cambia `--dev=all` por `--dev=xml,qweb` (la
  opción `reload` de Odoo re-ejecuta el proceso vía `os.execve` y mataría el
  depurador). Los cambios de Python requieren `docker compose restart odoo`.

El flujo completo está documentado en el `README.md` de la carpeta padre.