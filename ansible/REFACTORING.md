# Refactorización de Playbooks Ansible - GCP

## 🎯 Objetivo

Refactorizar los playbooks de Ansible para usar **módulos nativos** en lugar de comandos CLI (`gcloud`), siguiendo las mejores prácticas de Ansible.

## ❌ Problemas del Enfoque Anterior

### Uso de `command: gcloud ...`

```yaml
# ❌ Anti-patrón: Usando Ansible como wrapper de CLI
- name: Create GKE cluster
  command: >
    gcloud container clusters create {{ cluster_name }}
    --zone={{ gcp_zone }}
    --project={{ actual_project_id }}
    --machine-type={{ machine_type }}
    --num-nodes={{ num_nodes }}
    --quiet
```

**Problemas:**

1. **No es idempotente**: Ejecuta el comando cada vez, incluso si el cluster ya existe
2. **Manejo de errores deficiente**: Solo obtienes códigos de retorno, no estados estructurados
3. **No es declarativo**: Describes "cómo hacerlo" en lugar de "qué quieres"
4. **Difícil de testear**: No hay modo de dry-run real
5. **Parsing manual**: Necesitas parsear salida de texto con regex
6. **No es portable**: Depende de que `gcloud` esté instalado y configurado
7. **Ansible se convierte en un script glorificado**: Pierdes los beneficios de Ansible

## ✅ Solución: Módulos Nativos de Ansible

### Uso de `google.cloud.gcp_container_cluster`

```yaml
# ✅ Buena práctica: Usando módulos declarativos
- name: Create GKE cluster
  google.cloud.gcp_container_cluster:
    name: "{{ cluster_name }}"
    location: "{{ gcp_zone }}"
    project: "{{ gcp_project_id }}"
    auth_kind: application
    initial_node_count: "{{ num_nodes }}"
    node_config:
      machine_type: "{{ machine_type }}"
      disk_size_gb: "{{ disk_size }}"
    autoscaling:
      enabled: true
      min_node_count: "{{ min_nodes }}"
      max_node_count: "{{ max_nodes }}"
    state: present
```

**Beneficios:**

1. **Idempotente**: Solo crea el cluster si no existe
2. **Declarativo**: Describes el estado deseado, Ansible se encarga del resto
3. **Check mode**: Puedes hacer dry-runs con `--check`
4. **Manejo de errores robusto**: Excepciones estructuradas, no códigos de error
5. **Retorna datos estructurados**: JSON/dict, fácil de usar en otras tareas
6. **Documentación integrada**: `ansible-doc google.cloud.gcp_container_cluster`
7. **No depende de CLI externa**: Usa la API de GCP directamente

## 📊 Comparación

| Aspecto                 | `command: gcloud`     | Módulos Nativos  |
| ----------------------- | --------------------- | ---------------- |
| **Idempotencia**        | ❌ Manual             | ✅ Automática    |
| **Declarativo**         | ❌ Imperativo         | ✅ Declarativo   |
| **Check mode**          | ❌ No funciona        | ✅ Completo      |
| **Datos estructurados** | ❌ Texto plano        | ✅ JSON/dict     |
| **Manejo de errores**   | ❌ Códigos de retorno | ✅ Excepciones   |
| **Dependencias**        | `gcloud` CLI          | Python libraries |
| **Portabilidad**        | ❌ Requiere gcloud    | ✅ Solo Python   |
| **Testing**             | ❌ Difícil            | ✅ Fácil         |

## 🔧 Cambios Realizados

### 1. Playbooks Refactorizados

#### `create-cluster.yml`

- ❌ `command: gcloud services enable`
- ✅ `google.cloud.gcp_serviceusage_service`

- ❌ `command: gcloud container clusters create`
- ✅ `google.cloud.gcp_container_cluster`

- ❌ `command: kubectl cluster-info`
- ✅ `kubernetes.core.k8s_cluster_info`

#### `delete-cluster.yml`

- ❌ `command: gcloud container clusters describe`
- ✅ `google.cloud.gcp_container_cluster_info`

- ❌ `command: gcloud container clusters delete`
- ✅ `google.cloud.gcp_container_cluster` (state: absent)

#### `update-cluster.yml`

- ❌ `command: gcloud container clusters update`
- ✅ `google.cloud.gcp_container_cluster` (idempotente)

- ❌ `command: gcloud container clusters resize`
- ✅ Incluido en el módulo de cluster

