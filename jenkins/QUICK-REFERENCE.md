# 🚀 Comandos Rápidos - CI/CD Reference

## 📋 Setup Inicial

### Instalar Jenkins (Docker)

```bash
cd jenkins
./setup-jenkins.fish docker
# o
./setup-jenkins.sh docker
```

### Instalar Jenkins (Kubernetes)

```bash
cd jenkins
./setup-jenkins.fish kubernetes
```

### Acceder a Jenkins

```bash
# Obtener password inicial
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword

# URL
open http://localhost:8080
```

## 🔐 Configurar GCP Credentials

### Crear Service Account

```bash
# Variables
export PROJECT_ID="tu-proyecto-gcp"
export SA_NAME="jenkins-ci"

# Crear SA
gcloud iam service-accounts create $SA_NAME \
  --display-name "Jenkins CI/CD"

# Permisos para GKE
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/container.developer"

# Permisos para GCR
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/storage.admin"

# Crear key
gcloud iam service-accounts keys create jenkins-sa-key.json \
  --iam-account=${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com

echo "✅ Key guardada en: jenkins-sa-key.json"
```

### Subir Credenciales a Jenkins

```
Jenkins → Manage Jenkins → Manage Credentials → (global) → Add Credentials

1. Secret file:
   - File: jenkins-sa-key.json
   - ID: gcp-service-account-key

2. Secret text:
   - Secret: tu-proyecto-gcp
   - ID: gcp-project-id
```

## 🔄 Gestión de Jenkins

### Ver logs de Jenkins

```bash
docker logs jenkins -f
```

### Reiniciar Jenkins

```bash
docker restart jenkins
```

### Backup de Jenkins

```bash
docker exec jenkins tar -czf /tmp/jenkins-backup.tar.gz /var/jenkins_home
docker cp jenkins:/tmp/jenkins-backup.tar.gz ./jenkins-backup-$(date +%Y%m%d).tar.gz
```

### Restaurar Jenkins

```bash
docker cp jenkins-backup.tar.gz jenkins:/tmp/
docker exec jenkins tar -xzf /tmp/jenkins-backup.tar.gz -C /
docker restart jenkins
```

### Limpiar espacio

```bash
# Limpiar Docker
docker system prune -a --volumes

# Limpiar builds antiguos (dentro de Jenkins)
# Manage Jenkins → System Information → Script Console
# Ejecutar:
# Jenkins.instance.getItemByFullName("todo-app-cicd").builds.each { it.delete() }
```

## 🛠️ Gestión del Pipeline

### Ejecutar pipeline manualmente

```
Dashboard → todo-app-cicd → Build Now
```

### Ver logs del último build

```bash
# Método 1: Docker
docker exec jenkins tail -f /var/jenkins_home/jobs/todo-app-cicd/builds/lastBuild/log

# Método 2: Jenkins UI
Dashboard → todo-app-cicd → #BUILD_NUMBER → Console Output
```

### Cancelar un build

```
Dashboard → todo-app-cicd → #BUILD_NUMBER → Stop Build
```

### Ver historial

```
Dashboard → todo-app-cicd → Build History
```

## 🔍 Debugging

### Ver variables de entorno del build

```groovy
// En Jenkins Script Console:
def job = Jenkins.instance.getItemByFullName("todo-app-cicd")
def build = job.lastBuild
build.environment.each { println it }
```

### Probar credenciales

```bash
# Test GCP credentials
docker exec jenkins gcloud auth list
docker exec jenkins kubectl version --client
```

### Verificar acceso a GKE

```bash
# Desde Jenkins
docker exec jenkins gcloud container clusters list --project=TU_PROJECT_ID
```

### Ver workspace del job

```bash
docker exec jenkins ls -la /var/jenkins_home/workspace/todo-app-cicd
```

## 🚀 Despliegues

### Trigger manual desde terminal

```bash
# Usando Jenkins CLI
curl -X POST http://admin:ADMIN_PASSWORD@localhost:8080/job/todo-app-cicd/build
```

### Forzar rebuild de imágenes

```bash
# Commit vacío que activa el pipeline
git commit --allow-empty -m "chore: trigger rebuild"
git push origin master
```

### Deploy solo frontend

```bash
# Cambiar solo frontend
echo "// trigger" >> src/app/frontend/src/App.jsx
git add src/app/frontend/src/App.jsx
git commit -m "feat: update frontend"
git push origin master
```

