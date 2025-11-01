#!/usr/bin/env fish
#
# Script wrapper para desplegar la aplicación usando Ansible
#
# Uso:
#   ./deploy.fish           # Deploy completo
#   ./deploy.fish --update  # Solo actualizar (redeploy)
#

set GREEN (set_color green)
set YELLOW (set_color yellow)
set RED (set_color red)
set BLUE (set_color blue)
set NORMAL (set_color normal)

# Configuración
set SCRIPT_DIR (dirname (status -f))
set PROJECT_ROOT (dirname $SCRIPT_DIR)
set ANSIBLE_DIR "$PROJECT_ROOT/ansible"
set UPDATE_MODE false

# Procesar argumentos
for arg in $argv
    if test "$arg" = "--update"
        set UPDATE_MODE true
    end
end

echo "$BLUE========================================================$NORMAL"
if test "$UPDATE_MODE" = "true"
    echo "$BLUE        REDESPLEGAR APP EN GKE CON ANSIBLE           $NORMAL"
else
    echo "$BLUE         DESPLEGAR APP EN GKE CON ANSIBLE             $NORMAL"
end
echo "$BLUE========================================================$NORMAL"
echo ""

# Verificar prerrequisitos
echo "$YELLOW Verificando prerrequisitos...$NORMAL"

if not command -q kubectl
    echo "$RED Error: kubectl no está instalado$NORMAL"
    exit 1
end

if not command -q ansible-playbook
    echo "$RED Error: ansible no está instalado$NORMAL"
    echo "Instala con: pip install ansible"
    exit 1
end

# Verificar conexión al cluster
echo "$YELLOW Verificando conexión al cluster...$NORMAL"
if not kubectl cluster-info > /dev/null 2>&1
    echo "$RED Error: No hay conexión al cluster$NORMAL"
    echo "Ejecuta primero: ./scripts/create-cluster.fish"
    exit 1
end

echo "$GREEN ✓ Conectado al cluster$NORMAL"
echo ""

# Verificar colección de Ansible
echo "$YELLOW Verificando colección kubernetes.core...$NORMAL"
if not ansible-galaxy collection list 2>/dev/null | grep -q "kubernetes.core"
    echo "$YELLOW Instalando colección kubernetes.core...$NORMAL"
    ansible-galaxy collection install kubernetes.core
end
echo "$GREEN ✓ Colección disponible$NORMAL"
echo ""

# Mostrar información
echo "$YELLOW La configuración se encuentra en:$NORMAL"
echo "  $ANSIBLE_DIR/group_vars/all.yml"
echo "  $ANSIBLE_DIR/group_vars/gcp.yml"
echo ""

# Verificar que el directorio existe
if not test -d "$ANSIBLE_DIR"
    echo "$RED Error: El directorio $ANSIBLE_DIR no existe$NORMAL"
    exit 1
end

cd "$ANSIBLE_DIR"

if test "$UPDATE_MODE" = "true"
    # Modo update: hacer rollout restart
    echo "$YELLOW Actualizando deployments (rollout restart)...$NORMAL"
    echo ""
    
    set NAMESPACE (grep "k8s_namespace:" group_vars/all.yml | awk '{print $2}')
    
    kubectl rollout restart deployment/todo-backend -n $NAMESPACE
    kubectl rollout restart deployment/todo-frontend -n $NAMESPACE
    kubectl rollout restart deployment/todo-db -n $NAMESPACE
    
    echo ""
    echo "$YELLOW Esperando a que los pods estén listos...$NORMAL"
    kubectl wait --for=condition=ready pod -l app=todo-backend -n $NAMESPACE --timeout=300s
    kubectl wait --for=condition=ready pod -l app=todo-frontend -n $NAMESPACE --timeout=300s
    kubectl wait --for=condition=ready pod -l app=todo-db -n $NAMESPACE --timeout=300s
    
    echo ""
    echo "$GREEN ✓ Actualización completada$NORMAL"
else
    # Modo deploy completo: ejecutar playbook
    echo "$YELLOW Ejecutando playbook de Ansible...$NORMAL"
    echo ""
    
    ansible-playbook \
        -i inventory/hosts \
        playbooks/deploy-gcp.yml
    
    if test $status -ne 0
        echo ""
        echo "$RED Error al ejecutar el playbook$NORMAL"
        exit 1
    end
end

echo ""
echo "$GREEN========================================================$NORMAL"
echo "$GREEN         ✓ DESPLIEGUE COMPLETADO                     $NORMAL"
echo "$GREEN========================================================$NORMAL"
echo ""

# Obtener namespace de la configuración
set NAMESPACE (grep "k8s_namespace:" $ANSIBLE_DIR/group_vars/all.yml | awk '{print $2}')

# Mostrar estado
echo "$YELLOW Estado de los pods:$NORMAL"
kubectl get pods -n $NAMESPACE
echo ""

echo "$YELLOW Servicios:$NORMAL"
kubectl get svc -n $NAMESPACE
echo ""

echo "$YELLOW Ingress:$NORMAL"
kubectl get ingress -n $NAMESPACE
echo ""

# Obtener IP externa
set EXTERNAL_IP (kubectl get ingress todo-app-ingress -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)

if test -n "$EXTERNAL_IP"
    echo "$GREEN========================================================$NORMAL"
    echo "$GREEN           APLICACIÓN DISPONIBLE EN:                 $NORMAL"
    echo "$GREEN========================================================$NORMAL"
    echo ""
    echo "$BLUE  http://$EXTERNAL_IP$NORMAL"
    echo ""
else
    echo "$YELLOW El Load Balancer aún está provisionando...$NORMAL"
    echo "Ejecuta este comando en unos minutos para obtener la IP:"
    echo "$BLUE  kubectl get ingress -n $NAMESPACE$NORMAL"
    echo ""
end

# Comandos útiles
echo "$YELLOW Comandos útiles:$NORMAL"
echo ""
echo "Ver logs del backend:"
echo "  $BLUE kubectl logs -l app=todo-backend -n $NAMESPACE --tail=50 -f$NORMAL"
echo ""
echo "Ver logs del frontend:"
echo "  $BLUE kubectl logs -l app=todo-frontend -n $NAMESPACE --tail=50 -f$NORMAL"
echo ""
echo "Actualizar/redesplegar:"
echo "  $BLUE ./scripts/deploy.fish --update$NORMAL"
echo ""
echo "Ver todos los recursos:"
echo "  $BLUE kubectl get all -n $NAMESPACE$NORMAL"
echo ""
