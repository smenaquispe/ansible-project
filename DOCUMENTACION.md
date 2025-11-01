# 📚 Documentación del Proyecto - Todo App con IaC

## 1. 🛠️ Herramienta de Infrastructure as Code (IaC)

**Herramienta Principal:** **Ansible**

- **Versión:** >= 10.0
- **Colecciones utilizadas:** `kubernetes.core`
- **Propósito:** Automatización del aprovisionamiento de infraestructura en GCP (Google Cloud Platform) y despliegue de aplicaciones en Kubernetes (GKE)

### ¿Por qué Ansible?

- Automatiza la creación y gestión de clusters GKE
- Despliega aplicaciones de forma declarativa
- Gestiona configuraciones mediante playbooks YAML
- No requiere agentes en los nodos

---

## 2. 📁 Carpetas Importantes del Proyecto

### `ansible/`

**Núcleo de la infraestructura como código**

```
ansible/
├── ansible.cfg              # Configuración de Ansible
├── inventory/hosts          # Inventario de hosts (localhost, gcp)
├── group_vars/             # Variables por grupos
│   ├── all.yml             # Variables globales (Docker, K8s, timeouts)
│   └── gcp.yml             # Variables específicas de GCP
├── playbooks/              # Playbooks de automatización
│   ├── create-cluster.yml  # Crea cluster GKE
│   ├── delete-cluster.yml  # Elimina cluster GKE
│   ├── deploy-gcp.yml      # Despliega app en GKE
│   └── deploy.yml          # Despliega app localmente (Kind)
└── roles/                  # Roles reutilizables
    └── deploy-app/
```

**Archivos clave:**

- `group_vars/all.yml`: Configuración de imágenes Docker, namespace, réplicas
- `group_vars/gcp.yml`: Configuración GCP (proyecto, zona, región)
- `playbooks/create-cluster.yml`: Provisiona infraestructura en GCP
- `playbooks/deploy-gcp.yml`: Despliega la aplicación

### `kubernetes/`

**Manifiestos de Kubernetes**

```
kubernetes/
├── base/                   # Manifiestos para despliegue local (Kind)
│   ├── backend.yaml
│   ├── frontend.yaml
│   ├── db.yaml
│   └── kind-config.yaml
└── gcp/                    # Manifiestos para GCP/GKE
    ├── backend-gcp.yaml    # Deployment + Service + HPA
    ├── frontend-gcp.yaml   # Deployment + Service + HPA
    ├── db-gcp.yaml         # StatefulSet para PostgreSQL
    ├── ingress-gcp.yaml    # Load Balancer de GCP
    └── namespace.yaml      # Namespace todo-app
```

### `scripts/`

**Scripts de automatización (Fish shell)**

```
scripts/
├── create-cluster.fish     # Wrapper para crear cluster
├── delete-cluster.fish     # Wrapper para eliminar cluster
├── deploy.fish             # Wrapper para desplegar app
├── push-images.fish        # Sube imágenes a Docker Hub
└── utils.fish              # Funciones auxiliares
```

### `src/app/`

**Código fuente de la aplicación**

```
src/app/
├── backend/                # API Node.js + Express
├── frontend/               # React + Vite
└── db/                     # PostgreSQL con scripts init
```

---

## 3. 🔌 Configuraciones de Conexión con GCP

### 📍 Ubicación: `ansible/group_vars/all.yml` (líneas 18-28)

```yaml
# ============================================================================
# GOOGLE CLOUD PLATFORM (GCP)
# ============================================================================
gcp_project_id: "" # Se obtiene de gcloud config si está vacío
gcp_zone: us-central1-a # Zona de disponibilidad
gcp_region: us-central1 # Región de GCP

# ============================================================================
# KUBERNETES CLUSTER (GKE)
# ============================================================================
cluster_name: todo-app-cluster
machine_type: e2-small # Tipo de máquina para nodos
num_nodes: 2 # Número inicial de nodos
```

### 📍 Ubicación: `ansible/playbooks/create-cluster.yml` (líneas 12-18)

**Obtención dinámica del Project ID:**

```yaml
tasks:
  - name: Get GCP project ID
    set_fact:
      actual_project_id: "{{ gcp_project_id if (gcp_project_id is defined and gcp_project_id | length > 0) else lookup('pipe', 'gcloud config get-value project 2>/dev/null') }}"
```

**Comando gcloud ejecutado para crear el cluster (líneas 51-68):**

```yaml
- name: Create GKE cluster
  command: >
    gcloud container clusters create {{ cluster_name }}
    --zone={{ gcp_zone }}
    --project={{ actual_project_id }}
    --machine-type={{ machine_type }}
    --num-nodes={{ num_nodes }}
    --disk-size={{ disk_size }}
    --disk-type={{ disk_type }}
    --enable-autoscaling                    # ← AUTOESCALAMIENTO ACTIVADO
    --min-nodes={{ min_nodes }}             # ← MÍNIMO DE NODOS
    --max-nodes={{ max_nodes }}             # ← MÁXIMO DE NODOS
    --enable-autorepair
    --enable-autoupgrade
    {% if not enable_cloud_logging %}--no-enable-cloud-logging{% endif %}
    {% if not enable_cloud_monitoring %}--no-enable-cloud-monitoring{% endif %}
    --addons={{ cluster_addons | join(',') }}
```

