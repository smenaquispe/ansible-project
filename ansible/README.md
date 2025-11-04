# Ansible Configuration

Esta carpeta contiene toda la configuración y playbooks de Ansible para gestionar el despliegue de la aplicación Todo-App en Google Kubernetes Engine (GKE).

## 📁 Estructura

```
ansible/
├── inventory/
│   └── hosts                  # Inventario de Ansible (local y gcp)
├── group_vars/
│   ├── all.yml               # Variables globales para todos los hosts
│   └── gcp.yml               # Variables específicas para GCP
├── playbooks/
│   ├── create-cluster.yml    # Crear cluster GKE
│   ├── delete-cluster.yml    # Eliminar cluster GKE
│   ├── update-cluster.yml    # Actualizar cluster GKE
│   ├── deploy-gcp.yml        # Desplegar aplicación en GKE
│   └── deploy.yml            # Desplegar en Kind (local) - legacy
├── roles/
│   └── deploy-app/           # Rol de deploy (legacy)
├── requirements.yml          # Colecciones de Ansible requeridas
└── requirements.txt          # Dependencias de Python
```

## 🚀 Instalación y Requisitos

### 1. Instalar dependencias de Python

```bash
pip install -r requirements.txt
```

Esto instalará:

- `google-auth` - Autenticación con GCP
- `requests` - Cliente HTTP
- `kubernetes` - Cliente de Kubernetes
- `ansible` - Ansible core

### 2. Instalar colecciones de Ansible

```bash
ansible-galaxy collection install -r requirements.yml
```

Esto instalará:

- `google.cloud` - Módulos para gestionar recursos de GCP
- `kubernetes.core` - Módulos para gestionar recursos de Kubernetes

### 3. Configurar autenticación de GCP

Los playbooks usan **Application Default Credentials (ADC)** de Google Cloud.

**Opción A: Autenticación con cuenta de usuario**

```bash
gcloud auth application-default login
```

**Opción B: Service Account (recomendado para CI/CD)**

```bash
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account.json"
```

## ⚙️ Configuración

Toda la configuración está centralizada en archivos YAML en lugar de hardcodear valores en los scripts.

Los playbooks ahora usan **módulos nativos de Ansible** en lugar de comandos CLI de `gcloud`.

### `group_vars/all.yml`

Contiene todas las variables globales:

- **Docker Hub**: Usuario, registry, nombres de imágenes
- **GCP**: Project ID, zona, región
- **Cluster**: Nombre, tipo de máquina, número de nodos
- **Autoescalamiento**: Políticas de CPU/memoria, umbrales, perfiles
- **Kubernetes**: Namespace, paths de manifiestos
- **Deployment**: Timeouts, número de réplicas

**Para cambiar la configuración**, edita este archivo:

```yaml
# Ejemplo: Cambiar usuario de Docker Hub
docker_user: tu-usuario

# Ejemplo: Cambiar tipo de máquina
machine_type: e2-medium

# Ejemplo: Cambiar número de nodos
num_nodes: 3

# Ejemplo: Configurar políticas de autoescalamiento
cluster_autoscaler_settings:
  cpu_utilization_target: 0.7 # Escalar cuando CPU > 70%
  memory_utilization_target: 0.8 # Escalar cuando memoria > 80%

min_nodes: 2
max_nodes: 5
autoscaling_profile: balanced # balanced u optimize-utilization
```

#### Configuración de Autoescalamiento

El cluster puede autoescalar basándose en el uso de recursos. Configura los umbrales:

```yaml
# Perfil: balanced (equilibrado) u optimize-utilization (ahorro de costos)
autoscaling_profile: balanced

# Políticas personalizables
cluster_autoscaler_settings:
  # Escalar cuando los pods usan este % de CPU/memoria
  cpu_utilization_target: 0.7 # 70%
  memory_utilization_target: 0.8 # 80%

  # Tiempos de espera (en segundos)
  scale_down_delay_after_add: 600 # 10 minutos
  scale_down_unneeded_time: 600 # 10 minutos

  # Umbral para considerar un nodo subutilizado
  scale_down_utilization_threshold: 0.5 # 50%
```

**Ver documentación completa**: [`AUTOSCALING.md`](AUTOSCALING.md)

### `group_vars/gcp.yml`

Variables específicas para despliegues en GCP:

- Paths de manifiestos de GCP
- Orden de despliegue
- Configuración del cluster

## 📖 Playbooks

Los playbooks ahora usan **módulos declarativos de Ansible** para GCP y Kubernetes:

- `google.cloud.gcp_container_cluster` - Gestión de clusters GKE
- `google.cloud.gcp_serviceusage_service` - Habilitación de APIs
- `kubernetes.core.k8s` - Gestión de recursos de Kubernetes
- `kubernetes.core.k8s_info` - Consulta de información de Kubernetes

