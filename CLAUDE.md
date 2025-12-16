# CLAUDE.md - Guía Completa para Frappe-LMS (AppToLast Academy)

---

## ⚠️ REGLAS CRÍTICAS PARA EL ASISTENTE (CLAUDE/AI)

### 🚨 ANTES DE CADA RESPUESTA - OBLIGATORIO:

1. **CONSULTAR DOCUMENTACIÓN OFICIAL** del stack tecnológico:
   - Frappe Framework: https://frappeframework.com/docs
   - Frappe LMS: https://github.com/frappe/lms
   - Socket.IO: https://socket.io/docs/v4/
   - Traefik: https://doc.traefik.io/traefik/
   - Kubernetes: https://kubernetes.io/docs/
   - Nginx: https://nginx.org/en/docs/
   - PayPal NVP/SOAP API: https://developer.paypal.com/docs/nvp-soap-api/

2. **NO INVENTAR NADA** - Si no estás seguro, busca en la documentación oficial
3. **NO ALUCINAR** - No generar código o configuración sin base documental
4. **VERIFICAR** que los cambios propuestos son consistentes con el stack

### 🔒 SEGURIDAD - INFORMACIÓN SENSIBLE (MÁXIMA PRIORIDAD):

**ANTES de hacer cualquier commit:**
```bash
# SIEMPRE verificar que no hay credenciales
git diff --cached | grep -iE "(password|secret|key|token|credential|api_key)"

# SIEMPRE verificar archivos staged
git status

# SIEMPRE verificar que archivos sensibles están ignorados
git check-ignore k8s/01-secret.yaml  # Debe mostrar el archivo
```

**Archivos que NUNCA deben commitearse:**
```
k8s/01-secret.yaml          # Credenciales de BD, PayPal, encryption_key
.env, .env.local, .env.*    # Variables de entorno
*.pem, *.key, *.crt         # Certificados SSL
secrets/, credentials/      # Directorios de secretos
site_config.json            # Contiene credenciales del site
```

**Si se exponen credenciales accidentalmente:**
1. **INMEDIATAMENTE** rotar las credenciales expuestas
2. Usar `git reset --soft` para reescribir historia
3. `git push --force` para eliminar del remoto
4. Documentar el incidente

---

## 🏗️ Stack Tecnológico

### Backend
| Tecnología | Versión | Documentación |
|------------|---------|---------------|
| **Frappe Framework** | v15 | https://frappeframework.com/docs |
| **Python** | ≥3.10 | https://docs.python.org/3.10/ |
| **MariaDB** | 10.x | https://mariadb.com/kb/en/documentation/ |
| **Redis** | Alpine | https://redis.io/docs/ |
| **Gunicorn** | 23.x | https://docs.gunicorn.org/ |
| **Socket.IO** | Node.js | https://socket.io/docs/v4/ |

### Frontend
| Tecnología | Uso | Documentación |
|------------|-----|---------------|
| **Vue.js 3** | SPA Frontend | https://vuejs.org/guide/ |
| **Frappe UI** | Componentes | https://frappeui.com/ |
| **Vite** | Build tool | https://vitejs.dev/guide/ |

### Infraestructura
| Tecnología | Uso | Documentación |
|------------|-----|---------------|
| **Kubernetes** | Orquestación | https://kubernetes.io/docs/ |
| **Traefik** | Ingress/LB | https://doc.traefik.io/traefik/ |
| **Docker** | Contenedores | https://docs.docker.com/ |
| **Nginx** | Reverse Proxy | https://nginx.org/en/docs/ |
| **Cert-Manager** | TLS Certs | https://cert-manager.io/docs/ |

### Pagos
| Gateway | API | Documentación |
|---------|-----|---------------|
| **PayPal** | NVP/SOAP (NO REST) | https://developer.paypal.com/docs/nvp-soap-api/ |
| **Razorpay** | REST API | https://razorpay.com/docs/api/ |

---

## 📁 Estructura del Proyecto