### 🔑 Autenticación

Ansible utiliza **gcloud CLI** configurado previamente:

```bash
# Autenticación con GCP
gcloud auth login

# Configurar proyecto por defecto
gcloud config set project TU_PROJECT_ID

# Obtener credenciales del cluster
gcloud container clusters get-credentials todo-app-cluster \
  --zone=us-central1-a
```

---

## 4. ⚡ Configuraciones de Autoescalamiento

### 🌐 A. Autoescalamiento de NODOS en GCP (Cluster Level)

**Configuración de GKE Node Autoscaling**

#### 📍 Ubicación: `ansible/group_vars/all.yml` (líneas 30-32)

```yaml
# Autoscaling
min_nodes: 2 # Mínimo de nodos en el cluster
max_nodes: 5 # Máximo de nodos en el cluster
```

#### 📍 Aplicación: `ansible/playbooks/create-cluster.yml` (líneas 51-68)

```yaml
- name: Create GKE cluster
  command: >
    gcloud container clusters create {{ cluster_name }}
    --enable-autoscaling              # ← ACTIVA AUTOESCALAMIENTO
    --min-nodes={{ min_nodes }}       # ← min_nodes: 2
    --max-nodes={{ max_nodes }}       # ← max_nodes: 5
```

**¿Cómo funciona?**

- GKE añade nodos automáticamente cuando los pods no pueden ser programados por falta de recursos
- Elimina nodos cuando hay capacidad sobrante y los pods pueden redistribuirse
- Responde a la demanda de CPU y memoria del cluster

---

### 🔄 B. Autoescalamiento de PODS en Kubernetes (HPA)

**Horizontal Pod Autoscaler (HPA) v2**

#### 📍 Backend: `kubernetes/gcp/backend-gcp.yaml` (líneas 71-87)

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: todo-backend-hpa
  namespace: todo-app
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: todo-backend
  minReplicas: 2 # ← Mínimo de pods backend
  maxReplicas: 5 # ← Máximo de pods backend
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 20 # ← Umbral: 20% CPU
```

#### 📍 Frontend: `kubernetes/gcp/frontend-gcp.yaml` (líneas 53-69)

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: todo-frontend-hpa
  namespace: todo-app
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: todo-frontend
  minReplicas: 2 # ← Mínimo de pods frontend
  maxReplicas: 5 # ← Máximo de pods frontend
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 20 # ← Umbral: 20% CPU
```

**¿Cómo funciona el HPA?**

- Monitorea el uso de CPU de los pods
- Si el promedio de CPU supera el 20%, escala horizontalmente (añade pods)
- Si el uso baja, reduce el número de pods (hasta el mínimo configurado)
- Requiere que los pods tengan `resources.requests` definidos

#### 📊 Requisitos para que funcione el HPA:

```yaml
# En cada Deployment debe haber:
resources:
  requests:
    memory: "128Mi"
    cpu: "100m" # ← REQUERIDO para HPA
  limits:
    memory: "256Mi"
    cpu: "250m"
```

---

## 📊 Resumen de Autoescalamiento

| Nivel                   | Componente    | Mínimo  | Máximo  | Métrica              | Archivo                            |
| ----------------------- | ------------- | ------- | ------- | -------------------- | ---------------------------------- |
| **Cluster (Nodos GCP)** | VM Instances  | 2 nodos | 5 nodos | Recursos del cluster | `group_vars/all.yml`               |
| **Backend Pods**        | todo-backend  | 2 pods  | 5 pods  | 20% CPU              | `kubernetes/gcp/backend-gcp.yaml`  |
| **Frontend Pods**       | todo-frontend | 2 pods  | 5 pods  | 20% CPU              | `kubernetes/gcp/frontend-gcp.yaml` |

---

## 🚀 Comandos Útiles

```bash
# Crear cluster en GCP con autoescalamiento
ansible-playbook -i ansible/inventory/hosts ansible/playbooks/create-cluster.yml

# Desplegar aplicación (incluye HPAs)
ansible-playbook -i ansible/inventory/hosts ansible/playbooks/deploy-gcp.yml

# Ver estado del HPA
kubectl get hpa -n todo-app

# Ver detalles del autoescalamiento de nodos
gcloud container clusters describe todo-app-cluster \
  --zone=us-central1-a \
  --format="value(autoscaling)"

# Eliminar cluster
ansible-playbook -i ansible/inventory/hosts ansible/playbooks/delete-cluster.yml
```

---

## 💰 Información de Costos

Según `group_vars/all.yml` (líneas 77-81):

```yaml
estimated_costs:
  gke_management: "$74/mes"
  load_balancer: "$18/mes"
  total: "$92/mes"
  free_tier: "$300 créditos por 90 días"
```

**Optimizaciones aplicadas para reducir costos:**

- Cloud Logging: deshabilitado (`enable_cloud_logging: false`)
- Cloud Monitoring: deshabilitado (`enable_cloud_monitoring: false`)
- Máquinas pequeñas (`e2-small`)
- Disco HDD estándar (`pd-standard`)

---

## 📖 Documentación Adicional

Consulta estos archivos para más información:

- `README.md` - Guía completa del proyecto
- `QUICKSTART.md` - Inicio rápido
- `docs/README-GCP-DEPLOYMENT.md` - Despliegue en GCP
- `docs/WORKFLOW.md` - Flujo de trabajo
