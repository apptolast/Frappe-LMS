# CLAUDE.md - Guía para desarrollo en Frappe-LMS

## 🏗️ Estructura del Proyecto

```
Frappe-LMS/
├── lms/                    # App principal de Frappe LMS
├── frontend/               # Frontend Vue.js
├── frappe-ui/              # Componentes UI de Frappe
├── k8s/                    # Configuración de Kubernetes
├── docker/                 # Configuración de Docker
├── cypress/                # Tests E2E
└── .github/workflows/      # GitHub Actions CI/CD
```

## ⚠️ ARCHIVOS SENSIBLES - NO COMMITEAR

Los siguientes archivos están en `.gitignore` y **NUNCA** deben ser commiteados:

```
k8s/01-secret.yaml          # Contiene credenciales de BD, PayPal, etc.
.env                        # Variables de entorno
*.pem, *.key, *.crt         # Certificados
secrets/                    # Directorio de secretos
credentials/                # Directorio de credenciales
```

### Manejo de Credenciales

1. **Kubernetes Secrets**: Las credenciales se almacenan en `k8s/01-secret.yaml` (ignorado en git)
2. **Template disponible**: Usar `k8s/01-secret.yaml.example` como referencia
3. **Inyección en runtime**: Las credenciales se inyectan desde env vars al iniciar el contenedor

## 🚀 Flujo de CI/CD

### GitHub Actions (`.github/workflows/docker-build-push.yml`)

**Triggers:**
- Push a branch `apptolast`
- Excluye cambios en: `k8s/**`, `*.md`, `.gitignore`

**Acciones:**
1. Build imagen Docker
2. Push a Docker Hub: `apptolast/frappe-lms:latest`
3. Tag con SHA del commit

### Kubernetes

**CronJob `image-updater`**: Cada 12 horas hace rollout restart para obtener la última imagen.

**Aplicar cambios manualmente:**
```bash
kubectl apply -f k8s/
kubectl -n apptolast-frappe-lms rollout restart deployment/frappe-lms
```

## 🔧 Configuración del Servidor

### Puertos en el Pod frappe-lms

| Puerto | Servicio | Descripción |
|--------|----------|-------------|
| 80     | nginx    | Proxy reverso, assets estáticos |
| 8000   | gunicorn | API de Frappe |
| 9000   | socketio | Realtime/WebSocket |

### Traefik IngressRoute

- Host: `academy.apptolast.com`
- TLS: Certificado en `frappe-lms-tls`
- Sticky sessions para WebSocket

## 📝 Comandos Útiles

```bash
# Ver logs
kubectl -n apptolast-frappe-lms logs -l app=frappe-lms -c frappe-lms -f

# Exec en el pod
kubectl -n apptolast-frappe-lms exec -it $(kubectl -n apptolast-frappe-lms get pods -l app=frappe-lms -o jsonpath='{.items[0].metadata.name}') -c frappe-lms -- bash

# Verificar configuración
kubectl -n apptolast-frappe-lms get all

# Forzar redespliegue
kubectl -n apptolast-frappe-lms rollout restart deployment/frappe-lms
```

## 🔒 Seguridad

1. **NUNCA** commitear credenciales en el código
2. Usar Kubernetes Secrets para información sensible
3. El archivo `k8s/01-secret.yaml` SIEMPRE debe estar en `.gitignore`
4. Verificar con `git status` antes de commitear
5. Si se exponen credenciales accidentalmente, **rotarlas inmediatamente**

## 🌐 URLs

- **Producción**: https://academy.apptolast.com
- **Docker Hub**: https://hub.docker.com/r/apptolast/frappe-lms
- **GitHub**: https://github.com/apptolast/Frappe-LMS

## 🐛 Problemas Comunes

### Mixed Content
- Asegurar que nginx usa `proxy_redirect http:// https://`
- Verificar `X-Forwarded-Proto: https` en headers

### WebSocket no conecta
- Verificar que socketio está corriendo en puerto 9000
- Sticky sessions deben estar activas en Traefik
- Comprobar logs del contenedor

### PayPal validation fails
- Verificar credenciales en `k8s/01-secret.yaml`
- Usar credenciales NVP/SOAP (no REST API)
- En sandbox usar `Use Sandbox: true`
