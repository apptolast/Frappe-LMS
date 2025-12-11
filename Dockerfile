# ============================================
# Frappe LMS Docker Image
# Basado en el workflow oficial de frappe_docker
# ============================================
ARG FRAPPE_BRANCH=version-15

# ============================================
# Stage 1: Build stage
# ============================================
FROM frappe/build:${FRAPPE_BRANCH} AS builder

ARG FRAPPE_BRANCH=version-15
ARG FRAPPE_PATH=https://github.com/frappe/frappe

USER root

# Crear directorio para apps.json
RUN mkdir -p /opt/frappe

USER frappe

# Copiar el código de la aplicación LMS
COPY --chown=frappe:frappe . /tmp/lms-app

# Inicializar bench con Frappe
RUN bench init \
    --frappe-branch=${FRAPPE_BRANCH} \
    --frappe-path=${FRAPPE_PATH} \
    --no-procfile \
    --no-backups \
    --skip-redis-config-generation \
    --verbose \
    /home/frappe/frappe-bench

WORKDIR /home/frappe/frappe-bench

# Instalar la aplicación LMS desde el código local
RUN bench get-app /tmp/lms-app --skip-assets

# Configurar el site
RUN echo "{}" > sites/common_site_config.json

# Limpiar directorios .git para reducir tamaño
RUN find apps -mindepth 1 -path "*/.git" | xargs rm -fr

# Build de assets
RUN bench build --app lms

# ============================================
# Stage 2: Runtime stage
# ============================================
FROM frappe/base:${FRAPPE_BRANCH} AS backend

LABEL maintainer="AppToLast <info@apptolast.com>"
LABEL description="Frappe LMS - Learning Management System"
LABEL org.opencontainers.image.source="https://github.com/apptolast/frappe-lms"

USER frappe

COPY --from=builder --chown=frappe:frappe /home/frappe/frappe-bench /home/frappe/frappe-bench

WORKDIR /home/frappe/frappe-bench

# Volúmenes para datos persistentes
VOLUME [ \
  "/home/frappe/frappe-bench/sites", \
  "/home/frappe/frappe-bench/logs" \
]

# Puerto de la aplicación
EXPOSE 8000

# Comando por defecto: Gunicorn
CMD [ \
  "/home/frappe/frappe-bench/env/bin/gunicorn", \
  "--chdir=/home/frappe/frappe-bench/sites", \
  "--bind=0.0.0.0:8000", \
  "--threads=4", \
  "--workers=2", \
  "--worker-class=gthread", \
  "--worker-tmp-dir=/dev/shm", \
  "--timeout=120", \
  "--preload", \
  "frappe.app:application" \
]