### Deploy solo backend

```bash
# Cambiar solo backend
echo "// trigger" >> src/app/backend/server.js
git add src/app/backend/server.js
git commit -m "feat: update backend"
git push origin master
```

## 🔧 Ansible Manual

### Ejecutar playbooks manualmente

```bash
cd ansible

# Deploy completo
ansible-playbook -i inventory/hosts playbooks/deploy-gcp.yml

# Solo crear cluster
ansible-playbook -i inventory/hosts playbooks/create-cluster.yml

# Actualizar cluster
ansible-playbook -i inventory/hosts playbooks/update-cluster.yml

# Build images
ansible-playbook -i inventory/hosts playbooks/build-images.yml \
  -e "image_tag=v1.0.0"
```

## 🐳 Docker Images

### Ver imágenes en GCR

```bash
gcloud container images list --project=TU_PROJECT_ID
gcloud container images list-tags gcr.io/TU_PROJECT_ID/todo-frontend
```

### Pull imagen específica

```bash
docker pull gcr.io/TU_PROJECT_ID/todo-frontend:BUILD_NUMBER-COMMIT_HASH
```

### Eliminar imágenes antiguas

```bash
# Listar tags
gcloud container images list-tags gcr.io/TU_PROJECT_ID/todo-frontend

# Eliminar tag específico
gcloud container images delete gcr.io/TU_PROJECT_ID/todo-frontend:TAG --quiet
```

## ☸️ Kubernetes

### Ver estado del deployment

```bash
kubectl get all -n todo-app
kubectl get pods -n todo-app -w
kubectl get ingress -n todo-app
```

### Ver logs de aplicación

```bash
# Frontend
kubectl logs -f deployment/todo-frontend -n todo-app

# Backend
kubectl logs -f deployment/todo-backend -n todo-app

# Database
kubectl logs -f statefulset/todo-db -n todo-app
```

### Rollback a versión anterior

```bash
# Ver historial
kubectl rollout history deployment/todo-frontend -n todo-app

# Rollback al anterior
kubectl rollout undo deployment/todo-frontend -n todo-app

# Rollback a revisión específica
kubectl rollout undo deployment/todo-frontend -n todo-app --to-revision=2
```

### Escalar manualmente

```bash
# Escalar frontend a 5 réplicas
kubectl scale deployment/todo-frontend -n todo-app --replicas=5

# Ver resultado
kubectl get pods -n todo-app -l app=todo-frontend
```

### Restart de deployments

```bash
# Restart frontend
kubectl rollout restart deployment/todo-frontend -n todo-app

# Restart todos
kubectl rollout restart deployment -n todo-app
```

### Exec en pod

```bash
# Listar pods
kubectl get pods -n todo-app

# Entrar a pod
kubectl exec -it POD_NAME -n todo-app -- /bin/sh

# Ejecutar comando
kubectl exec POD_NAME -n todo-app -- env
```

### Ver recursos utilizados

```bash
kubectl top nodes
kubectl top pods -n todo-app
```

## 🌐 Webhooks

### Configurar webhook de GitHub

```bash
# URL del webhook:
http://TU_JENKINS_URL:8080/github-webhook/

# Para testing local con ngrok:
ngrok http 8080
# Usar URL de ngrok en webhook
```

### Test webhook manualmente

```bash
# Simular webhook push
curl -X POST http://localhost:8080/github-webhook/ \
  -H "Content-Type: application/json" \
  -d '{
    "ref": "refs/heads/master",
    "repository": {
      "url": "https://github.com/USER/REPO"
    }
  }'
```

## 📊 Monitoreo

### Ver métricas de Jenkins

```bash
# En navegador
http://localhost:8080/monitoring
http://localhost:8080/load-statistics
```

### Ver logs de sistema

```bash
# Jenkins logs
docker exec jenkins tail -f /var/jenkins_home/logs/jenkins.log

# Kubernetes events
kubectl get events -n todo-app --sort-by='.lastTimestamp'

# GKE cluster info
gcloud container clusters describe todo-app-cluster \
  --region=us-central1 --format=json
```

## 🧪 Testing

### Ejecutar tests localmente

```bash
# Todos los tests
make test

# Con coverage
uv run pytest tests/ -v --cov=scripts --cov-report=html

# Ver coverage
open htmlcov/index.html
```

### Lint código

