# ============================================
# Frappe LMS Docker Image
# Utiliza el método oficial de frappe_docker
# ============================================
ARG FRAPPE_BRANCH=version-15

# ============================================
# Stage 1: Build stage
# ============================================
FROM frappe/build:${FRAPPE_BRANCH} AS builder

ARG FRAPPE_BRANCH=version-15
ARG FRAPPE_PATH=https://github.com/frappe/frappe
# URL del repositorio LMS - usamos la versión de apptolast
ARG LMS_REPO=https://github.com/apptolast/Frappe-LMS
ARG LMS_BRANCH=apptolast

USER root

# Crear directorio para apps.json
# Orden de apps: payments, erpnext, lms, education
# (erpnext es requerido por education según documentación oficial)
RUN mkdir -p /opt/frappe && \
    echo '[{"url": "https://github.com/frappe/payments", "branch": "version-15"}, {"url": "https://github.com/frappe/erpnext", "branch": "develop"}, {"url": "'${LMS_REPO}'", "branch": "'${LMS_BRANCH}'"}, {"url": "https://github.com/frappe/education", "branch": "develop"}]' > /opt/frappe/apps.json

USER frappe

# Inicializar bench con Frappe y la app LMS
RUN bench init \
    --apps_path=/opt/frappe/apps.json \
    --frappe-branch=${FRAPPE_BRANCH} \
    --frappe-path=${FRAPPE_PATH} \
    --no-procfile \
    --no-backups \
    --skip-redis-config-generation \
    --verbose \
    /home/frappe/frappe-bench

WORKDIR /home/frappe/frappe-bench

# Configurar el site
RUN echo "{}" > sites/common_site_config.json

# NOTA: Los assets se compilarán durante el primer arranque del pod
# porque el build en CI tiene limitaciones de memoria y tiempo.
# El init container ejecutará bench build si es necesario.

# Limpiar directorios .git para reducir tamaño
RUN find apps -mindepth 1 -path "*/.git" | xargs rm -fr

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
