# Configuración de Límites de CPU y Memoria

## ✅ Cambios Realizados

Ahora puedes configurar **límites mínimos y máximos de CPU y memoria** directamente en `group_vars/all.yml`.

## 📝 Variables en `all.yml`

```yaml
# Límites de Recursos para Autoescalamiento
resource_limits:
  cpu:
    min: 4 # Mínimo de vCPUs en el cluster
    max: 10 # Máximo de vCPUs en el cluster
  memory:
    min: 4 # Mínimo de GB de memoria en el cluster
    max: 10 # Máximo de GB de memoria en el cluster
```

## 🎯 Cómo Funciona

GKE escalará el número de nodos para mantener el cluster dentro de estos límites de recursos:

### Ejemplo con `e2-small` (2 vCPUs, 2 GB RAM por nodo)

```yaml
resource_limits:
  cpu:
    min: 4 # Al menos 2 nodos (2 nodos × 2 vCPUs = 4 vCPUs)
    max: 10 # Máximo 5 nodos (5 nodos × 2 vCPUs = 10 vCPUs)
  memory:
    min: 4 # Al menos 2 nodos (2 nodos × 2 GB = 4 GB)
    max: 10 # Máximo 5 nodos (5 nodos × 2 GB = 10 GB)
```

**Resultado:** El cluster tendrá entre 2 y 5 nodos.

### Ejemplo con Límites No Alineados

```yaml
resource_limits:
  cpu:
    min: 6 # Al menos 3 nodos (3 nodos × 2 vCPUs = 6 vCPUs)
    max: 12 # Máximo 6 nodos (6 nodos × 2 vCPUs = 12 vCPUs)
  memory:
    min: 4 # Al menos 2 nodos (2 nodos × 2 GB = 4 GB)
    max: 16 # Máximo 8 nodos (8 nodos × 2 GB = 16 GB)
```

**Resultado:**

- Por CPU: Necesita 3-6 nodos
- Por memoria: Necesita 2-8 nodos
- GKE usará el límite más restrictivo: **3-6 nodos**

## 📊 Ejemplos Prácticos

### 1. Cluster Pequeño (Desarrollo)

```yaml
machine_type: e2-small # 2 vCPUs, 2 GB RAM

resource_limits:
  cpu:
    min: 2 # 1 nodo mínimo
    max: 6 # 3 nodos máximo
  memory:
    min: 2 # 1 nodo mínimo
    max: 6 # 3 nodos máximo

min_nodes: 1
max_nodes: 3
```

### 2. Cluster Mediano (Producción)

```yaml
machine_type: e2-medium # 2 vCPUs, 4 GB RAM

resource_limits:
  cpu:
    min: 4 # 2 nodos mínimo
    max: 20 # 10 nodos máximo
  memory:
    min: 8 # 2 nodos mínimo
    max: 40 # 10 nodos máximo

min_nodes: 2
max_nodes: 10
```

### 3. Cluster Grande (Alta Demanda)

```yaml
machine_type: e2-standard-4 # 4 vCPUs, 16 GB RAM

resource_limits:
  cpu:
    min: 12 # 3 nodos mínimo (3 × 4 = 12 vCPUs)
    max: 60 # 15 nodos máximo (15 × 4 = 60 vCPUs)
  memory:
    min: 48 # 3 nodos mínimo (3 × 16 = 48 GB)
    max: 240 # 15 nodos máximo (15 × 16 = 240 GB)

min_nodes: 3
max_nodes: 15
```

## 🔧 Cómo Calcular los Límites

### Paso 1: Conoce tu Tipo de Máquina

| Tipo de Máquina | vCPUs | Memoria (GB) |
| --------------- | ----- | ------------ |
| e2-micro        | 2     | 1            |
| e2-small        | 2     | 2            |
| e2-medium       | 2     | 4            |
| e2-standard-2   | 2     | 8            |
| e2-standard-4   | 4     | 16           |
| e2-standard-8   | 8     | 32           |

### Paso 2: Calcula Recursos Totales

```
CPU total = número_de_nodos × vCPUs_por_nodo
Memoria total = número_de_nodos × GB_por_nodo
```

### Paso 3: Define tus Límites

```yaml
resource_limits:
  cpu:
    min: min_nodes × vCPUs_por_nodo
    max: max_nodes × vCPUs_por_nodo
  memory:
    min: min_nodes × GB_por_nodo
    max: max_nodes × GB_por_nodo
```

## 💡 Consejos

### 1. Alinea con min_nodes y max_nodes

Para evitar confusión, asegúrate de que los límites sean consistentes:

