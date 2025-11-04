#!/usr/bin/env fish
#
# Script de setup de Jenkins para Fish shell
# Uso: ./setup-jenkins.fish [docker|kubernetes]
#

set GREEN (set_color green)
set YELLOW (set_color yellow)
set RED (set_color red)
set BLUE (set_color blue)
set NORMAL (set_color normal)

echo "$BLUE========================================$NORMAL"
echo "$BLUE   Setup Jenkins CI/CD                 $NORMAL"
echo "$BLUE========================================$NORMAL"
echo ""

set INSTALL_METHOD $argv[1]
test -z "$INSTALL_METHOD"; and set INSTALL_METHOD docker

# Función para verificar comandos
function check_command
    if command -q $argv[1]
        echo "$GREEN✓$NORMAL $argv[1] está instalado"
        return 0
    else
        echo "$YELLOW⚠$NORMAL $argv[1] no está instalado"
        return 1
    end
end

# Verificar prerrequisitos
echo "$YELLOW Verificando prerrequisitos...$NORMAL"
check_command docker; or begin
    echo "$RED Error: Docker es requerido$NORMAL"
    exit 1
end

check_command kubectl; or begin
    echo "$RED Error: kubectl es requerido$NORMAL"
    exit 1
end

check_command gcloud; or echo "$YELLOW Advertencia: gcloud CLI no instalado$NORMAL"

if test "$INSTALL_METHOD" = "kubernetes"
    check_command helm; or begin
        echo "$RED Error: Helm es requerido para instalación en K8s$NORMAL"
        exit 1
    end
end

echo ""

# Instalación según método
if test "$INSTALL_METHOD" = "docker"
    echo "$BLUE========================================$NORMAL"
    echo "$BLUE   Instalando Jenkins con Docker       $NORMAL"
    echo "$BLUE========================================$NORMAL"
    echo ""
    
    # Crear red y volumen
    echo "$YELLOW Creando red y volumen Docker...$NORMAL"
    docker network create jenkins 2>/dev/null; or echo "Red jenkins ya existe"
    docker volume create jenkins-data 2>/dev/null; or echo "Volumen jenkins-data ya existe"
    
    # Detener Jenkins existente si lo hay
    if docker ps -a | grep -q jenkins
        echo "$YELLOW Deteniendo Jenkins existente...$NORMAL"
        docker stop jenkins 2>/dev/null; or true
        docker rm jenkins 2>/dev/null; or true
    end
    
    # Ejecutar Jenkins
    echo "$YELLOW Iniciando Jenkins...$NORMAL"
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
    
    echo "$GREEN✓ Jenkins iniciado$NORMAL"
    echo ""
    
    # Esperar a que Jenkins esté listo
    echo "$YELLOW Esperando a que Jenkins esté listo...$NORMAL"
    while not docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null
        echo -n "."
        sleep 2
    end
    echo ""
    
    # Mostrar password inicial
    echo ""
    echo "$GREEN========================================$NORMAL"
    echo "$GREEN   Jenkins está listo!                 $NORMAL"
    echo "$GREEN========================================$NORMAL"
    echo ""
    echo "URL: $BLUE http://localhost:8080$NORMAL"
    echo ""
    echo "Password inicial:"
    set INITIAL_PASSWORD (docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword)
    echo "$YELLOW$INITIAL_PASSWORD$NORMAL"
    echo ""
    
    # Instalar herramientas dentro del contenedor
    echo "$YELLOW Instalando herramientas adicionales en el contenedor...$NORMAL"
    
    # kubectl
    docker exec -u root jenkins bash -c "
        curl -LO 'https://dl.k8s.io/release/\$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl' && \
        chmod +x kubectl && \
        mv kubectl /usr/local/bin/
    " 2>/dev/null; and echo "$GREEN✓ kubectl instalado$NORMAL"; or echo "$YELLOW⚠ Error instalando kubectl$NORMAL"
    
    # gcloud CLI
    docker exec -u root jenkins bash -c "
        apt-get update && \
        apt-get install -y curl gnupg && \
        echo 'deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main' | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
        curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - && \
        apt-get update && \
        apt-get install -y google-cloud-sdk google-cloud-sdk-gke-gcloud-auth-plugin
    " 2>/dev/null; and echo "$GREEN✓ gcloud CLI instalado$NORMAL"; or echo "$YELLOW⚠ Error instalando gcloud$NORMAL"
    
    # uv (Python package manager)
    docker exec -u root jenkins bash -c "
        curl -LsSf https://astral.sh/uv/install.sh | sh
    " 2>/dev/null; and echo "$GREEN✓ uv instalado$NORMAL"; or echo "$YELLOW⚠ Error instalando uv$NORMAL"
    
    # Python 3.11
    docker exec -u root jenkins bash -c "
        apt-get update && \
        apt-get install -y python3.11 python3.11-venv python3-pip
    " 2>/dev/null; and echo "$GREEN✓ Python 3.11 instalado$NORMAL"; or echo "$YELLOW⚠ Error instalando Python$NORMAL"
    
    echo ""
    echo "$GREEN========================================$NORMAL"
    echo "$GREEN Próximos pasos:$NORMAL"
    echo "$GREEN========================================$NORMAL"
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
    
else if test "$INSTALL_METHOD" = "kubernetes"
    echo "$BLUE========================================$NORMAL"
    echo "$BLUE   Instalando Jenkins en Kubernetes    $NORMAL"
    echo "$BLUE========================================$NORMAL"
    echo ""
    
    # Crear namespace
    echo "$YELLOW Creando namespace jenkins...$NORMAL"
    kubectl create namespace jenkins 2>/dev/null; or echo "Namespace jenkins ya existe"
    
    # Agregar repo de Helm
    echo "$YELLOW Agregando repositorio de Helm...$NORMAL"
    helm repo add jenkins https://charts.jenkins.io
    helm repo update
    
    # Leer configuración
    read -P "Dominio para Jenkins (ej: jenkins.example.com): " JENKINS_DOMAIN
    read -s -P "Password admin para Jenkins: " ADMIN_PASSWORD
    echo ""
    
    # Instalar Jenkins
    echo "$YELLOW Instalando Jenkins...$NORMAL"
    helm upgrade --install jenkins jenkins/jenkins \
        --namespace jenkins \
        --values jenkins/jenkins-values.yaml \
        --set controller.ingress.hostName=$JENKINS_DOMAIN \
        --set controller.adminPassword=$ADMIN_PASSWORD \
        --wait
    
    echo "$GREEN✓ Jenkins instalado$NORMAL"
    echo ""
    
    # Obtener información
    echo "$GREEN========================================$NORMAL"
    echo "$GREEN   Jenkins está listo!                 $NORMAL"
    echo "$GREEN========================================$NORMAL"
    echo ""
    
    echo "URL: $BLUE http://$JENKINS_DOMAIN$NORMAL"
    echo ""
    echo "Usuario: $YELLOW admin$NORMAL"
    echo "Password: $YELLOW [el que ingresaste]$NORMAL"
    echo ""
    
    # Port-forward para acceso inmediato
    echo "$YELLOW Para acceso inmediato, ejecuta:$NORMAL"
    echo "  kubectl port-forward -n jenkins svc/jenkins 8080:8080"
    echo ""
    
else
    echo "$RED Método de instalación no válido. Usa: docker o kubernetes$NORMAL"
    exit 1
end

echo "$GREEN========================================$NORMAL"
echo "$GREEN   Setup completado!                   $NORMAL"
echo "$GREEN========================================$NORMAL"
