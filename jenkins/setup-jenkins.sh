#!/bin/bash
#
# Script para configurar Jenkins con todas las dependencias necesarias
# Uso: ./setup-jenkins.sh [docker|kubernetes]
#

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   Setup Jenkins CI/CD                 ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

INSTALL_METHOD=${1:-docker}

# Función para verificar comandos
check_command() {
    if command -v "$1" &> /dev/null; then
        echo -e "${GREEN}✓${NC} $1 está instalado"
        return 0
    else
        echo -e "${YELLOW}⚠${NC} $1 no está instalado"
        return 1
    fi
}

# Verificar prerrequisitos
echo -e "${YELLOW}Verificando prerrequisitos...${NC}"
check_command docker || { echo -e "${RED}Error: Docker es requerido${NC}"; exit 1; }
check_command kubectl || { echo -e "${RED}Error: kubectl es requerido${NC}"; exit 1; }
check_command gcloud || echo -e "${YELLOW}Advertencia: gcloud CLI no instalado${NC}"

if [ "$INSTALL_METHOD" = "kubernetes" ]; then
    check_command helm || { echo -e "${RED}Error: Helm es requerido para instalación en K8s${NC}"; exit 1; }
fi

echo ""

# Instalación según método
if [ "$INSTALL_METHOD" = "docker" ]; then
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}   Instalando Jenkins con Docker       ${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    # Crear red y volumen
    echo -e "${YELLOW}Creando red y volumen Docker...${NC}"
    docker network create jenkins 2>/dev/null || echo "Red jenkins ya existe"
    docker volume create jenkins-data 2>/dev/null || echo "Volumen jenkins-data ya existe"
    
    # Detener Jenkins existente si lo hay
    if docker ps -a | grep -q jenkins; then
        echo -e "${YELLOW}Deteniendo Jenkins existente...${NC}"
        docker stop jenkins 2>/dev/null || true
        docker rm jenkins 2>/dev/null || true
    fi
    
    # Ejecutar Jenkins
    echo -e "${YELLOW}Iniciando Jenkins...${NC}"
    docker run -d \
        --name jenkins \
        --restart unless-stopped \
        --network jenkins \
        -p 8080:8080 \
        -p 50000:50000 \
        -v jenkins-data:/var/jenkins_home \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -e JAVA_OPTS="-Xmx2g -Xms1g" \
        jenkins/jenkins:lts
    
    echo -e "${GREEN}✓ Jenkins iniciado${NC}"
    echo ""
    
    # Esperar a que Jenkins esté listo
    echo -e "${YELLOW}Esperando a que Jenkins esté listo...${NC}"
    until docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null; do
        echo -n "."
        sleep 2
    done
    echo ""
    
    # Mostrar password inicial
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}   Jenkins está listo!                 ${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "URL: ${BLUE}http://localhost:8080${NC}"
    echo ""
    echo -e "Password inicial:"
    echo -e "${YELLOW}$(docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword)${NC}"
    echo ""
    
    # Instalar herramientas dentro del contenedor
    echo -e "${YELLOW}Instalando herramientas adicionales en el contenedor...${NC}"
    
    # kubectl
    docker exec -u root jenkins bash -c "
        curl -LO 'https://dl.k8s.io/release/\$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl' && \
        chmod +x kubectl && \
        mv kubectl /usr/local/bin/
    " 2>/dev/null && echo -e "${GREEN}✓ kubectl instalado${NC}" || echo -e "${YELLOW}⚠ Error instalando kubectl${NC}"
    
    # gcloud CLI
    docker exec -u root jenkins bash -c "
        apt-get update && \
        apt-get install -y curl gnupg && \
        echo 'deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main' | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
        curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - && \
        apt-get update && \
        apt-get install -y google-cloud-sdk google-cloud-sdk-gke-gcloud-auth-plugin
    " 2>/dev/null && echo -e "${GREEN}✓ gcloud CLI instalado${NC}" || echo -e "${YELLOW}⚠ Error instalando gcloud${NC}"
    
    # uv (Python package manager)
    docker exec -u root jenkins bash -c "
        curl -LsSf https://astral.sh/uv/install.sh | sh
    " 2>/dev/null && echo -e "${GREEN}✓ uv instalado${NC}" || echo -e "${YELLOW}⚠ Error instalando uv${NC}"
    
    # Python 3.11
    docker exec -u root jenkins bash -c "
        apt-get update && \
        apt-get install -y python3.11 python3.11-venv python3-pip
    " 2>/dev/null && echo -e "${GREEN}✓ Python 3.11 instalado${NC}" || echo -e "${YELLOW}⚠ Error instalando Python${NC}"
    
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Próximos pasos:${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo "1. Abre http://localhost:8080 en tu navegador"
    echo "2. Ingresa el password inicial mostrado arriba"
    echo "3. Instala los plugins sugeridos"
    echo "4. Crea tu usuario admin"
    echo "5. Configura las credenciales de GCP:"
    echo "   - Manage Jenkins → Manage Credentials"
    echo "   - Add: gcp-service-account-key (Secret file)"
    echo "   - Add: gcp-project-id (Secret text)"
    echo "6. Crea un nuevo Pipeline job apuntando al Jenkinsfile"
    echo ""
    
elif [ "$INSTALL_METHOD" = "kubernetes" ]; then
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}   Instalando Jenkins en Kubernetes    ${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    # Crear namespace
    echo -e "${YELLOW}Creando namespace jenkins...${NC}"
    kubectl create namespace jenkins 2>/dev/null || echo "Namespace jenkins ya existe"
    
    # Agregar repo de Helm
    echo -e "${YELLOW}Agregando repositorio de Helm...${NC}"
    helm repo add jenkins https://charts.jenkins.io
    helm repo update
    
    # Leer configuración
    read -p "Dominio para Jenkins (ej: jenkins.example.com): " JENKINS_DOMAIN
    read -s -p "Password admin para Jenkins: " ADMIN_PASSWORD
    echo ""
    
    # Actualizar values file
    sed -i "s/jenkins.tudominio.com/$JENKINS_DOMAIN/g" jenkins-values.yaml
    sed -i "s/changeme123/$ADMIN_PASSWORD/g" jenkins-values.yaml
    
    # Instalar Jenkins
    echo -e "${YELLOW}Instalando Jenkins...${NC}"
    helm upgrade --install jenkins jenkins/jenkins \
        --namespace jenkins \
        --values jenkins-values.yaml \
        --wait
    
    echo -e "${GREEN}✓ Jenkins instalado${NC}"
    echo ""
    
    # Obtener información
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}   Jenkins está listo!                 ${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    
    # Service
    JENKINS_SERVICE=$(kubectl get svc -n jenkins jenkins -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")
    if [ "$JENKINS_SERVICE" != "pending" ]; then
        echo -e "URL: ${BLUE}http://$JENKINS_SERVICE:8080${NC}"
    else
        echo -e "URL: ${BLUE}http://$JENKINS_DOMAIN${NC} (una vez configurado el DNS)"
    fi
    echo ""
    echo -e "Usuario: ${YELLOW}admin${NC}"
    echo -e "Password: ${YELLOW}[el que ingresaste]${NC}"
    echo ""
    
    # Port-forward para acceso inmediato
    echo -e "${YELLOW}Para acceso inmediato, ejecuta:${NC}"
    echo -e "  kubectl port-forward -n jenkins svc/jenkins 8080:8080"
    echo ""
    
else
    echo -e "${RED}Método de instalación no válido. Usa: docker o kubernetes${NC}"
    exit 1
fi

# Crear archivo de configuración de ejemplo
cat > jenkins-config.example.env << EOF
# Configuración de Jenkins para CI/CD

# GCP
GCP_PROJECT_ID=your-project-id
GCP_REGION=us-central1
GKE_CLUSTER=todo-app-cluster

# Docker Registry
DOCKER_REGISTRY=gcr.io/\${GCP_PROJECT_ID}

# GitHub (opcional)
GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx
GITHUB_REPO=https://github.com/usuario/ansible-project

# Notificaciones (opcional)
SLACK_WEBHOOK=https://hooks.slack.com/services/xxx/xxx/xxx
EMAIL_RECIPIENTS=team@example.com
EOF

echo -e "${GREEN}✓ Archivo de configuración de ejemplo creado: jenkins-config.example.env${NC}"
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   Setup completado!                   ${NC}"
echo -e "${GREEN}========================================${NC}"
