#!/usr/bin/env fish
#
# Script para eliminar el cluster de GKE y evitar costos
#

set GREEN (set_color green)
set YELLOW (set_color yellow)
set RED (set_color red)
set BLUE (set_color blue)
set NORMAL (set_color normal)

echo "$RED========================================================$NORMAL"
echo "$RED        ELIMINAR CLUSTER GKE - EVITAR COSTOS         $NORMAL"
echo "$RED========================================================$NORMAL"

# Obtener configuración actual
set PROJECT_ID (gcloud config get-value project 2>/dev/null)
set ZONE "us-central1-a"
set CLUSTER_NAME "todo-app-cluster"

echo "$YELLOW Configuración actual:$NORMAL"
echo "  Project ID:    $PROJECT_ID"
echo "  Zone:          $ZONE"
echo "  Cluster Name:  $CLUSTER_NAME"
echo ""

# Verificar si el cluster existe
echo "$YELLOW Verificando si el cluster existe...$NORMAL"
if gcloud container clusters describe $CLUSTER_NAME --zone=$ZONE > /dev/null 2>&1
    echo "$GREEN ✓ Cluster encontrado$NORMAL"
    echo ""
    
    # Mostrar información del cluster
    echo "$YELLOW Información del cluster:$NORMAL"
    gcloud container clusters describe $CLUSTER_NAME --zone=$ZONE --format="table(name,location,currentMasterVersion,currentNodeCount,status)"
    echo ""
    
    # Calcular costo estimado
    echo "$RED ⚠️  IMPORTANTE: Costos estimados mensuales$NORMAL"
    echo "  - GKE Cluster management: ~\$74/mes"
    echo "  - Load Balancer: ~\$18/mes"
    echo "  - Compute nodes: Según uso"
    echo ""
else
    echo "$YELLOW ⚠ No se encontró el cluster '$CLUSTER_NAME' en la zona '$ZONE'$NORMAL"
    echo ""
    echo "Clusters disponibles:"
    gcloud container clusters list
    exit 0
end

# Preguntar antes de eliminar
echo "$RED========================================================$NORMAL"
echo "$RED                   ⚠️  ADVERTENCIA                     $NORMAL"
echo "$RED========================================================$NORMAL"
echo ""
echo "Esta acción eliminará:"
echo "  ❌ El cluster GKE completo"
echo "  ❌ Todos los pods y deployments"
echo "  ❌ Todos los servicios y Load Balancers"
echo "  ❌ Los datos en la base de datos (si no está en volumen externo)"
echo ""
echo "$YELLOW Esta acción NO se puede deshacer.$NORMAL"
echo ""

read -P "$RED ¿Estás SEGURO de que quieres eliminar el cluster? [y/N]: $NORMAL" confirm
echo ""

if not test "$confirm" = "y" -o "$confirm" = "Y"
    echo "$GREEN ✓ Operación cancelada. El cluster NO fue eliminado.$NORMAL"
    exit 0
end

# Segunda confirmación
read -P "$RED Escribe 'DELETE' para confirmar la eliminación: $NORMAL" confirm2
echo ""

if not test "$confirm2" = "DELETE"
    echo "$GREEN ✓ Operación cancelada. El cluster NO fue eliminado.$NORMAL"
    exit 0
end

# Eliminar el cluster
echo ""
echo "$YELLOW Eliminando el cluster...$NORMAL"
echo "$YELLOW (Esto puede tardar 5-10 minutos)$NORMAL"
echo ""

gcloud container clusters delete $CLUSTER_NAME \
    --zone=$ZONE \
    --quiet

if test $status -eq 0
    echo ""
    echo "$GREEN========================================================$NORMAL"
    echo "$GREEN           ✓ CLUSTER ELIMINADO EXITOSAMENTE          $NORMAL"
    echo "$GREEN========================================================$NORMAL"
    echo ""
    echo "$GREEN Ya no se generarán costos por el cluster GKE.$NORMAL"
    echo ""
    echo "$YELLOW Otros recursos a verificar:$NORMAL"
    echo ""
    echo "1. Load Balancers huérfanos:"
    echo "   $BLUE gcloud compute forwarding-rules list$NORMAL"
    echo ""
    echo "2. Discos persistentes huérfanos:"
    echo "   $BLUE gcloud compute disks list$NORMAL"
    echo ""
    echo "3. Direcciones IP estáticas reservadas:"
    echo "   $BLUE gcloud compute addresses list$NORMAL"
    echo ""
    echo "4. Revisar costos en:"
    echo "   $BLUE https://console.cloud.google.com/billing$NORMAL"
    echo ""
else
    echo ""
    echo "$RED✗ Error al eliminar el cluster$NORMAL"
    echo ""
    echo "Intenta manualmente:"
    echo "$YELLOW  gcloud container clusters delete $CLUSTER_NAME --zone=$ZONE$NORMAL"
    echo ""
    exit 1
end