```bash
make lint
# o
uv run ruff check scripts/
uv run mypy scripts/
uv run ansible-lint ansible/
```

## 🔥 Comandos de Emergencia

### Rollback completo

```bash
# 1. Identificar commit anterior
git log --oneline

# 2. Rollback
kubectl rollout undo deployment/todo-frontend -n todo-app
kubectl rollout undo deployment/todo-backend -n todo-app
kubectl rollout undo statefulset/todo-db -n todo-app
```

### Eliminar todo y redeployar

```bash
# 1. Eliminar namespace
kubectl delete namespace todo-app

# 2. Redeployar
cd ansible
ansible-playbook -i inventory/hosts playbooks/deploy-gcp.yml
```

### Reconstruir cluster desde cero

```bash
# 1. Eliminar cluster
gcloud container clusters delete todo-app-cluster \
  --region=us-central1 --quiet

# 2. Recrear
cd ansible
ansible-playbook -i inventory/hosts playbooks/create-cluster.yml
ansible-playbook -i inventory/hosts playbooks/deploy-gcp.yml
```

### Verificar todo está funcionando

```bash
#!/bin/bash
# health-check.sh

echo "🔍 Verificando Jenkins..."
curl -s http://localhost:8080 > /dev/null && echo "✅ Jenkins OK" || echo "❌ Jenkins DOWN"

echo "🔍 Verificando GKE..."
kubectl cluster-info > /dev/null 2>&1 && echo "✅ GKE OK" || echo "❌ GKE DOWN"

echo "🔍 Verificando Pods..."
kubectl get pods -n todo-app | grep Running && echo "✅ Pods OK" || echo "❌ Pods NOT READY"

echo "🔍 Verificando Ingress..."
INGRESS_IP=$(kubectl get ingress -n todo-app -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}')
if [ ! -z "$INGRESS_IP" ]; then
    curl -s http://$INGRESS_IP > /dev/null && echo "✅ Ingress OK ($INGRESS_IP)" || echo "⚠️ Ingress IP exists but not responding"
else
    echo "⏳ Ingress IP pending"
fi

echo "🔍 Verificando Backend Health..."
curl -s http://$INGRESS_IP/api/todos > /dev/null && echo "✅ Backend API OK" || echo "⚠️ Backend API not responding"
```

## 📱 Aliases Útiles (Agregar a .bashrc o .config/fish/config.fish)

### Bash

```bash
# Jenkins
alias jlogs='docker logs jenkins -f'
alias jrestart='docker restart jenkins'
alias jpipeline='docker exec jenkins tail -f /var/jenkins_home/jobs/todo-app-cicd/builds/lastBuild/log'

# Kubernetes
alias k='kubectl'
alias kgp='kubectl get pods -n todo-app'
alias klogs='kubectl logs -f -n todo-app'
alias kexec='kubectl exec -it -n todo-app'

# Deploy
alias deploy='cd ansible && ansible-playbook -i inventory/hosts playbooks/deploy-gcp.yml'
```

### Fish

```fish
# Jenkins
alias jlogs='docker logs jenkins -f'
alias jrestart='docker restart jenkins'
alias jpipeline='docker exec jenkins tail -f /var/jenkins_home/jobs/todo-app-cicd/builds/lastBuild/log'

# Kubernetes
alias k='kubectl'
alias kgp='kubectl get pods -n todo-app'
alias klogs='kubectl logs -f -n todo-app'
alias kexec='kubectl exec -it -n todo-app'

# Deploy
alias deploy='cd ansible && ansible-playbook -i inventory/hosts playbooks/deploy-gcp.yml'
```

## 🎯 Cheatsheet PDF

Para generar un PDF de este cheatsheet:

```bash
# Instalar pandoc
sudo apt install pandoc texlive-latex-base

# Generar PDF
pandoc QUICK-REFERENCE.md -o cicd-cheatsheet.pdf
```

## 📞 Contactos de Emergencia

```
# En caso de problemas:
1. Check Jenkins logs
2. Check Kubernetes events
3. Check application logs
4. Rollback si es necesario
5. Contactar al equipo

# Links útiles:
Jenkins Dashboard: http://localhost:8080
GCP Console: https://console.cloud.google.com
GitHub Repo: https://github.com/USER/REPO
```

---

**💡 Tip:** Guarda este archivo como favorito. Contiene todos los comandos que necesitarás día a día.
