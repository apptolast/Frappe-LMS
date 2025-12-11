# Despliegue de Frappe LMS en Kubernetes

Este directorio contiene los manifiestos de Kubernetes para desplegar Frappe LMS.

## Requisitos Previos

1. **Cluster Kubernetes** con:
   - Traefik como Ingress Controller
   - cert-manager con ClusterIssuer `cloudflare-clusterissuer` configurado
   - StorageClass `longhorn` disponible

2. **Docker Hub**: Imagen en `apptolast/frappe-lms:latest`

3. **Cloudflare**: Configurar DNS para `lms.apptolast.com`

## Estructura de Archivos

```
k8s/
├── 00-namespace.yaml         # Namespace para el proyecto
├── 01-secret.yaml            # Secrets (MODIFICAR antes de usar)
├── 02-configmap.yaml         # Configuración de Frappe
├── 03-storage.yaml           # PVCs para datos persistentes
├── 04-mariadb.yaml           # Base de datos MariaDB
├── 05-redis.yaml             # Cache Redis
├── 06-deployment.yaml        # Aplicación (web, worker, scheduler)
├── 07-service.yaml           # Servicio interno
├── 08-certificate.yaml       # Certificado TLS
├── 09-ingressroute.yaml      # IngressRoute de Traefik
├── 10-image-updater-cronjob.yaml  # Actualización automática
├── deploy.sh                 # Script de despliegue
└── undeploy.sh               # Script de eliminación
```

## Despliegue

### 1. Configurar Secrets

**IMPORTANTE**: Antes de desplegar, edita `01-secret.yaml` con valores seguros:

```bash
# Generar passwords seguros
openssl rand -base64 32  # Para MYSQL_ROOT_PASSWORD
openssl rand -base64 32  # Para FRAPPE_ADMIN_PASSWORD
openssl rand -hex 16     # Para ENCRYPTION_KEY
```

### 2. Configurar DNS en Cloudflare

Añade un registro A/CNAME en Cloudflare:
- **Nombre**: `lms`
- **Tipo**: `A` o `CNAME`
- **Contenido**: IP de tu cluster o dominio del Load Balancer
- **Proxy**: Activado (naranja) o Desactivado según prefieras

### 3. Ejecutar Despliegue

```bash
cd k8s
./deploy.sh
```

## Verificar Estado

```bash
# Ver todos los recursos
kubectl get all -n apptolast-frappe-lms

# Ver logs de la aplicación
kubectl logs -f deployment/frappe-lms -n apptolast-frappe-lms

# Ver estado de pods
kubectl get pods -n apptolast-frappe-lms -w

# Ver certificado
kubectl get certificate -n apptolast-frappe-lms
```

## Acceso

- **URL**: https://lms.apptolast.com
- **Usuario admin**: Administrator
- **Password**: El configurado en `01-secret.yaml`

## Actualizaciones Automáticas

El CronJob `image-updater` verifica cada 12 horas si hay una nueva imagen y hace rolling restart automático.

Para forzar una actualización manual:
```bash
kubectl create job --from=cronjob/image-updater manual-update -n apptolast-frappe-lms
```

## Eliminar

```bash
cd k8s
./undeploy.sh
```

## Troubleshooting

### La aplicación no inicia
```bash
# Ver logs del init container
kubectl logs deployment/frappe-lms -c site-init -n apptolast-frappe-lms

# Ver eventos
kubectl get events -n apptolast-frappe-lms --sort-by='.lastTimestamp'
```

### Problemas con base de datos
```bash
# Conectar a MariaDB
kubectl exec -it statefulset/mariadb-frappe-lms -n apptolast-frappe-lms -- mysql -u root -p
```

### Problemas con certificado
```bash
# Ver estado del certificado
kubectl describe certificate frappe-lms-tls -n apptolast-frappe-lms

# Ver logs de cert-manager
kubectl logs -n cert-manager deployment/cert-manager
```