### 1. Create Cluster (`create-cluster.yml`)

Crea un cluster GKE en Google Cloud Platform usando módulos nativos de Ansible.

**Uso directo**:

```bash
cd ansible
ansible-playbook -i inventory/hosts playbooks/create-cluster.yml
```

**O usar el script wrapper**:

```bash
./scripts/create-cluster.fish
```

**Lo que hace**:

1. Valida que `gcp_project_id` esté configurado
2. Habilita APIs necesarias (Container, Compute) usando `gcp_serviceusage_service`
3. Crea el cluster GKE usando `gcp_container_cluster` (idempotente)
4. Obtiene credenciales de kubectl
5. Verifica la conexión usando `k8s_cluster_info`

**Módulos de Ansible usados**:

- `google.cloud.gcp_serviceusage_service` - Habilitar APIs
- `google.cloud.gcp_container_cluster` - Crear/actualizar cluster
- `kubernetes.core.k8s_cluster_info` - Información del cluster
- `kubernetes.core.k8s_info` - Listar nodos

**Variables usadas**:

- `gcp_project_id` (requerido)
- `gcp_zone`
- `cluster_name`
- `machine_type`
- `num_nodes`
- `min_nodes`, `max_nodes`
- `disk_size`, `disk_type`
- `enable_cloud_logging`, `enable_cloud_monitoring`
- `cluster_addons`

### 2. Deploy App (`deploy-gcp.yml`)

Despliega la aplicación en el cluster GKE usando módulos nativos de Kubernetes.

**Uso directo**:

```bash
cd ansible
ansible-playbook -i inventory/hosts playbooks/deploy-gcp.yml
```

**O usar el script wrapper**:

```bash
./scripts/deploy.fish
```

**Lo que hace**:

1. Verifica conexión al cluster usando `k8s_cluster_info`
2. Crea el namespace `todo-app` usando `k8s`
3. Despliega la base de datos (PostgreSQL) usando `k8s`
4. Espera a que la DB esté lista usando `k8s_info`
5. Despliega el backend (Node.js) usando `k8s`
6. Espera a que el backend esté listo usando `k8s_info`
7. Despliega el frontend (React) usando `k8s`
8. Espera a que el frontend esté listo usando `k8s_info`
9. Crea el Ingress (Load Balancer) usando `k8s`
10. Muestra el estado y la IP externa usando `k8s_info`

**Módulos de Ansible usados**:

- `kubernetes.core.k8s_cluster_info` - Verificar conexión
- `kubernetes.core.k8s` - Aplicar manifiestos
- `kubernetes.core.k8s_info` - Consultar recursos

**Variables usadas**:

- `k8s_namespace`
- `k8s_manifests_dir`
- `pod_ready_retries`
- `pod_ready_delay`

### 3. Update Cluster (`update-cluster.yml`)

Actualiza la configuración de un cluster GKE existente.

**Uso directo**:

```bash
cd ansible
ansible-playbook -i inventory/hosts playbooks/update-cluster.yml
```

**Lo que hace**:

1. Verifica que el cluster existe usando `gcp_container_cluster_info`
2. Muestra configuración actual vs objetivo
3. Actualiza el cluster usando `gcp_container_cluster` (idempotente)
4. Actualiza credenciales de kubectl
5. Muestra los nodos actualizados

**Módulos de Ansible usados**:

- `google.cloud.gcp_container_cluster_info` - Obtener información del cluster
- `google.cloud.gcp_container_cluster` - Actualizar cluster
- `kubernetes.core.k8s_info` - Listar nodos

### 4. Delete Cluster (`delete-cluster.yml`)

Elimina el cluster GKE usando módulos nativos de Ansible.

**Uso directo**:

```bash
cd ansible
ansible-playbook -i inventory/hosts playbooks/delete-cluster.yml
```

**O usar el script wrapper**:

```bash
./scripts/delete-cluster.fish
```

**Lo que hace**:

1. Valida que `gcp_project_id` esté configurado
2. Verifica que el cluster existe usando `gcp_container_cluster_info`
3. Pide confirmación (escribir 'DELETE')
4. Elimina el cluster usando `gcp_container_cluster` con `state: absent`
5. Sugiere verificar recursos huérfanos

**Módulos de Ansible usados**:

- `google.cloud.gcp_container_cluster_info` - Listar clusters
- `google.cloud.gcp_container_cluster` - Eliminar cluster

## 🎯 Inventario

El archivo `inventory/hosts` define dos grupos:

```ini
[local]
localhost ansible_connection=local

[gcp]
localhost ansible_connection=local
```

- **local**: Para despliegues locales en Kind (legacy)
- **gcp**: Para despliegues en GCP/GKE

Las variables del grupo `gcp` se cargan automáticamente desde `group_vars/gcp.yml`.

