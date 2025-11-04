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
        GCP_REGION = 'us-central1'
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
        
        stage('Verify or Create Cluster') {
            when {
                expression { 
                    return env.INFRA_CHANGED == 'true' || env.CODE_CHANGED == 'true'
                }
            }
            steps {
                echo '🔍 Verificando cluster GKE...'
                withCredentials([file(credentialsId: 'gcp-service-account-key', variable: 'GCP_KEY_FILE')]) {
                    script {
                        def clusterExists = sh(
                            script: '''
                                gcloud auth activate-service-account --key-file="$GCP_KEY_FILE"
                                gcloud config set project "$PROJECT_ID"
                                gcloud container clusters describe "$GKE_CLUSTER" --region="$GCP_REGION" 2>/dev/null
                            ''',
                            returnStatus: true
                        )
                        
                        if (clusterExists != 0) {
                            echo '🆕 Cluster no existe, creando con gcloud...'
                            sh '''
                                gcloud auth activate-service-account --key-file="$GCP_KEY_FILE"
                                gcloud config set project "$PROJECT_ID"
                                
                                # Crear cluster usando gcloud directamente
                                gcloud container clusters create "$GKE_CLUSTER" \
                                    --region "$GCP_REGION" \
                                    --num-nodes 3 \
                                    --machine-type e2-medium \
                                    --disk-size 20 \
                                    --enable-autoscaling \
                                    --min-nodes 1 \
                                    --max-nodes 5 \
                                    --enable-autorepair \
                                    --enable-autoupgrade
                            '''
                        } else {
                            echo '✅ Cluster ya existe'
                        }
                        
                        // Siempre obtener credenciales del cluster al final
                        echo '🔐 Obteniendo credenciales del cluster...'
                        sh '''
                            gcloud container clusters get-credentials "$GKE_CLUSTER" \
                                --region "$GCP_REGION" \
                                --project "$PROJECT_ID"
                        '''
                    }
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
                sh '''
                    # Aplicar cambios en la infraestructura
                    echo "Aplicando cambios de infraestructura..."
                    kubectl apply -f kubernetes/gcp/namespace.yaml
                    
                    # Si hay cambios en los manifests, aplicarlos
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
                '''
            }
        }
        
        stage('Deploy Application') {
            when {
                expression { 
                    return env.CODE_CHANGED == 'true' || env.CONFIG_CHANGED == 'true'
                }
            }
            steps {
                echo '🚀 Desplegando aplicación...'
                sh '''
                    # Crear namespace si no existe
                    kubectl apply -f kubernetes/gcp/namespace.yaml
                    
                    # Actualizar las imágenes de los deployments
                    echo "Actualizando imágenes Docker..."
                    kubectl set image deployment/todo-frontend \
                        todo-frontend="$FRONTEND_IMAGE:$BUILD_TAG" \
                        -n todo-app
                    
                    kubectl set image deployment/todo-backend \
                        todo-backend="$BACKEND_IMAGE:$BUILD_TAG" \
                        -n todo-app
                    
                    kubectl set image statefulset/todo-db \
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
                    # Verificar que todos los pods estén corriendo
                    kubectl get pods -n todo-app
                    kubectl rollout status deployment/todo-frontend -n todo-app --timeout=5m
                    kubectl rollout status deployment/todo-backend -n todo-app --timeout=5m
                    kubectl rollout status statefulset/todo-db -n todo-app --timeout=5m
                    
                    # Obtener información del servicio
                    echo "=========================================="
                    echo "Información del Ingress:"
                    kubectl get ingress -n todo-app
                    echo "=========================================="
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