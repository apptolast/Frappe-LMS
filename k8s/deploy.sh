#!/bin/bash

# Script de despliegue para Frappe LMS en Kubernetes
# Ejecutar desde el directorio k8s/

set -e

NAMESPACE="apptolast-frappe-lms"

echo "=== Desplegando Frappe LMS ==="
echo ""

# Aplicar los manifiestos en orden
echo "1. Creando namespace..."
kubectl apply -f 00-namespace.yaml

echo ""
echo "2. Creando secrets (RECUERDA MODIFICAR LOS VALORES)..."
kubectl apply -f 01-secret.yaml

echo ""
echo "3. Creando configmaps..."
kubectl apply -f 02-configmap.yaml

echo ""
echo "4. Creando almacenamiento persistente..."
kubectl apply -f 03-storage.yaml

echo ""
echo "5. Desplegando MariaDB..."
kubectl apply -f 04-mariadb.yaml

echo ""
echo "Esperando a que MariaDB esté listo..."
kubectl wait --for=condition=ready pod -l app=mariadb-frappe-lms -n $NAMESPACE --timeout=120s

echo ""
echo "6. Desplegando Redis..."
kubectl apply -f 05-redis.yaml

echo ""
echo "Esperando a que Redis esté listo..."
kubectl wait --for=condition=ready pod -l app=redis-frappe-lms -n $NAMESPACE --timeout=60s

echo ""
echo "7. Desplegando aplicación Frappe LMS..."
kubectl apply -f 06-deployment.yaml

echo ""
echo "8. Creando servicio..."
kubectl apply -f 07-service.yaml

echo ""
echo "9. Creando certificado TLS..."
kubectl apply -f 08-certificate.yaml

echo ""
echo "10. Creando IngressRoute..."
kubectl apply -f 09-ingressroute.yaml

echo ""
echo "11. Creando CronJob para actualizaciones automáticas..."
kubectl apply -f 10-image-updater-cronjob.yaml

echo ""
echo "=== Despliegue completado ==="
echo ""
echo "Verificando estado del deployment..."
kubectl get all -n $NAMESPACE

echo ""
echo "Para ver los logs de la aplicación:"
echo "  kubectl logs -f deployment/frappe-lms -n $NAMESPACE"
echo ""
echo "Para ver el estado de los pods:"
echo "  kubectl get pods -n $NAMESPACE -w"
echo ""
echo "URL de acceso: https://lms.apptolast.com"
