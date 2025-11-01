# 🗂️ Estructura de Archivos GCP

```
todo-app/gcp/
├── README-GCP-DEPLOYMENT.md    # 📚 Guía completa de despliegue
├── CHECKLIST.md                # ✅ Checklist pre-despliegue
├── namespace.yaml              # Namespace de Kubernetes
├── db-gcp.yaml                 # PostgreSQL + PVC + Secret
├── backend-gcp.yaml            # Backend Node.js + Service
├── frontend-gcp.yaml           # Frontend React + Service
├── ingress-gcp.yaml            # Load Balancer de GCP
├── deploy-gcp.sh               # Script automatizado (Bash)
└── deploy-gcp.fish             # Script automatizado (Fish Shell)
```

## 📋 Descripción de Archivos

### Configuración de Kubernetes

#### `namespace.yaml`

- Crea el namespace `todo-app`
- Aísla los recursos de la aplicación

#### `db-gcp.yaml`

- **PersistentVolumeClaim**: 5Gi de almacenamiento (GCP standard-rwo)
- **Deployment**: PostgreSQL con límites de recursos
- **Service**: ClusterIP (solo acceso interno)
- **Secret**: Contraseña de la base de datos

#### `backend-gcp.yaml`

- **Deployment**: 2 réplicas de Node.js backend
- **Resources**: 128Mi-256Mi RAM, 100m-250m CPU
- **Probes**: Liveness y Readiness para /health
- **Service**: ClusterIP en puerto 5000
- **HPA** (comentado): Para escalado automático

#### `frontend-gcp.yaml`

- **Deployment**: 2 réplicas de React frontend
- **Resources**: 128Mi-256Mi RAM, 100m-250m CPU
- **Probes**: Liveness y Readiness para /
- **Service**: ClusterIP en puerto 80
- **HPA** (comentado): Para escalado automático

#### `ingress-gcp.yaml`

- **Ingress**: GCP Load Balancer (clase `gce`)
- **Rutas**:
  - `/api/*` → Backend
  - `/*` → Frontend
- **SSL** (opcional): Managed Certificates

### Scripts de Despliegue

#### `deploy-gcp.fish`

- Script automatizado para Fish Shell
- Pasos:
  1. Configurar proyecto GCP
  2. Habilitar APIs
  3. Crear cluster GKE
  4. Desplegar aplicación
  5. Configurar Load Balancer
  6. Mostrar información de acceso

#### `deploy-gcp.sh`

- Mismo script pero para Bash/Zsh

### Documentación

#### `README-GCP-DEPLOYMENT.md`

- Guía completa paso a paso
- Prerequisitos detallados
- Troubleshooting
- Monitoreo y costos

#### `CHECKLIST.md`

- Verificación pre-despliegue
- Lista de comprobación
- Links útiles

## 🔄 Diferencias con Configuración Local (Kind)

| Aspecto             | Local (Kind)      | GCP (GKE)                          |
| ------------------- | ----------------- | ---------------------------------- |
| **Services**        | NodePort          | ClusterIP + Ingress                |
| **Storage**         | hostPath          | GCP Persistent Disk (standard-rwo) |
| **Load Balancer**   | Port Mapping      | GCP Cloud Load Balancer            |
| **Resource Limits** | Sin límites       | Requests/Limits definidos          |
| **HPA**             | 3-8 réplicas      | Deshabilitado (Free Tier)          |
| **Namespace**       | Sin namespace     | `todo-app` namespace               |
| **Secrets**         | Hardcoded en YAML | Kubernetes Secrets                 |
| **Ingress**         | No usado          | GCP Ingress Controller             |

## 🎯 Orden de Despliegue

1. **namespace.yaml** - Crear namespace primero
2. **db-gcp.yaml** - Base de datos y storage
3. **backend-gcp.yaml** - Backend (depende de DB)
4. **frontend-gcp.yaml** - Frontend (depende de Backend)
5. **ingress-gcp.yaml** - Load Balancer (último)

## 💰 Recursos GCP Utilizados

### Compute

- **GKE Cluster**: Control plane + 2 worker nodes
- **Machine Type**: e2-small (2 vCPU, 2GB RAM por nodo)
- **Disk**: 20GB standard persistent disk por nodo

### Storage

- **PersistentVolume**: 5Gi standard-rwo para PostgreSQL

### Networking

- **Load Balancer**: GCP HTTP(S) Load Balancer
- **IP Externa**: 1 IP pública estática

### Costo Estimado

- **Total**: ~$146/mes
- **Cubierto por**: $300 Free Trial (2 meses gratis)

## 🔐 Seguridad

### Secretos

- ⚠️ `db-secret` tiene contraseña por defecto
- 🔒 **IMPORTANTE**: Cambiar en producción
- ✅ Mejor práctica: Usar Google Secret Manager

### Mejoras Recomendadas

```bash
# Crear secret desde archivo
kubectl create secret generic db-secret \
  --from-literal=password=$(openssl rand -base64 32) \
  -n todo-app

# O usar Google Secret Manager
gcloud secrets create db-password --data-file=password.txt
```

## 📊 Monitoreo

### Comandos Útiles

```bash
# Ver todos los recursos
kubectl get all -n todo-app

# Ver uso de recursos
kubectl top nodes
kubectl top pods -n todo-app

# Ver logs
kubectl logs -l app=todo-backend -n todo-app -f

# Describir recursos
kubectl describe ingress todo-app-ingress -n todo-app
```

## 🧹 Limpieza

### Opción 1: Eliminar solo la app

```bash
kubectl delete namespace todo-app
kubectl delete ingress todo-app-ingress -n todo-app
```

### Opción 2: Eliminar todo

```bash
gcloud container clusters delete todo-app-cluster --zone=us-central1-a
```

## 📚 Referencias

- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [Kubernetes Best Practices](https://cloud.google.com/architecture/best-practices-for-running-cost-effective-kubernetes-applications-on-gke)
- [GCP Free Tier](https://cloud.google.com/free/docs/gcp-free-tier)
