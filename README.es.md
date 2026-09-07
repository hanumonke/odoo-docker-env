# odoo-docker-env

Entorno de desarrollo de Odoo basado en Docker con **depurador totalmente
funcional** para las imágenes oficiales `odoo:*` (sin modificar el núcleo de
Odoo de la imagen).

- `create-odoo-project.sh` - genera un nuevo proyecto Odoo con la configuración
  de depuración
- `base-docker-odoo/` - proyecto base listo para copiar (misma configuración;
  todos los nombres/credenciales son placeholders que se sobrescriben en `.env`)

## Qué significa "configuración de depuración"

Depurar un contenedor de la imagen oficial se hace con **forward attach**:

1. El contenedor ejecuta Odoo bajo `debugpy` y *escucha* en el puerto `5678`.
2. VS Code / VSCodium se conecta a `localhost:5678` y se detiene en tus
   breakpoints.

Dos peculiaridades de Odoo se manejan automáticamente:

- **El modo `reload` de dev mata el depurador.** La opción `reload` de
  `--dev` re-ejecuta el proceso vía `os.execve` en cuanto cambia un archivo
  `.py`; eso destruye la sesión de debugpy. En modo debug, el entrypoint
  reemplaza `--dev=all` por `--dev=xml,qweb` (se conserva el auto-reload de
  xml/qweb).
- **Los breakpoints del núcleo requieren un espejo del código fuente.** El
  núcleo de Odoo solo vive dentro de la imagen
  (`/usr/lib/python3/dist-packages/odoo`). `refresh_odoo_src.sh` copia el
  código fuente exacto que está corriendo (solo archivos `.py`) a
  `./odoo-src`, que `launch.json` mapea vía `pathMappings` — así puedes
  entrar paso a paso en `models.py`, `fields.py`, herencias de módulos base,
  etc.

## Requisitos

- Docker Engine (Compose v2) en Linux (también funciona con Docker Desktop en
  macOS/Windows; el puerto `5678` se publica hacia el host).
- VS Code o VSCodium con la extensión de Python (`ms-python.python`).

## Uso

### Opción A - Generar un proyecto nuevo (recomendado)

```bash
./create-odoo-project.sh -n mi-proyecto -v 17.0
cd mi-proyecto
docker compose up -d
```

Opciones: `-n|--name`, `-v|--version`, `-d|--db`, `-p|--port`, `--dbport`,
`--debug codium|pycharm|none`, `-i` (interactivo), `-h`.

### Opción B - Copiar la plantilla base

```bash
cp -r base-docker-odoo mi-proyecto && cd mi-proyecto
docker compose up -d
```

## Flujo de depuración

```bash
# 1. Iniciar Odoo en pausa esperando al depurador
DEBUGPY=1 docker compose up -d odoo
```

```text
>>> [debugpy] Odoo debugger listening on 0.0.0.0:5678. Start 'Attach to Odoo (Docker)' in VS Code.
>>> [debugpy] Waiting for VS Code to attach before starting Odoo ...
```

```text
# 2. En VS Code / Codium
#    Depurar: Seleccionar e iniciar depuración  ->  "Attach to Odoo (Docker)"
```

3. Odoo arranca y se detiene en tus breakpoints.

Dónde puedes poner breakpoints:

- tus addons en `custom/` → mapeado a `/mnt/extra-addons`
- el código del núcleo de Odoo en `odoo-src/` → mapeado a
  `/usr/lib/python3/dist-packages/odoo` (ejecuta `./refresh_odoo_src.sh`
  primero; repítelo tras actualizar la imagen)

### Volver al modo normal / reiniciar

```bash
docker compose up -d odoo        # DEBUGPY=0 -> modo normal (--dev=all)
docker compose restart odoo      # durante una sesión de debug, recarga cambios de python
```

## Ajustes de depuración (`.env`)

| Variable | Por defecto | Descripción |
|----------|-------------|-------------|
| `DEBUGPY` | `0` | `1` = ejecuta Odoo bajo el depurador |
| `DEBUGPY_PORT` | `5678` | puerto en el que escucha el contenedor |
| `DEBUGPY_WAIT` | `1` | `1` = pausa al arrancar hasta conectarse; `0` = arranca de inmediato, pausa solo en los breakpoints |

## Solución de problemas

**"El depurador no se conecta nunca" / VS Code dice esperando para siempre**
- Asegúrate de que ninguna otra sesión de depuración de VS Code / Codium (o un
  proceso `debugpy adapter` huérfano) tenga ocupado el puerto `5678` del host.
  Comprueba con `ss -tlnp | grep 5678` y cierra la sesión / mata el PID.
- Confirma que el contenedor imprimió
  `>>> [debugpy] ... listening` en `docker compose logs odoo`.

**Los breakpoints del núcleo no se resuelven** → los números de línea cambian
tras actualizar la imagen. Vuelve a ejecutar `./refresh_odoo_src.sh` (los
archivos se copian tal cual desde el contenedor en ejecución, así que
coinciden exactamente).

**El contenedor no arranca en modo debug** → revisa `docker compose logs
odoo`; si el debug entrypoint nunca se ejecuta, tu imagen puede ser anterior a
la instalación de `debugpy`: reconstruye con `docker compose build odoo`.

**PyCharm** → aún no está implementado; con `--debug pycharm` se genera un
placeholder (`config/pycharm_debug_TODO.md`).

## Archivos

| Archivo | Propósito |
|---------|-----------|
| `create-odoo-project.sh` | generador de proyectos |
| `base-docker-odoo/` | proyecto base copiable |
| `base-docker-odoo/debug_entrypoint.sh` | alterna modo normal vs depuración; elimina `reload` en modo debug |
| `base-docker-odoo/debug_launcher.py` | `debugpy.listen` y luego arranca Odoo |
| `base-docker-odoo/refresh_odoo_src.sh` | refleja el código fuente exacto del núcleo en `odoo-src/` |
| `base-docker-odoo/.vscode/launch.json` | `Attach to Odoo (Docker)` + path mappings |