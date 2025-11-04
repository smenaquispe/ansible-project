# 🔄 Workflow CI/CD - Cluster + Jenkins

Este documento explica el flujo de trabajo para crear la infraestructura y usar Jenkins para CI/CD.

## 📋 Flujo de Trabajo

### 1️⃣ **Crear Infraestructura (UNA SOLA VEZ)**

Usa los scripts de Fish para crear el cluster e infraestructura inicial:

```bash
# 1. Crear el cluster GKE (2 nodos, e2-small)
./scripts/create-cluster.fish

# 2. Desplegar la aplicación e ingress
./scripts/deploy.fish
```

Esto creará:
- ✅ Cluster GKE con 2 nodos (configurado en `ansible/group_vars/all.yml`)
- ✅ Namespace `todo-app`
- ✅ Deployments: frontend, backend, database
- ✅ Services
- ✅ Ingress con Load Balancer

### 2️⃣ **CI/CD Automático con Jenkins**

Una vez creada la infraestructura, Jenkins se encarga de:

#### **Cuando cambias CÓDIGO** (archivos en `src/`):
1. ✅ Detecta cambios en código
2. ✅ Ejecuta tests
3. ✅ Construye imágenes Docker
4. ✅ Sube imágenes a GCR
5. ✅ Se conecta al cluster existente
6. ✅ **Actualiza solo las imágenes** de los deployments
7. ✅ Verifica que el rollout fue exitoso

```groovy
// Jenkins ejecuta:
kubectl set image deployment/todo-frontend \
    todo-frontend=gcr.io/PROJECT_ID/todo-frontend:BUILD_TAG \
    -n todo-app

kubectl set image deployment/todo-backend \
    todo-backend=gcr.io/PROJECT_ID/todo-backend:BUILD_TAG \
    -n todo-app

kubectl set image deployment/todo-db \
    todo-db=gcr.io/PROJECT_ID/todo-db:BUILD_TAG \
    -n todo-app
```

#### **Cuando cambias INFRAESTRUCTURA** (archivos en `kubernetes/` o `ansible/`):
1. ✅ Detecta cambios en manifests
2. ✅ Se conecta al cluster
3. ✅ Aplica los manifests modificados con `kubectl apply`
4. ✅ Verifica el estado

## 🎯 ¿Qué hace cada herramienta?

### **Scripts de Fish (Ansible)**
- ✅ Crear/eliminar cluster
- ✅ Despliegue inicial completo
- ✅ Configuración de infraestructura

### **Jenkins CI/CD**
- ✅ Detección automática de cambios
- ✅ Tests automáticos
- ✅ Build y push de imágenes Docker
- ✅ **Actualización de deployments existentes**
- ✅ Verificación de rollout

## 📝 Comandos Útiles

### Verificar estado del cluster
```bash
kubectl get nodes
kubectl get all -n todo-app
kubectl get ingress -n todo-app
```

### Recrear infraestructura (si es necesario)
```bash
# Eliminar cluster
./scripts/delete-cluster.fish

# Recrear todo
./scripts/create-cluster.fish
./scripts/deploy.fish
```

### Actualización manual (sin Jenkins)
```bash
# Redesplegar con Ansible
./scripts/deploy.fish --update

# O manualmente con kubectl
kubectl rollout restart deployment/todo-frontend -n todo-app
kubectl rollout restart deployment/todo-backend -n todo-app
kubectl rollout restart deployment/todo-db -n todo-app
```

### Ver logs
```bash
# Backend
kubectl logs -l app=todo-backend -n todo-app --tail=50 -f

# Frontend
kubectl logs -l app=todo-frontend -n todo-app --tail=50 -f

# Database
kubectl logs -l app=todo-db -n todo-app --tail=50 -f
```

## 🔧 Configuración

### Cluster (en `ansible/group_vars/all.yml`)
```yaml
cluster_name: todo-app-cluster
machine_type: e2-small      # 2 vCPUs, 2 GB RAM
num_nodes: 2                # 2 nodos totales en la región
min_nodes: 2                # Mínimo para autoscaling
max_nodes: 5                # Máximo para autoscaling
```

### Jenkins (en `Jenkinsfile`)
```groovy
environment {
    PROJECT_ID = credentials('gcp-project-id')
    GCP_REGION = 'us-central1'
    GKE_CLUSTER = 'todo-app-cluster'
    DOCKER_REGISTRY = "gcr.io/${PROJECT_ID}"
    // ...
}
```

## ⚠️ Importante

1. **NO intentes crear el cluster desde Jenkins** - Usa los scripts de Fish
2. **Jenkins solo actualiza deployments existentes** - No crea recursos nuevos
3. **Si cambias manifests de K8s**, Jenkins los aplicará automáticamente
4. **El cluster debe estar corriendo** antes de que Jenkins intente desplegar

## 🚀 Ejemplo de Flujo Completo

```bash
# 1. Setup inicial (UNA SOLA VEZ)
./scripts/create-cluster.fish
./scripts/deploy.fish

# 2. Obtener IP del Load Balancer
kubectl get ingress -n todo-app

# 3. Hacer cambios en el código
vim src/app/frontend/src/App.jsx

# 4. Commit y push
git add .
git commit -m "feat: Nuevo feature en frontend"
git push origin master

# 5. Jenkins automáticamente:
#    - Detecta el cambio (webhook)
#    - Ejecuta tests
#    - Build de imágenes
#    - Push a GCR
#    - Actualiza deployment en GKE
#    - Verifica rollout

# 6. Verificar despliegue
kubectl rollout status deployment/todo-frontend -n todo-app
kubectl get pods -n todo-app
```

## 📊 Stages del Pipeline Jenkins

```
1. Checkout              → Clone del repositorio
2. Detect Changes        → Detecta si cambió código/infra/config
3. Setup Python Env      → Instala dependencias
4. Run Tests             → Ejecuta pytest
5. Build Docker Images   → Build paralelo (frontend, backend, db)
6. Push Docker Images    → Push a GCR
7. Connect to Cluster    → Get credentials del cluster existente
8. Update Infrastructure → Aplica manifests (si INFRA_CHANGED)
9. Deploy Application    → Actualiza imágenes (si CODE_CHANGED)
10. Verify Deployment    → Verifica rollout exitoso
11. Health Check         → Verifica pods en estado Ready
```

## 🐛 Troubleshooting

### "Error: namespace 'todo-app' no existe"
**Solución:** Ejecuta primero `./scripts/deploy.fish` para crear la infraestructura

### "Error: cluster not found"
**Solución:** Ejecuta `./scripts/create-cluster.fish` para crear el cluster

### "Timeout waiting for rollout"
**Solución:** Verifica los logs de los pods:
```bash
kubectl describe pod <pod-name> -n todo-app
kubectl logs <pod-name> -n todo-app
```

### "Quota exceeded"
**Solución:** Verifica tu configuración en `all.yml`:
- `num_nodes: 2` (no más de 2-4 nodos)
- `machine_type: e2-small` (máquinas pequeñas)
- Elimina recursos no usados en GCP