#### `deploy-gcp.yml`

- ✅ Ya usaba `kubernetes.core.k8s` (correcto)
- ✅ Eliminado `kubeconfig_path` (usa el default)
- ✅ Mejorado uso de `k8s_cluster_info` para validación

### 2. Variables Actualizadas

#### `group_vars/all.yml`

- ❌ Eliminado: `estimated_costs` (información no relevante)
- ✅ Agregado: `gcp_auth_kind: application` (documentación de autenticación)

### 3. Documentación Nueva

- ✅ `requirements.yml` - Colecciones de Ansible necesarias
- ✅ `requirements.txt` - Dependencias de Python
- ✅ `README.md` - Actualizado con instrucciones de instalación y uso
- ✅ `REFACTORING.md` - Este documento

## 🚀 Instalación

### 1. Dependencias de Python

```bash
pip install -r ansible/requirements.txt
```

Instala:

- `google-auth` - Autenticación con GCP
- `requests` - Cliente HTTP
- `kubernetes` - Cliente de Kubernetes
- `ansible` - Ansible core

### 2. Colecciones de Ansible

```bash
ansible-galaxy collection install -r ansible/requirements.yml
```

Instala:

- `google.cloud` - Módulos para GCP
- `kubernetes.core` - Módulos para Kubernetes

### 3. Autenticación GCP

**Opción A: Usuario (desarrollo)**

```bash
gcloud auth application-default login
```

**Opción B: Service Account (producción/CI)**

```bash
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account.json"
```

## 📝 Uso

Los comandos siguen siendo los mismos:

```bash
# Crear cluster
ansible-playbook -i ansible/inventory/hosts ansible/playbooks/create-cluster.yml

# Desplegar aplicación
ansible-playbook -i ansible/inventory/hosts ansible/playbooks/deploy-gcp.yml

# Actualizar cluster
ansible-playbook -i ansible/inventory/hosts ansible/playbooks/update-cluster.yml

# Eliminar cluster
ansible-playbook -i ansible/inventory/hosts ansible/playbooks/delete-cluster.yml
```

O usar los scripts wrapper en `scripts/`:

```bash
./scripts/create-cluster.fish
./scripts/deploy.fish
./scripts/delete-cluster.fish
```

## ✨ Ventajas de la Nueva Arquitectura

### 1. Verdadera Idempotencia

```bash
# Puedes ejecutar esto múltiples veces sin problemas
ansible-playbook playbooks/create-cluster.yml
# Primera vez: crea el cluster
# Segunda vez: "ok" (no cambia nada)
# Tercera vez: "ok" (no cambia nada)
```

### 2. Check Mode (Dry Run)

```bash
# Ver qué cambiaría sin aplicar cambios
ansible-playbook playbooks/create-cluster.yml --check --diff
```

### 3. Manejo de Estado Estructurado

```yaml
- name: Create cluster
  google.cloud.gcp_container_cluster:
    name: my-cluster
    state: present
  register: cluster

- name: Use cluster endpoint
  debug:
    msg: "Cluster endpoint: {{ cluster.endpoint }}"
```

### 4. Mejor Debugging

```bash
# Ver todos los módulos disponibles
ansible-doc -l google.cloud

# Ver documentación de un módulo
ansible-doc google.cloud.gcp_container_cluster

# Verbose output estructurado
ansible-playbook playbooks/create-cluster.yml -vvv
```

## 🎓 Mejores Prácticas Aplicadas

1. ✅ **Usar módulos nativos en lugar de `command`/`shell`**
2. ✅ **Declarar estado deseado, no pasos imperativos**
3. ✅ **Aprovechar la idempotencia de Ansible**
4. ✅ **Usar `ansible.builtin.*` para claridad**
5. ✅ **Centralizar variables en `group_vars/`**
6. ✅ **Documentar requisitos explícitamente**
7. ✅ **Validar configuración antes de ejecutar**
8. ✅ **Retornar datos estructurados para reutilizar**

## 📚 Referencias

- [Ansible Google Cloud Guide](https://docs.ansible.com/ansible/latest/scenario_guides/guide_gce.html)
- [google.cloud Collection](https://galaxy.ansible.com/google/cloud)
- [kubernetes.core Collection](https://galaxy.ansible.com/kubernetes/core)
- [Best Practices - Don't use shell/command](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