```
Frappe-LMS/
├── lms/                        # App principal de Frappe LMS
│   ├── lms/                    # Módulo Python principal
│   │   ├── doctype/            # DocTypes (modelos)
│   │   ├── www/                # Páginas web
│   │   └── api/                # APIs
│   └── public/                 # Assets estáticos
│
├── frontend/                   # Frontend Vue.js 3
│   ├── src/
│   │   ├── components/         # Componentes Vue
│   │   ├── pages/              # Páginas/Vistas
│   │   └── router/             # Vue Router
│   ├── package.json
│   └── vite.config.js
│
├── frappe-ui/                  # Submódulo de componentes UI
│
├── k8s/                        # Configuración Kubernetes
│   ├── 00-namespace.yaml       # Namespace
│   ├── 01-secret.yaml          # 🔒 SENSIBLE - NO COMMITEAR
│   ├── 01-secret.yaml.example  # Template para secretos
│   ├── 02-configmap.yaml       # Configuración no sensible
│   ├── 03-storage.yaml         # PersistentVolumeClaims
│   ├── 04-mariadb.yaml         # StatefulSet MariaDB
│   ├── 05-redis.yaml           # Deployment Redis
│   ├── 06-deployment.yaml      # Deployment principal
│   ├── 07-service.yaml         # Services
│   ├── 08-certificate.yaml     # Cert-manager Certificate
│   ├── 09-ingressroute.yaml    # Traefik IngressRoute
│   ├── 10-image-updater-cronjob.yaml  # CronJob actualización
│   ├── 11-nginx-configmap.yaml # Configuración Nginx
│   ├── deploy.sh               # Script de despliegue
│   └── undeploy.sh             # Script de eliminación
│
├── .github/workflows/          # GitHub Actions
│   ├── docker-build-push.yml   # Build y push a Docker Hub
│   ├── ci.yml                  # Tests de servidor
│   ├── ui-tests.yml            # Tests Cypress
│   └── linters.yml             # Linting
│
├── cypress/                    # Tests E2E
├── docker/                     # Configuración Docker adicional
├── Dockerfile                  # Imagen Docker personalizada
├── pyproject.toml              # Dependencias Python
├── package.json                # Dependencias Node.js
└── CLAUDE.md                   # Este archivo
```

---

## 🚀 Flujo de CI/CD

### GitHub Actions

#### `docker-build-push.yml` (Principal)
```yaml
Triggers:
  - push a: main, apptolast, develop
  - Ignora: k8s/**, **.md, .gitignore

Acciones:
  1. Build imagen Docker multi-arch
  2. Push a Docker Hub: apptolast/frappe-lms
  3. Tags: latest, branch-name, git-sha
```

#### Ejecutar manualmente:
```bash
# Desde GitHub UI: Actions > Build and Push Docker Image > Run workflow

# O con gh CLI:
gh workflow run docker-build-push.yml --ref apptolast
```

### Kubernetes - Actualización Automática

**CronJob `image-updater`**: Ejecuta cada 12 horas
```bash
# Ver estado del cronjob
kubectl -n apptolast-frappe-lms get cronjob

# Ejecutar manualmente
kubectl -n apptolast-frappe-lms create job --from=cronjob/image-updater manual-update
```

### Despliegue Manual
```bash
# Aplicar todos los manifiestos
kubectl apply -f k8s/

# Forzar redespliegue
kubectl -n apptolast-frappe-lms rollout restart deployment/frappe-lms
kubectl -n apptolast-frappe-lms rollout restart deployment/frappe-lms-worker
kubectl -n apptolast-frappe-lms rollout restart deployment/frappe-lms-scheduler

# Ver estado
kubectl -n apptolast-frappe-lms rollout status deployment/frappe-lms
```

---

## 🔧 Arquitectura del Pod frappe-lms

```
┌─────────────────────────────────────────────────────────────┐
│                    Pod: frappe-lms                          │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────────────────────┐   │
│  │   nginx (:80)   │  │      frappe-lms container       │   │
│  │                 │  │  ┌─────────────┐ ┌───────────┐  │   │
│  │  /assets → static  │  gunicorn    │ │ socketio  │  │   │
│  │  /socket.io → :9000│  │   (:8000)   │ │  (:9000)  │  │   │
│  │  /* → :8000     │  │  └─────────────┘ └───────────┘  │   │
│  └─────────────────┘  └─────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                 Service: frappe-lms                         │
│                    Port: 8000 → 80                          │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              Traefik IngressRoute                           │
│         Host: academy.apptolast.com                         │
│         TLS: frappe-lms-tls (cert-manager)                  │
│         Sticky sessions: frappe_session cookie              │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔐 Configuración de Credenciales

### PayPal Sandbox (NVP/SOAP API)

**IMPORTANTE**: Frappe Payments usa la API NVP/SOAP de PayPal, NO la REST API.

Credenciales requeridas (de PayPal Developer Dashboard > Sandbox > NVP/SOAP):
- `API Username`: ej. `sb-xxxxx_api1.business.example.com`
- `API Password`: ej. `YOUR_API_PASSWORD`
- `Signature`: ej. `YOUR_SIGNATURE_HERE...`

**Configuración en `k8s/01-secret.yaml`:**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: frappe-lms-secret
  namespace: apptolast-frappe-lms
type: Opaque
stringData:
  PAYPAL_SANDBOX_USERNAME: "sb-xxxxx_api1.business.example.com"
  PAYPAL_SANDBOX_PASSWORD: "YOUR_PASSWORD"
  PAYPAL_SANDBOX_SIGNATURE: "YOUR_SIGNATURE"
```

### Inyección de Credenciales en Runtime

