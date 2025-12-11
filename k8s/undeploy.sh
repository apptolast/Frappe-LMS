#!/bin/bash

# Script para eliminar el despliegue de Frappe LMS

set -e

NAMESPACE="apptolast-frappe-lms"

echo "=== Eliminando Frappe LMS ==="
echo ""
echo "ADVERTENCIA: Esto eliminará todos los recursos del namespace $NAMESPACE"
echo "Los datos persistentes (PVCs) se mantendrán por seguridad."
echo ""
read -p "¿Estás seguro? (y/N): " confirm

if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "Operación cancelada."
    exit 0
fi

echo ""
echo "Eliminando recursos..."

kubectl delete -f 10-image-updater-cronjob.yaml --ignore-not-found
kubectl delete -f 09-ingressroute.yaml --ignore-not-found
kubectl delete -f 08-certificate.yaml --ignore-not-found
kubectl delete -f 07-service.yaml --ignore-not-found
kubectl delete -f 06-deployment.yaml --ignore-not-found
kubectl delete -f 05-redis.yaml --ignore-not-found
kubectl delete -f 04-mariadb.yaml --ignore-not-found
kubectl delete -f 02-configmap.yaml --ignore-not-found
kubectl delete -f 01-secret.yaml --ignore-not-found

echo ""
echo "Los PVCs no se han eliminado. Para eliminarlos manualmente:"
echo "  kubectl delete -f 03-storage.yaml"
echo ""
echo "Para eliminar el namespace completo (incluyendo PVCs):"
echo "  kubectl delete namespace $NAMESPACE"
echo ""
echo "=== Eliminación completada ==="
