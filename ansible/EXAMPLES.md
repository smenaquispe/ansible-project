# Ejemplos de Uso - Playbooks Refactorizados

## 🚀 Instalación Inicial

```bash
# Clonar el repositorio (si aún no lo tienes)
cd /home/smenaq/Documents/UNSA/cloud/ansible-project

# Instalar dependencias de Python
pip install -r ansible/requirements.txt

# Instalar colecciones de Ansible
ansible-galaxy collection install -r ansible/requirements.yml

# Configurar autenticación de GCP
gcloud auth application-default login
```

## 📋 Uso Básico

### 1. Crear Cluster GKE

```bash
# Usando Ansible directamente
cd ansible
ansible-playbook -i inventory/hosts playbooks/create-cluster.yml

# O usando el script wrapper
cd ..
./scripts/create-cluster.fish
```

**Salida esperada:**

```
PLAY [Create GKE Cluster] ***********************

TASK [Validate GCP project ID] ******************
ok: [gcp_host]

TASK [Display cluster configuration] ************
ok: [gcp_host] => {
    "msg": [
        "Project ID:    mi-proyecto-gcp",
        "Zone:          us-central1-a",
        "Cluster Name:  todo-app-cluster",
        "Machine Type:  e2-small",
        "Num Nodes:     2",
        "Autoscaling:   2-5 nodes"
    ]
}

TASK [Enable Container API] *********************
changed: [gcp_host]

TASK [Enable Compute API] ***********************
changed: [gcp_host]

TASK [Create GKE cluster] ***********************
changed: [gcp_host]

TASK [Get cluster credentials] ******************
changed: [gcp_host]

PLAY RECAP **************************************
gcp_host : ok=6 changed=4
```

### 2. Desplegar Aplicación

```bash
# Usando Ansible directamente
cd ansible
ansible-playbook -i inventory/hosts playbooks/deploy-gcp.yml

# O usando el script wrapper
cd ..
./scripts/deploy.fish
```

### 3. Actualizar Cluster

```bash
# Editar variables en ansible/group_vars/all.yml
# Por ejemplo, cambiar num_nodes de 2 a 3

cd ansible
ansible-playbook -i inventory/hosts playbooks/update-cluster.yml
```

### 4. Eliminar Cluster

```bash
cd ansible
ansible-playbook -i inventory/hosts playbooks/delete-cluster.yml
# Escribir 'DELETE' cuando se solicite confirmación
```

## 🔍 Uso Avanzado

### Check Mode (Dry Run)

Ver qué cambios se realizarían sin aplicarlos:

```bash
ansible-playbook -i inventory/hosts playbooks/create-cluster.yml --check
```

### Verbose Mode

Ver información detallada de la ejecución:

```bash
# Nivel 1: Básico
ansible-playbook -i inventory/hosts playbooks/create-cluster.yml -v

# Nivel 2: Medio
ansible-playbook -i inventory/hosts playbooks/create-cluster.yml -vv

# Nivel 3: Detallado
ansible-playbook -i inventory/hosts playbooks/create-cluster.yml -vvv

# Nivel 4: Debug completo
ansible-playbook -i inventory/hosts playbooks/create-cluster.yml -vvvv
```

### Ejecutar Tareas Específicas

```bash
# Listar todos los tags
ansible-playbook -i inventory/hosts playbooks/create-cluster.yml --list-tasks

# Ejecutar desde una tarea específica
ansible-playbook -i inventory/hosts playbooks/create-cluster.yml \
  --start-at-task="Create GKE cluster"
```

### Cambiar Variables en Runtime

```bash
# Override de una variable
ansible-playbook -i inventory/hosts playbooks/create-cluster.yml \
  -e "num_nodes=4"

# Override de múltiples variables
ansible-playbook -i inventory/hosts playbooks/create-cluster.yml \
  -e "num_nodes=4 machine_type=e2-medium"

# Usando un archivo de variables
ansible-playbook -i inventory/hosts playbooks/create-cluster.yml \
  -e "@my-custom-vars.yml"
```

### Limitar a Hosts Específicos

```bash
# Solo ejecutar en el host 'gcp_host'
ansible-playbook -i inventory/hosts playbooks/create-cluster.yml \
  --limit gcp_host
```

## 🔧 Personalización

### Crear Configuración Personalizada

```yaml
# my-custom-vars.yml
---
cluster_name: my-custom-cluster
machine_type: e2-medium
num_nodes: 3
min_nodes: 3
max_nodes: 10
enable_cloud_logging: true
enable_cloud_monitoring: true
```

```bash
ansible-playbook -i inventory/hosts playbooks/create-cluster.yml \
  -e "@my-custom-vars.yml"
```

### Usar Service Account (CI/CD)

```bash
# Configurar variable de entorno
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account.json"

# Ejecutar playbook
ansible-playbook -i inventory/hosts playbooks/create-cluster.yml
```

