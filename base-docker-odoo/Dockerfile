FROM odoo:17.0

# Install debugpy for remote debugging (debug_launcher.py).
# USER root is required because the base image runs pip as the 'odoo'
# user, which would install into /var/lib/odoo/.local (hidden by the
# odoo-web volume mounted at /var/lib/odoo).
# Pin ~=1.8 to stay compatible with the VS Code / VSCodium debug adapter.
USER root
RUN pip3 install --no-cache-dir --break-system-packages "debugpy~=1.8"
USER odoo

# Install additional dependencies
# RUN pip3 install --no-cache-dir --break-system-packages -r requirements.txt