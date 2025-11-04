#!/usr/bin/env fish

# Script para recrear el cluster GKE con la configuración correcta
# Este script usa los valores de ansible/group_vars/all.yml

set -x PROJECT_ID ansible-project-475919
set -x CLUSTER_NAME todo-app-cluster
set -x REGION us-central1
set -x MACHINE_TYPE e2-small
set -x DISK_SIZE 20
set -x NUM_NODES 2
set -x MIN_NODES 2
set -x MAX_NODES 5

echo "🚀 Recreando cluster GKE con la configuración correcta..."
echo "   Proyecto: $PROJECT_ID"
echo "   Cluster: $CLUSTER_NAME"
echo "   Región: $REGION"
echo "   Tipo de máquina: $MACHINE_TYPE (2 vCPUs, 2 GB RAM)"
echo "   Nodos totales: $NUM_NODES"
echo "   Autoscaling: $MIN_NODES - $MAX_NODES nodos"
echo ""

# Verificar si el cluster ya existe
set cluster_exists (gcloud container clusters list \
    --project=$PROJECT_ID \
    --filter="name=$CLUSTER_NAME AND location=$REGION" \
    --format="value(name)" 2>/dev/null)

if test -n "$cluster_exists"
    echo "⚠️  El cluster '$CLUSTER_NAME' ya existe en $REGION"
    echo "   Estado actual:"
    gcloud container clusters describe $CLUSTER_NAME \
        --region=$REGION \
        --project=$PROJECT_ID \
        --format="table(status,currentNodeCount,currentNodeVersion)"
    echo ""
    echo "❌ Por favor elimina el cluster existente primero:"
    echo "   gcloud container clusters delete $CLUSTER_NAME --region=$REGION --project=$PROJECT_ID"
    exit 1
end

echo "✅ No existe cluster con ese nombre, procediendo a crear..."
echo ""

# Crear el cluster
# IMPORTANTE: --num-nodes 2 significa 2 nodos TOTALES en la región (no por zona)
# GKE distribuirá automáticamente: 1 nodo en zona A, 1 nodo en zona B
gcloud container clusters create $CLUSTER_NAME \
    --project=$PROJECT_ID \
    --region=$REGION \
    --machine-type=$MACHINE_TYPE \
    --disk-size=$DISK_SIZE \
    --disk-type=pd-standard \
    --num-nodes=$NUM_NODES \
    --enable-autoscaling \
    --min-nodes=$MIN_NODES \
    --max-nodes=$MAX_NODES \
    --enable-autorepair \
    --enable-autoupgrade \
    --release-channel=regular \
    --enable-ip-alias \
    --no-enable-cloud-logging \
    --no-enable-cloud-monitoring \
    --addons=HorizontalPodAutoscaling,HttpLoadBalancing

if test $status -eq 0
    echo ""
    echo "✅ Cluster creado exitosamente!"
    echo ""
    echo "📊 Información del cluster:"
    gcloud container clusters describe $CLUSTER_NAME \
        --region=$REGION \
        --project=$PROJECT_ID \
        --format="table(status,currentNodeCount,currentNodeVersion,endpoint)"
    
    echo ""
    echo "🔐 Obteniendo credenciales..."
    gcloud container clusters get-credentials $CLUSTER_NAME \
        --region=$REGION \
        --project=$PROJECT_ID
    
    echo ""
    echo "🎉 Listo! Ahora puedes usar kubectl:"
    echo "   kubectl get nodes"
    echo "   kubectl cluster-info"
else
    echo ""
    echo "❌ Error al crear el cluster"
    echo "   Verifica las cuotas de GCP: https://console.cloud.google.com/iam-admin/quotas?project=$PROJECT_ID"
    exit 1
end