### Configurar Diferentes Proyectos

```bash
# Proyecto de desarrollo
ansible-playbook -i inventory/hosts playbooks/create-cluster.yml \
  -e "gcp_project_id=mi-proyecto-dev cluster_name=dev-cluster"

# Proyecto de producción
ansible-playbook -i inventory/hosts playbooks/create-cluster.yml \
  -e "gcp_project_id=mi-proyecto-prod cluster_name=prod-cluster"
```

## 🧪 Testing y Validación

### Verificar Sintaxis

```bash
# Verificar sintaxis de un playbook
ansible-playbook --syntax-check playbooks/create-cluster.yml

# Verificar sintaxis de todos los playbooks
for playbook in playbooks/*.yml; do
  echo "Checking $playbook..."
  ansible-playbook --syntax-check "$playbook"
done
```

### Validar Inventario

```bash
# Ver el inventario parseado
ansible-inventory -i inventory/hosts --list

# Ver variables de un host específico
ansible-inventory -i inventory/hosts --host gcp_host
```

### Validar Conexión

```bash
# Ping a los hosts
ansible -i inventory/hosts gcp -m ping

# Ejecutar un comando ad-hoc
ansible -i inventory/hosts gcp -m shell -a "whoami"
```

## 📊 Monitoreo y Debugging

### Ver Estado del Cluster

```bash
# Después de crear el cluster
kubectl cluster-info
kubectl get nodes
kubectl get all -n todo-app
```

### Ver Logs de Ansible

```bash
# Ejecutar con logging detallado
ANSIBLE_LOG_PATH=./ansible.log \
ansible-playbook -i inventory/hosts playbooks/create-cluster.yml -vv

# Ver el log
cat ansible.log
```

### Debug de Módulos

```bash
# Ver documentación de un módulo
ansible-doc google.cloud.gcp_container_cluster

# Ver ejemplos de uso
ansible-doc google.cloud.gcp_container_cluster | grep -A 50 EXAMPLES

# Listar todos los módulos de google.cloud
ansible-doc -l google.cloud
```

## 🎯 Casos de Uso Comunes

### Desarrollo Local → GCP

```bash
# 1. Desarrollar localmente con Kind
./scripts/create-cluster.fish  # Crea cluster local
./scripts/deploy.fish          # Despliega en local

# 2. Testear cambios

# 3. Desplegar en GCP
cd ansible
ansible-playbook -i inventory/hosts playbooks/create-cluster.yml
ansible-playbook -i inventory/hosts playbooks/deploy-gcp.yml
```

### Actualizar Aplicación

```bash
# 1. Hacer cambios en el código
# 2. Construir y pushear imágenes
./scripts/push-images.fish

# 3. Redesplegar (usa las nuevas imágenes)
cd ansible
ansible-playbook -i inventory/hosts playbooks/deploy-gcp.yml
```

### Escalar Cluster

```bash
# Editar ansible/group_vars/all.yml
# Cambiar: num_nodes: 2 → num_nodes: 4

# Aplicar cambios
cd ansible
ansible-playbook -i inventory/hosts playbooks/update-cluster.yml
```

### Disaster Recovery

```bash
# Backup: Exportar configuración actual
kubectl get all -n todo-app -o yaml > backup.yaml

# Recrear cluster
cd ansible
ansible-playbook -i inventory/hosts playbooks/delete-cluster.yml
ansible-playbook -i inventory/hosts playbooks/create-cluster.yml

# Restaurar aplicación
ansible-playbook -i inventory/hosts playbooks/deploy-gcp.yml
```

## 🐛 Troubleshooting

### Error: Authentication Failed

```bash
# Verificar autenticación
gcloud auth list

# Re-autenticar
gcloud auth application-default login
```

### Error: API Not Enabled

```bash
# Habilitar APIs manualmente
gcloud services enable container.googleapis.com
gcloud services enable compute.googleapis.com
```

### Error: Module Not Found

```bash
# Reinstalar colecciones
ansible-galaxy collection install google.cloud --force
ansible-galaxy collection install kubernetes.core --force
```

### Error: Cluster Already Exists

```bash
# La idempotencia debería manejar esto automáticamente
# Si falla, ejecutar con verbose para ver detalles
ansible-playbook -i inventory/hosts playbooks/create-cluster.yml -vvv
```

### Ver Estado de Resources en GCP

```bash
# Listar clusters
gcloud container clusters list

# Describir cluster específico
gcloud container clusters describe todo-app-cluster --zone=us-central1-a

# Ver nodos
gcloud compute instances list

# Ver discos
gcloud compute disks list

# Ver load balancers
gcloud compute forwarding-rules list
```

## 📚 Referencias

- [Ansible Documentation](https://docs.ansible.com/)
- [Google Cloud Collection](https://galaxy.ansible.com/google/cloud)
- [Kubernetes Core Collection](https://galaxy.ansible.com/kubernetes/core)
- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
