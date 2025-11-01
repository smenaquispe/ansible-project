#!/usr/bin/env fish
#
# Script wrapper para crear cluster GKE usando Ansible
#
# Uso:
#   ./create-cluster.fish
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

echo "$BLUE========================================================$NORMAL"
echo "$BLUE         CREAR CLUSTER GKE CON ANSIBLE                $NORMAL"
echo "$BLUE========================================================$NORMAL"
echo ""

# Verificar prerrequisitos
echo "$YELLOW Verificando prerrequisitos...$NORMAL"

if not command -q gcloud
    echo "$RED Error: gcloud CLI no está instalado$NORMAL"
    exit 1
end

if not command -q kubectl
    echo "$RED Error: kubectl no está instalado$NORMAL"
    exit 1
end

if not command -q ansible-playbook
    echo "$RED Error: ansible no está instalado$NORMAL"
    echo "Instala con: pip install ansible"
    exit 1
end

echo "$GREEN ✓ Todos los prerrequisitos cumplidos$NORMAL"
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
echo "$YELLOW Para cambiar la configuración, edita esos archivos.$NORMAL"
echo ""

# Verificar que el directorio existe
if not test -d "$ANSIBLE_DIR"
    echo "$RED Error: El directorio $ANSIBLE_DIR no existe$NORMAL"
    exit 1
end

# Ejecutar playbook de Ansible
cd "$ANSIBLE_DIR"

echo "$YELLOW Ejecutando playbook de Ansible...$NORMAL"
echo ""

ansible-playbook \
    -i inventory/hosts \
    playbooks/create-cluster.yml

if test $status -ne 0
    echo ""
    echo "$RED Error al ejecutar el playbook$NORMAL"
    exit 1
end

echo ""
echo "$GREEN========================================================$NORMAL"
echo "$GREEN         ✓ CLUSTER LISTO PARA USAR                   $NORMAL"
echo "$GREEN========================================================$NORMAL"
echo ""
echo "$YELLOW Siguiente paso:$NORMAL"
echo "  ./scripts/deploy.fish  # Para desplegar la aplicación"
echo ""