```yaml
# ✅ CORRECTO - Alineado
machine_type: e2-small # 2 vCPUs, 2 GB RAM
min_nodes: 2
max_nodes: 5

resource_limits:
  cpu:
    min: 4 # 2 nodos × 2 vCPUs
    max: 10 # 5 nodos × 2 vCPUs
  memory:
    min: 4 # 2 nodos × 2 GB
    max: 10 # 5 nodos × 2 GB
```

### 2. Considera tus Pods

Si tus pods requieren muchos recursos, aumenta los límites:

```yaml
# Si cada pod requiere 500m CPU y 512Mi memoria
# Y quieres correr hasta 20 pods:
# Necesitas: 20 × 0.5 = 10 vCPUs mínimo
# Y:        20 × 0.5 = 10 GB memoria mínimo

resource_limits:
  cpu:
    min: 4 # Base
    max: 20 # Para 20 pods con headroom
  memory:
    min: 4 # Base
    max: 20 # Para 20 pods con headroom
```

### 3. Deja Margen para el Sistema

Kubernetes y GKE usan recursos del nodo:

- ~10-20% de CPU
- ~100-500 MB de memoria

```yaml
# ❌ MALO - Sin margen
resource_limits:
  cpu:
    max: 10  # Tus pods necesitan exactamente 10 vCPUs

# ✅ BUENO - Con margen
resource_limits:
  cpu:
    max: 12  # 10 para tus pods + 2 de margen
```

## 🚀 Cómo Usar

### 1. Configurar en all.yml

```bash
# Edita el archivo
nano ansible/group_vars/all.yml
```

```yaml
# Configura tus límites
resource_limits:
  cpu:
    min: 4
    max: 10
  memory:
    min: 4
    max: 10
```

### 2. Crear Cluster

```bash
ansible-playbook -i ansible/inventory/hosts ansible/playbooks/create-cluster.yml
```

### 3. Verificar Límites

```bash
# Ver configuración del cluster
gcloud container clusters describe todo-app-cluster \
  --zone=us-central1-a \
  --format="yaml(autoscaling, clusterAutoscaling)"
```

### 4. Actualizar Límites

```bash
# Edita all.yml con nuevos valores
# Luego:
ansible-playbook -i ansible/inventory/hosts ansible/playbooks/update-cluster.yml
```

### 5. Override en Runtime

```bash
ansible-playbook -i ansible/inventory/hosts ansible/playbooks/create-cluster.yml \
  -e '{"resource_limits": {"cpu": {"min": 8, "max": 20}, "memory": {"min": 8, "max": 20}}}'
```

## 📊 Monitoreo

### Ver Uso Actual

```bash
# Uso total del cluster
kubectl top nodes

# Suma de CPU y memoria
kubectl top nodes | awk 'NR>1 {cpu+=$3; mem+=$5} END {print "CPU:", cpu, "Memoria:", mem}'
```

### Ver Capacidad Total

```bash
# Ver capacidad de cada nodo
kubectl get nodes -o json | jq '.items[] | {name: .metadata.name, cpu: .status.capacity.cpu, memory: .status.capacity.memory}'
```

## ⚠️ Advertencias

1. **Los límites deben ser realistas**: No pongas límites muy bajos que impidan que tus pods se programen

2. **GKE no puede crear fracciones de nodo**: Si pones `cpu.max: 5` con `e2-small` (2 vCPUs), GKE creará máximo 2 nodos (4 vCPUs), no 2.5

3. **Los límites son guías, no garantías**: GKE usa estos valores junto con otras métricas para decidir cuándo escalar

## 📚 Relación con Otras Variables

```yaml
# Estas variables trabajan juntas:

# 1. Límites físicos de nodos
min_nodes: 2
max_nodes: 5

# 2. Límites de recursos totales
resource_limits:
  cpu:
    min: 4 # min_nodes × vCPUs
    max: 10 # max_nodes × vCPUs

# 3. Umbrales de utilización
cluster_autoscaler_settings:
  cpu_utilization_target: 0.7 # Escalar cuando uso > 70%

# 4. Perfil de comportamiento
autoscaling_profile: balanced
```

## 🎉 Resultado

Ahora puedes controlar el autoescalamiento tanto por **cantidad de nodos** como por **cantidad de recursos (CPU/memoria)**.

Ejemplo final en `all.yml`:

```yaml
# Configuración completa
machine_type: e2-small # 2 vCPUs, 2 GB RAM

min_nodes: 2
max_nodes: 5

resource_limits:
  cpu:
    min: 4 # 2 nodos × 2 vCPUs
    max: 10 # 5 nodos × 2 vCPUs
  memory:
    min: 4 # 2 nodos × 2 GB
    max: 10 # 5 nodos × 2 GB

cluster_autoscaler_settings:
  cpu_utilization_target: 0.7
  memory_utilization_target: 0.8
```

¡Ahora tienes control completo! 🚀
