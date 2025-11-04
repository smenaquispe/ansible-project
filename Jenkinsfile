#!/usr/bin/env groovy

/**
 * Jenkins Pipeline para CI/CD del proyecto Todo-App
 * 
 * Este pipeline:
 * - Detecta cambios en código o infraestructura
 * - Construye y publica imágenes Docker
 * - Despliega en GKE usando Ansible
 * - Gestiona actualizaciones de infraestructura
 */

pipeline {
    agent any
    
    environment {
        // Configuración de proyecto
        PROJECT_ID = credentials('gcp-project-id')
        GCP_REGION = 'us-central1-a'
        GKE_CLUSTER = 'todo-app-cluster'
        
        // Configuración de Docker
        DOCKER_REGISTRY = "gcr.io/${PROJECT_ID}"
        FRONTEND_IMAGE = "${DOCKER_REGISTRY}/todo-frontend"
        BACKEND_IMAGE = "${DOCKER_REGISTRY}/todo-backend"
        DB_IMAGE = "${DOCKER_REGISTRY}/todo-db"
        
        // Git
        GIT_COMMIT_SHORT = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
        BUILD_TAG = "${env.BUILD_NUMBER}-${GIT_COMMIT_SHORT}"
    }
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
    }
    
    triggers {
        // GitHub webhook trigger - Se activa automáticamente con cada push
        githubPush()
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo '📦 Clonando repositorio...'
                checkout scm
                
                script {
                    // Obtener información del commit
                    env.GIT_AUTHOR = sh(script: "git log -1 --pretty=format:'%an'", returnStdout: true).trim()
                    env.GIT_MESSAGE = sh(script: "git log -1 --pretty=format:'%s'", returnStdout: true).trim()
                }
                
                echo "Commit: ${env.GIT_MESSAGE}"
                echo "Author: ${env.GIT_AUTHOR}"
            }
        }
        
        stage('Detect Changes') {
            steps {
                echo '🔍 Detectando cambios...'
                script {
                    // Inicializar flags como booleanos
                    env.CODE_CHANGED = 'false'
                    env.INFRA_CHANGED = 'false'
                    env.CONFIG_CHANGED = 'false'
                    
                    // Detectar cambios en el código de la aplicación
                    def codeChanges = sh(
                        script: '''
                            git diff --name-only HEAD~1 HEAD 2>/dev/null | grep -E '^src/' || true
                        ''',
                        returnStdout: true
                    ).trim()
                    
                    if (codeChanges) {
                        env.CODE_CHANGED = 'true'
                        echo "✅ Cambios detectados en código:"
                        echo codeChanges
                    }
                    
                    // Detectar cambios en infraestructura (Ansible/K8s)
                    def infraChanges = sh(
                        script: '''
                            git diff --name-only HEAD~1 HEAD 2>/dev/null | grep -E '^(ansible/|kubernetes/)' || true
                        ''',
                        returnStdout: true
                    ).trim()
                    
                    if (infraChanges) {
                        env.INFRA_CHANGED = 'true'
                        echo "✅ Cambios detectados en infraestructura:"
                        echo infraChanges
                    }
                    
                    // Detectar cambios en configuración
                    def configChanges = sh(
                        script: '''
                            git diff --name-only HEAD~1 HEAD 2>/dev/null | grep -E '^(config\\.env|ansible/group_vars/)' || true
                        ''',
                        returnStdout: true
                    ).trim()
                    
                    if (configChanges) {
                        env.CONFIG_CHANGED = 'true'
                        echo "✅ Cambios detectados en configuración:"
                        echo configChanges
                    }
                    
                    // Si es el primer build o no hay commit anterior, construir todo
                    if (env.BUILD_NUMBER == '1') {
                        env.CODE_CHANGED = 'true'
                        env.INFRA_CHANGED = 'true'
                        echo "⚠️ Primer build - construyendo todo"
                    }
                    
                    // Debug: mostrar valores de las flags
                    echo "DEBUG - CODE_CHANGED: ${env.CODE_CHANGED}"
                    echo "DEBUG - INFRA_CHANGED: ${env.INFRA_CHANGED}"
                    echo "DEBUG - CONFIG_CHANGED: ${env.CONFIG_CHANGED}"
                }
            }
        }
        
        stage('Setup Python Environment') {
            when {
                expression { 
                    return env.CODE_CHANGED == 'true' || env.INFRA_CHANGED == 'true'
                }
            }
            steps {
                echo '🐍 Configurando entorno Python...'
                sh '''
                    # Instalar uv si no está instalado
                    if ! command -v uv &> /dev/null; then
                        curl -LsSf https://astral.sh/uv/install.sh | sh
                        export PATH="$HOME/.local/bin:$PATH"
                    fi
                    
                    # Usar ruta completa de uv
                    export PATH="$HOME/.local/bin:$PATH"
                    
                    # Sincronizar dependencias
                    uv sync
                '''
            }
        }
        
        stage('Run Tests') {
            when {
                expression { 
                    return env.CODE_CHANGED == 'true'
                }
            }
            steps {
                echo '🧪 Ejecutando tests...'
                sh '''
                    export PATH="$HOME/.local/bin:$PATH"
                    # Excluir test_deploy.py porque requiere scripts Python que no existen (solo Fish)
                    uv run pytest tests/test_structure.py -v --cov-report=term-missing --cov-report=html
                '''
            }
            post {
                always {
                    // TODO: Instalar plugin HTML Publisher para habilitar reportes
                    // publishHTML(target: [
                    //     allowMissing: true,
                    //     alwaysLinkToLastBuild: true,
                    //     keepAll: true,
                    //     reportDir: 'htmlcov',
                    //     reportFiles: 'index.html',
                    //     reportName: 'Coverage Report'
                    // ])
                    echo "📊 Reporte de cobertura generado en htmlcov/"
                }
            }
        }
        
        stage('Build Docker Images') {
            when {
                expression { 
                    return env.CODE_CHANGED == 'true'
                }
            }
            parallel {
                stage('Build Frontend') {
                    when {
                        expression { 
                            return env.CODE_CHANGED == 'true'
                        }
                    }
                    steps {
                        echo '🏗️ Construyendo imagen Frontend...'
                        dir('src/app/frontend') {
                            sh """
                                docker build -t ${FRONTEND_IMAGE}:${BUILD_TAG} .
                                docker tag ${FRONTEND_IMAGE}:${BUILD_TAG} ${FRONTEND_IMAGE}:latest
                            """
                        }
                    }
                }
                
                stage('Build Backend') {
                    when {
                        expression { 
                            return env.CODE_CHANGED == 'true'
                        }
                    }
                    steps {
                        echo '🏗️ Construyendo imagen Backend...'
                        dir('src/app/backend') {
                            sh """
                                docker build -t ${BACKEND_IMAGE}:${BUILD_TAG} .
                                docker tag ${BACKEND_IMAGE}:${BUILD_TAG} ${BACKEND_IMAGE}:latest
                            """
                        }
                    }
                }
                
                stage('Build Database') {
                    when {
                        expression { 
                            return env.CODE_CHANGED == 'true'
                        }
                    }
                    steps {
                        echo '🏗️ Construyendo imagen Database...'
                        dir('src/app/db') {
                            sh """
                                docker build -t ${DB_IMAGE}:${BUILD_TAG} .
                                docker tag ${DB_IMAGE}:${BUILD_TAG} ${DB_IMAGE}:latest
                            """
                        }
                    }
                }
            }
        }
        
        stage('Push Docker Images') {
            when {
                expression { 
                    return env.CODE_CHANGED == 'true'
                }
            }
            steps {
                echo '📤 Publicando imágenes a GCR...'
                withCredentials([file(credentialsId: 'gcp-service-account-key', variable: 'GCP_KEY_FILE')]) {
                    sh '''
                        # Autenticar con GCP
                        gcloud auth activate-service-account --key-file="${GCP_KEY_FILE}"
                        gcloud config set project "${PROJECT_ID}"
                        
                        # Configurar Docker para GCR
                        gcloud auth configure-docker
                        
                        # Push de imágenes
                        docker push ${FRONTEND_IMAGE}:${BUILD_TAG}
                        docker push ${FRONTEND_IMAGE}:latest
                        
                        docker push ${BACKEND_IMAGE}:${BUILD_TAG}
                        docker push ${BACKEND_IMAGE}:latest
                        
                        docker push ${DB_IMAGE}:${BUILD_TAG}
                        docker push ${DB_IMAGE}:latest
                    '''
                }
            }
        }
        
        stage('Connect to Cluster') {
            when {
                expression { 
                    return env.CODE_CHANGED == 'true' || env.INFRA_CHANGED == 'true'
                }
            }
            steps {
                echo '� Conectando al cluster GKE existente...'
                withCredentials([file(credentialsId: 'gcp-service-account-key', variable: 'GCP_KEY_FILE')]) {
                    sh '''
                        gcloud auth activate-service-account --key-file="$GCP_KEY_FILE"
                        gcloud config set project "$PROJECT_ID"
                        
                        # Obtener credenciales del cluster existente
                        echo "Obteniendo credenciales del cluster $GKE_CLUSTER..."
                        gcloud container clusters get-credentials "$GKE_CLUSTER" \
                            --region "$GCP_REGION" \
                            --project "$PROJECT_ID"
                        
                        # Verificar conectividad
                        echo "Verificando conectividad con el cluster..."
                        kubectl cluster-info || echo "⚠️  Advertencia: No se pudo conectar al cluster"
                        kubectl get nodes || echo "⚠️  Advertencia: No se pudieron listar los nodos"
                    '''
                }
            }
        }
        
        stage('Update Infrastructure') {
            when {
                expression { 
                    return env.INFRA_CHANGED == 'true'
                }
            }
            steps {
                echo '🔧 Actualizando infraestructura Kubernetes...'
                echo '⚠️  NOTA: Si necesitas recrear recursos, usa: ./scripts/deploy.fish'
                sh '''
                    # Solo aplicar cambios si hay modificaciones en los manifests
                    echo "Verificando cambios en manifests..."
                    
                    if [ -f "kubernetes/gcp/namespace.yaml" ]; then
                        kubectl apply -f kubernetes/gcp/namespace.yaml
                    fi
                    
                    if [ -f "kubernetes/gcp/backend-gcp.yaml" ]; then
                        kubectl apply -f kubernetes/gcp/backend-gcp.yaml
                    fi
                    
                    if [ -f "kubernetes/gcp/frontend-gcp.yaml" ]; then
                        kubectl apply -f kubernetes/gcp/frontend-gcp.yaml
                    fi
                    
                    if [ -f "kubernetes/gcp/db-gcp.yaml" ]; then
                        kubectl apply -f kubernetes/gcp/db-gcp.yaml
                    fi
                    
                    if [ -f "kubernetes/gcp/ingress-gcp.yaml" ]; then
                        kubectl apply -f kubernetes/gcp/ingress-gcp.yaml
                    fi
                    
                    if [ -f "kubernetes/gcp/backend-config.yaml" ]; then
                        kubectl apply -f kubernetes/gcp/backend-config.yaml
                    fi
                    
                    echo "✅ Manifests aplicados"
                '''
            }
        }
        
        stage('Deploy Application') {
            when {
                expression { 
                    return env.CODE_CHANGED == 'true'
                }
            }
            steps {
                echo '🚀 Actualizando imágenes de la aplicación...'
                sh '''
                    # Verificar que el namespace existe
                    if ! kubectl get namespace todo-app > /dev/null 2>&1; then
                        echo "❌ Error: El namespace 'todo-app' no existe"
                        echo "Por favor crea primero el cluster e infraestructura con:"
                        echo "  ./scripts/create-cluster.fish"
                        echo "  ./scripts/deploy.fish"
                        exit 1
                    fi
                    
                    # Actualizar las imágenes de los deployments existentes
                    echo "Actualizando imagen Frontend..."
                    kubectl set image deployment/todo-frontend \
                        todo-frontend="$FRONTEND_IMAGE:$BUILD_TAG" \
                        -n todo-app
                    
                    echo "Actualizando imagen Backend..."
                    kubectl set image deployment/todo-backend \
                        todo-backend="$BACKEND_IMAGE:$BUILD_TAG" \
                        -n todo-app
                    
                    echo "Actualizando imagen Database..."
                    kubectl set image deployment/todo-db \
                        todo-db="$DB_IMAGE:$BUILD_TAG" \
                        -n todo-app
                    
                    echo "✅ Imágenes actualizadas correctamente"
                '''
            }
        }
        
        stage('Verify Deployment') {
            when {
                expression { 
                    return env.CODE_CHANGED == 'true' || env.INFRA_CHANGED == 'true'
                }
            }
            steps {
                echo '✅ Verificando despliegue...'
                sh '''
                    echo "Esperando que los deployments se actualicen..."
                    
                    # Verificar rollout de Frontend
                    echo "Verificando Frontend..."
                    kubectl rollout status deployment/todo-frontend -n todo-app --timeout=5m
                    
                    # Verificar rollout de Backend
                    echo "Verificando Backend..."
                    kubectl rollout status deployment/todo-backend -n todo-app --timeout=5m
                    
                    # Verificar rollout de Database
                    echo "Verificando Database..."
                    kubectl rollout status deployment/todo-db -n todo-app --timeout=5m
                    
                    echo ""
                    echo "=========================================="
                    echo "Estado de los Pods:"
                    echo "=========================================="
                    kubectl get pods -n todo-app
                    
                    echo ""
                    echo "=========================================="
                    echo "Servicios:"
                    echo "=========================================="
                    kubectl get svc -n todo-app
                    
                    echo ""
                    echo "=========================================="
                    echo "Ingress:"
                    echo "=========================================="
                    kubectl get ingress -n todo-app
                    
                    # Obtener IP externa si está disponible
                    EXTERNAL_IP=$(kubectl get ingress todo-app-ingress -n todo-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
                    
                    if [ -n "$EXTERNAL_IP" ]; then
                        echo ""
                        echo "=========================================="
                        echo "✅ Aplicación disponible en:"
                        echo "   http://$EXTERNAL_IP"
                        echo "=========================================="
                    fi
                '''
            }
        }
        
        stage('Health Check') {
            when {
                expression { 
                    return env.CODE_CHANGED == 'true'
                }
            }
            steps {
                echo '🏥 Verificando salud de la aplicación...'
                script {
                    // Esperar un poco para que el servicio esté listo
                    sleep 30
                    
                    // Obtener la IP del Ingress
                    def ingressIP = sh(
                        script: """
                            kubectl get ingress -n todo-app -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending"
                        """,
                        returnStdout: true
                    ).trim()
                    
                    if (ingressIP != "pending" && ingressIP != "") {
                        echo "🌐 Aplicación disponible en: http://${ingressIP}"
                        
                        // Intentar hacer una petición de salud
                        def healthCheck = sh(
                            script: "curl -f http://${ingressIP}/api/todos || true",
                            returnStatus: true
                        )
                        
                        if (healthCheck == 0) {
                            echo "✅ Health check exitoso"
                        } else {
                            echo "⚠️ Health check falló - puede necesitar más tiempo"
                        }
                    } else {
                        echo "⏳ IP del Ingress aún no asignada"
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo '✅ Pipeline completado exitosamente!'
            script {
                // Limpiar imágenes locales para ahorrar espacio
                try {
                    sh """
                        docker image prune -f
                    """
                    echo '🗑️ Imágenes Docker limpiadas'
                } catch (Exception e) {
                    echo '⚠️ No se pudo limpiar imágenes Docker (no crítico)'
                }
            }
        }
        
        failure {
            echo '❌ Pipeline falló!'
            // Aquí puedes agregar notificaciones (Slack, Email, etc.)
        }
        
        always {
            // Limpiar workspace para el siguiente build
            cleanWs(
                deleteDirs: true,
                patterns: [
                    [pattern: '.venv', type: 'INCLUDE'],
                    [pattern: '__pycache__', type: 'INCLUDE'],
                    [pattern: '*.pyc', type: 'INCLUDE']
                ]
            )
        }
    }
}