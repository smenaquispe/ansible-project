# Jenkins CI/CD Setup 🚀

Sistema completo de CI/CD para automatizar builds, tests y despliegues del proyecto Todo-App.

## 🎯 ¿Por dónde empezar?

### 👉 **NUEVO**: Lee primero [`START-HERE.md`](START-HERE.md)

Resumen ejecutivo con todo lo que necesitas saber.

### 📚 Guías por Nivel

1. **Principiante** → [`QUICKSTART.md`](QUICKSTART.md) (5 min)
2. **Intermedio** → Este README (guía completa)
3. **Avanzado** → [`ARCHITECTURE-DIAGRAM.md`](ARCHITECTURE-DIAGRAM.md)
4. **Referencia diaria** → [`QUICK-REFERENCE.md`](QUICK-REFERENCE.md)

## 📋 Tabla de Contenidos

- [Requisitos](#requisitos)
- [Instalación de Jenkins](#instalación-de-jenkins)
- [Configuración](#configuración)
- [Pipeline](#pipeline)
- [Credenciales](#credenciales)
- [Webhooks](#webhooks)
- [Troubleshooting](#troubleshooting)

## 🔧 Requisitos

### En el servidor Jenkins

- Docker instalado
- kubectl instalado
- gcloud CLI instalado
- Python 3.11+
- uv (gestor de paquetes Python)

### Plugins de Jenkins requeridos

```bash
# Pipeline y Git
Pipeline
Git plugin
GitHub plugin

# Docker
Docker Pipeline
Docker plugin

# Kubernetes
Kubernetes CLI Plugin

# Utilidades
Credentials Binding Plugin
Google Kubernetes Engine Plugin
HTML Publisher Plugin
```

## 📦 Instalación de Jenkins

### Opción 1: Docker (Recomendado)

```bash
# Crear red Docker
docker network create jenkins

# Crear volumen para datos persistentes
docker volume create jenkins-data

# Ejecutar Jenkins con Docker-in-Docker
docker run -d \
  --name jenkins \
  --restart unless-stopped \
  --network jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins-data:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts

# Obtener password inicial
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

### Opción 2: Kubernetes (Producción)

Usar el Helm chart oficial:

```bash
# Agregar repo de Jenkins
helm repo add jenkins https://charts.jenkins.io
helm repo update

# Instalar Jenkins
helm install jenkins jenkins/jenkins \
  --namespace jenkins \
  --create-namespace \
  --values jenkins/jenkins-values.yaml
```

Ver `jenkins-values.yaml` para configuración personalizada.

## ⚙️ Configuración

### 1. Instalar Plugins

1. Ve a: `Manage Jenkins` → `Manage Plugins` → `Available`
2. Busca e instala los plugins listados arriba
3. Reinicia Jenkins

### 2. Configurar Herramientas Globales

**Manage Jenkins → Global Tool Configuration**

#### Docker

- Name: `docker`
- Install automatically: ✅

#### kubectl

```bash
# En el servidor Jenkins
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

#### gcloud CLI

```bash
# En el servidor Jenkins
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
gcloud init
```

#### uv (Python)

```bash
# En el servidor Jenkins
curl -LsSf https://astral.sh/uv/install.sh | sh
```

## 🔐 Credenciales

Configurar en: `Manage Jenkins` → `Manage Credentials` → `(global)`

### 1. GCP Service Account

**ID:** `gcp-service-account-key`  
**Tipo:** Secret file

```bash
# Crear service account en GCP
gcloud iam service-accounts create jenkins-ci \
  --display-name "Jenkins CI/CD"

# Asignar permisos necesarios
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:jenkins-ci@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/container.developer"

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:jenkins-ci@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/storage.admin"

# Crear y descargar la key
gcloud iam service-accounts keys create jenkins-sa-key.json \
  --iam-account=jenkins-ci@YOUR_PROJECT_ID.iam.gserviceaccount.com

# Subir jenkins-sa-key.json a Jenkins como credencial
```

### 2. GCP Project ID

**ID:** `gcp-project-id`  
**Tipo:** Secret text

Valor: Tu GCP Project ID (ej: `my-project-12345`)

### 3. GitHub Token (Opcional)

**ID:** `github-token`  
**Tipo:** Secret text

Para acceso privado a repos o evitar límites de rate.

## 🔄 Crear Pipeline Job

### 1. Nuevo Item

1. Click en `New Item`
2. Nombre: `todo-app-cicd`
3. Tipo: `Pipeline`
4. Click `OK`

### 2. Configurar Pipeline

#### General

- ✅ GitHub project: `https://github.com/TU_USUARIO/ansible-project`
- ✅ Discard old builds: Keep last 10 builds

#### Build Triggers

- ✅ **GitHub hook trigger for GITScm polling**
- ✅ **Poll SCM**: `H/5 * * * *` (cada 5 minutos como fallback)

#### Pipeline

- **Definition:** Pipeline script from SCM
- **SCM:** Git
- **Repository URL:** `https://github.com/TU_USUARIO/ansible-project.git`
- **Credentials:** (si es privado) selecciona tu GitHub token
- **Branch:** `*/master` o `*/main`
- **Script Path:** `Jenkinsfile`

### 3. Guardar

Click en `Save`

## 🎣 Configurar Webhooks

### GitHub Webhook

1. Ve a tu repositorio en GitHub
2. `Settings` → `Webhooks` → `Add webhook`
3. **Payload URL:** `http://TU_JENKINS_URL/github-webhook/`
4. **Content type:** `application/json`
5. **Events:** Just the push event
6. ✅ Active
7. Click `Add webhook`

### GitLab Webhook (alternativa)

1. Ve a tu proyecto en GitLab
2. `Settings` → `Webhooks`
3. **URL:** `http://TU_JENKINS_URL/project/todo-app-cicd`
4. **Trigger:** Push events
5. Click `Add webhook`

## 🏗️ Funcionamiento del Pipeline

El pipeline automáticamente:

### 1. **Detecta Cambios**

- Código fuente (`src/`)
- Infraestructura (`ansible/`, `kubernetes/`)
- Configuración (`config.env`, `group_vars/`)

### 2. **Ejecuta Tests**

- Solo si hay cambios en código
- Genera reporte de cobertura

### 3. **Construye Imágenes Docker**

- Solo los componentes modificados
- Etiqueta con número de build y commit hash

### 4. **Publica a GCR**

- Sube imágenes a Google Container Registry
- Tags: `latest` y `BUILD_NUMBER-COMMIT_HASH`

### 5. **Gestiona Infraestructura**

- Verifica/crea cluster GKE si es necesario
- Actualiza recursos si hay cambios en infraestructura

### 6. **Despliega Aplicación**

- Usa Ansible playbooks existentes
- Actualiza deployments con nuevas imágenes

### 7. **Verifica Despliegue**

- Comprueba que todos los pods estén corriendo
- Hace health check del API

## 🎯 Ejemplo de Uso

### Despliegue Automático

```bash
# 1. Hacer cambios en el código
echo "// nuevo feature" >> src/app/frontend/src/App.jsx

# 2. Commit y push
git add .
git commit -m "feat: nuevo feature en frontend"
git push origin master

# 3. Jenkins detecta el push via webhook
# 4. Pipeline se ejecuta automáticamente:
#    - Construye imagen de frontend
#    - Ejecuta tests
#    - Publica a GCR
#    - Despliega en GKE
#    - Verifica salud
```

### Actualizar Infraestructura

```bash
# Cambiar configuración de recursos
vim ansible/group_vars/gcp.yml

git add ansible/group_vars/gcp.yml
git commit -m "chore: aumentar recursos de backend"
git push origin master

# Jenkins ejecuta update-cluster.yml
```

## 📊 Monitoreo

### Ver Estado del Pipeline

1. Dashboard de Jenkins: `http://JENKINS_URL:8080`
2. Click en el job `todo-app-cicd`
3. Ver historial de builds y logs

### Logs en Tiempo Real

```bash
# Ver logs del último build
docker exec jenkins \
  tail -f /var/jenkins_home/jobs/todo-app-cicd/builds/lastSuccessfulBuild/log
```

### Métricas de Build

El plugin HTML Publisher genera reportes de:

- Cobertura de tests
- Análisis estático (si se configura)

## 🔧 Troubleshooting

### Error: "No space left on device"

```bash
# Limpiar imágenes Docker antiguas
docker system prune -a --volumes

# O en el Jenkinsfile, aumentar la frecuencia de limpieza
```

### Error: "kubectl: connection refused"

```bash
# Verificar credenciales de GKE
gcloud container clusters get-credentials todo-app-cluster \
  --region=us-central1 --project=YOUR_PROJECT_ID

# Copiar kubeconfig a Jenkins
docker cp ~/.kube/config jenkins:/var/jenkins_home/.kube/config
```

### Error: "gcloud: command not found"

```bash
# Instalar gcloud en el contenedor de Jenkins
docker exec -u root jenkins bash -c "
  curl https://sdk.cloud.google.com | bash
  exec -l \$SHELL
"
```

### Pipeline no se activa con push

1. Verificar webhook en GitHub/GitLab
2. Comprobar que Jenkins sea accesible públicamente
3. Revisar logs de Jenkins: `Manage Jenkins` → `System Log`

### Timeout en despliegue

```groovy
// Aumentar timeout en Jenkinsfile
timeout(time: 60, unit: 'MINUTES')  // Cambiar de 30 a 60
```

## 🚀 Mejoras Futuras

### 1. Ambientes Múltiples

```groovy
// Agregar stage para diferentes ambientes
stage('Deploy to Staging') {
    when { branch 'develop' }
    // ...
}

stage('Deploy to Production') {
    when { branch 'master' }
    input message: 'Deploy to production?'
    // ...
}
```

### 2. Notificaciones

```groovy
// En post section
post {
    success {
        slackSend(color: 'good', message: "Deployment successful!")
    }
    failure {
        mail to: 'team@example.com',
             subject: "Build Failed",
             body: "Check ${env.BUILD_URL}"
    }
}
```

### 3. Rollback Automático

```groovy
stage('Rollback on Failure') {
    when { expression { currentBuild.result == 'FAILURE' } }
    steps {
        sh 'kubectl rollout undo deployment/todo-frontend -n todo-app'
    }
}
```

### 4. Blue-Green Deployment

```groovy
stage('Blue-Green Deploy') {
    steps {
        sh '''
            kubectl apply -f kubernetes/blue-green/
            # Switch traffic
            kubectl patch service todo-app -p '{"spec":{"selector":{"version":"green"}}}'
        '''
    }
}
```

## 📚 Referencias

- [Jenkins Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [Google Kubernetes Engine Plugin](https://plugins.jenkins.io/google-kubernetes-engine/)
- [Docker Pipeline Plugin](https://plugins.jenkins.io/docker-workflow/)
- [Ansible en Jenkins](https://plugins.jenkins.io/ansible/)

## 💡 Tips

1. **Usar Jenkins Shared Libraries** para código reutilizable
2. **Implementar Quality Gates** con SonarQube
3. **Cachear dependencias** para builds más rápidos
4. **Usar Jenkins Agents** en Kubernetes para escalabilidad
5. **Implementar Secret Management** con Vault o Sealed Secrets