Las credenciales se inyectan al iniciar el contenedor (ver `06-deployment.yaml`):
```bash
# El script de inicio lee las env vars y las escribe en site_config.json
python3 -c "
import json, os
with open('site_config.json', 'r') as f:
    c = json.load(f)
c['sandbox_api_username'] = os.environ.get('PAYPAL_SANDBOX_USERNAME', '')
c['sandbox_api_password'] = os.environ.get('PAYPAL_SANDBOX_PASSWORD', '')
c['sandbox_signature'] = os.environ.get('PAYPAL_SANDBOX_SIGNATURE', '')
with open('site_config.json', 'w') as f:
    json.dump(c, f, indent=2)
"
```

---

## 📝 Comandos Útiles

### Kubernetes
```bash
# Ver todos los recursos
kubectl -n apptolast-frappe-lms get all

# Logs en tiempo real
kubectl -n apptolast-frappe-lms logs -l app=frappe-lms -c frappe-lms -f

# Logs de nginx
kubectl -n apptolast-frappe-lms logs -l app=frappe-lms -c nginx -f

# Exec en el pod
kubectl -n apptolast-frappe-lms exec -it $(kubectl -n apptolast-frappe-lms get pods -l app=frappe-lms -o jsonpath='{.items[0].metadata.name}') -c frappe-lms -- bash

# Ver site_config
kubectl -n apptolast-frappe-lms exec $(kubectl -n apptolast-frappe-lms get pods -l app=frappe-lms -o jsonpath='{.items[0].metadata.name}') -c frappe-lms -- cat /home/frappe/frappe-bench/sites/lms.localhost/site_config.json

# Reiniciar deployment
kubectl -n apptolast-frappe-lms rollout restart deployment/frappe-lms
```

### Frappe Bench (dentro del contenedor)
```bash
# Activar entorno virtual
source /home/frappe/frappe-bench/env/bin/activate

# Ejecutar comando bench
cd /home/frappe/frappe-bench
bench --site lms.localhost console

# Migrar
bench --site lms.localhost migrate

# Limpiar caché
bench --site lms.localhost clear-cache
```

### Git (antes de commitear)
```bash
# SIEMPRE verificar
git status
git diff --cached | grep -iE "(password|secret|key|token)"
git check-ignore k8s/01-secret.yaml
```

---

## 🐛 Solución de Problemas Comunes

### Mixed Content Error
**Síntoma**: `Mixed Content: The page was loaded over HTTPS, but requested an insecure resource`

**Solución**:
1. Verificar `proxy_redirect http:// https://` en nginx config
2. Verificar `X-Forwarded-Proto: https` en headers
3. Verificar `host_name: https://...` en site_config.json

### WebSocket Connection Closed
**Síntoma**: `WebSocket is closed before the connection is established`

**Solución**:
1. Verificar `allow_cors` en site_config.json
2. Verificar sticky sessions en Traefik IngressRoute
3. Verificar que socketio está corriendo en puerto 9000
4. Verificar `FRAPPE_SITE_NAME_HEADER` env var

### PayPal Validation Error
**Síntoma**: `Invalid payment gateway credentials`

**Solución**:
1. Usar credenciales NVP/SOAP (NO REST API)
2. Verificar que están en `k8s/01-secret.yaml`
3. Reiniciar el deployment para recargar credenciales
4. En sandbox, marcar `Use Sandbox: true`

### Socket.IO 404
**Síntoma**: `GET /socket.io/?EIO=4&transport=polling 404`

**Solución**:
1. Verificar que nginx proxy `/socket.io` al puerto 9000
2. Verificar que el proceso socketio está corriendo
3. Ver logs: `kubectl logs -l app=frappe-lms -c frappe-lms | grep socketio`

---

## 🌐 URLs y Recursos

| Recurso | URL |
|---------|-----|
| **Producción** | https://academy.apptolast.com |
| **Docker Hub** | https://hub.docker.com/r/apptolast/frappe-lms |
| **GitHub Repo** | https://github.com/apptolast/Frappe-LMS |
| **Frappe Docs** | https://frappeframework.com/docs |
| **LMS Original** | https://github.com/frappe/lms |
| **PayPal Sandbox** | https://developer.paypal.com/dashboard/applications/sandbox |

---

## 📋 Checklist Pre-Commit

- [ ] `git status` - Verificar archivos staged
- [ ] `git diff --cached` - Revisar cambios
- [ ] No hay credenciales en el diff
- [ ] `k8s/01-secret.yaml` NO está staged
- [ ] Los cambios tienen sentido con la documentación oficial
- [ ] Tests pasan (si aplica)

---

## 🔄 Actualizado

- **Fecha**: 2025-12-16
- **Commit**: Ver `git log --oneline -1`
- **Autor**: AppToLast Team