## 🚀 Workflow Completo

### Primera vez

```bash
# 1. Editar configuración si es necesario
vim ansible/group_vars/all.yml

# 2. Crear cluster
./scripts/create-cluster.fish

# 3. Desplegar aplicación
./scripts/deploy.fish
```

### Actualizar configuración

```bash
# 1. Editar variables
vim ansible/group_vars/all.yml

# Por ejemplo, cambiar número de réplicas:
# backend_replicas: 3

# 2. Re-desplegar
./scripts/deploy.fish
```

### Actualizar aplicación (nuevas imágenes)

```bash
# 1. Subir nuevas imágenes
./scripts/push-images.fish 1.1.0

# 2. Redesplegar
./scripts/deploy.fish --update
```

## 📝 Ejemplos de Configuración

### Cambiar zona de GCP

```yaml
# group_vars/all.yml
gcp_zone: us-east1-b
gcp_region: us-east1
```

### Aumentar número de nodos

```yaml
# group_vars/all.yml
num_nodes: 4
min_nodes: 3
max_nodes: 5
```

### Cambiar tipo de máquina

```yaml
# group_vars/all.yml
machine_type: e2-medium # Más potente que e2-small
```

### Habilitar logging (genera costos adicionales)

```yaml
# group_vars/all.yml
enable_cloud_logging: true
enable_cloud_monitoring: true
```

### Cambiar número de réplicas

```yaml
# group_vars/all.yml
backend_replicas: 3
frontend_replicas: 3
```

### Usar otro registry (GitHub Container Registry)

```yaml
# group_vars/all.yml
docker_registry: ghcr.io
docker_user: tu-usuario-github
```

## 🔧 Variables Disponibles

### Docker & Images

- `docker_user`: Usuario de Docker Hub
- `docker_registry`: Registry a usar (docker.io, ghcr.io, etc.)
- `default_image_version`: Versión por defecto de imágenes
- `backend_image`: Imagen completa del backend
- `frontend_image`: Imagen completa del frontend
- `db_image`: Imagen completa de la DB

### GCP

- `gcp_project_id`: ID del proyecto de GCP
- `gcp_zone`: Zona de GCP
- `gcp_region`: Región de GCP

### Cluster

- `cluster_name`: Nombre del cluster
- `machine_type`: Tipo de máquina (e2-small, e2-medium, etc.)
- `num_nodes`: Número de nodos
- `min_nodes`, `max_nodes`: Límites de autoscaling
- `disk_size`: Tamaño de disco por nodo (GB)
- `disk_type`: Tipo de disco (pd-standard, pd-ssd)
- `enable_cloud_logging`: Habilitar Cloud Logging
- `enable_cloud_monitoring`: Habilitar Cloud Monitoring

### Kubernetes

- `k8s_namespace`: Namespace de Kubernetes
- `k8s_manifests_dir_base`: Path de manifiestos base (Kind)
- `k8s_manifests_dir_gcp`: Path de manifiestos GCP
- `kubeconfig_path`: Path del kubeconfig

### Deployment

- `pod_ready_timeout`: Timeout para pods (segundos)
- `pod_ready_retries`: Número de reintentos
- `pod_ready_delay`: Delay entre reintentos (segundos)
- `backend_replicas`: Réplicas del backend
- `frontend_replicas`: Réplicas del frontend
- `db_replicas`: Réplicas de la DB

## 💡 Best Practices

1. **No hardcodees valores** en los playbooks, usa variables
2. **Edita `group_vars/all.yml`** para cambios globales
3. **Edita `group_vars/gcp.yml`** para cambios específicos de GCP
4. **Usa los scripts** en lugar de ejecutar playbooks directamente
5. **Versioniza cambios** en git cuando edites las variables
6. **Documenta cambios** si modificas valores por defecto

## 🐛 Troubleshooting

### Playbook falla con "kubernetes.core not found"

```bash
ansible-galaxy collection install kubernetes.core
```

### Variables no se aplican

Asegúrate de usar el grupo correcto en el inventario:

```bash
ansible-playbook -i inventory/hosts playbooks/deploy-gcp.yml
# El playbook debe tener: hosts: gcp
```

### Quiero usar valores diferentes temporalmente

Puedes pasar variables por línea de comandos:

```bash
ansible-playbook -i inventory/hosts playbooks/create-cluster.yml \
  -e "num_nodes=4" \
  -e "machine_type=e2-medium"
```

### Quiero ver qué variables se están usando

```bash
ansible-inventory -i inventory/hosts --list --yaml
```

## 📚 Referencias

- [Ansible Documentation](https://docs.ansible.com/)
- [Ansible Kubernetes Collection](https://docs.ansible.com/ansible/latest/collections/kubernetes/core/index.html)
- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [Ansible Variables](https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html)
