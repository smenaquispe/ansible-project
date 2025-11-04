# Configuración de Autoescalamiento en GKE

## 📊 Cómo Funciona el Autoescalamiento en GKE

GKE tiene **dos niveles de autoescalamiento**:

### 1. **Cluster Autoscaler (Node Pool Autoscaling)**

Escala **nodos** (VMs) del cluster basándose en:

- Pods que no pueden ser programados por falta de recursos
- Nodos subutilizados que pueden ser removidos

### 2. **Horizontal Pod Autoscaler (HPA)**

Escala **pods** basándose en:

- Uso de CPU/memoria de los pods
- Métricas personalizadas

## ⚙️ Variables de Configuración

### Variables en `group_vars/all.yml`

```yaml
# Límites de nodos
min_nodes: 2 # Mínimo de nodos en el cluster
max_nodes: 5 # Máximo de nodos en el cluster

# Perfil de autoescalamiento
autoscaling_profile: balanced # balanced u optimize-utilization

# Políticas de autoescalamiento
cluster_autoscaler_settings:
  # CPU: Escalar cuando los pods usan este % de CPU
  cpu_utilization_target: 0.7 # 70% (rango: 0.0 - 1.0)

  # Memoria: Escalar cuando los pods usan este % de memoria
  memory_utilization_target: 0.8 # 80% (rango: 0.0 - 1.0)

  # Tiempo de espera después de escalar hacia arriba
  scale_down_delay_after_add: 600 # 10 minutos en segundos

  # Tiempo que un nodo debe estar subutilizado antes de removerse
  scale_down_unneeded_time: 600 # 10 minutos en segundos

  # Umbral de utilización para considerar remover un nodo
  scale_down_utilization_threshold: 0.5 # 50%
```

## 🎯 Perfiles de Autoescalamiento

GKE ofrece dos perfiles:

### **`balanced`** (Por defecto)

- Equilibra disponibilidad y costos
- Escala moderadamente
- Mejor para cargas de trabajo estables

### **`optimize-utilization`**

- Prioriza la utilización de recursos
- Escala más agresivamente hacia abajo
- Mejor para ahorrar costos
- Puede tener más fluctuaciones

## 📝 Ejemplos de Configuración

### Ejemplo 1: Aplicación con Alta Demanda de CPU

```yaml
# Escalar cuando CPU > 60%
cluster_autoscaler_settings:
  cpu_utilization_target: 0.6
  memory_utilization_target: 0.8
  scale_down_utilization_threshold: 0.4

min_nodes: 3
max_nodes: 10
autoscaling_profile: balanced
```

### Ejemplo 2: Aplicación con Alta Demanda de Memoria

```yaml
# Escalar cuando memoria > 70%
cluster_autoscaler_settings:
  cpu_utilization_target: 0.8
  memory_utilization_target: 0.7
  scale_down_utilization_threshold: 0.5

min_nodes: 2
max_nodes: 8
autoscaling_profile: balanced
```

### Ejemplo 3: Optimización de Costos

```yaml
# Escalar agresivamente para reducir costos
cluster_autoscaler_settings:
  cpu_utilization_target: 0.8
  memory_utilization_target: 0.85
  scale_down_delay_after_add: 300 # 5 minutos
  scale_down_unneeded_time: 300 # 5 minutos
  scale_down_utilization_threshold: 0.4

min_nodes: 1
max_nodes: 5
autoscaling_profile: optimize-utilization
```

### Ejemplo 4: Alta Disponibilidad

```yaml
# Mantener recursos disponibles, escalar conservadoramente
cluster_autoscaler_settings:
  cpu_utilization_target: 0.5 # Escalar temprano
  memory_utilization_target: 0.6
  scale_down_delay_after_add: 900 # 15 minutos
  scale_down_unneeded_time: 900
  scale_down_utilization_threshold: 0.3

min_nodes: 4
max_nodes: 15
autoscaling_profile: balanced
```

## 🔧 Cómo Usar

### 1. Configurar Variables

Edita `ansible/group_vars/all.yml`:

```yaml
# Ajusta según tus necesidades
cpu_utilization_target: 0.7 # Escalar cuando CPU > 70%
memory_utilization_target: 0.8 # Escalar cuando memoria > 80%
min_nodes: 2
max_nodes: 5
autoscaling_profile: balanced
```

### 2. Crear Cluster

```bash
ansible-playbook -i ansible/inventory/hosts ansible/playbooks/create-cluster.yml
```

### 3. Actualizar Políticas

Si necesitas cambiar las políticas después de crear el cluster:

```bash
# 1. Editar ansible/group_vars/all.yml
# 2. Aplicar cambios
ansible-playbook -i ansible/inventory/hosts ansible/playbooks/update-cluster.yml
```

### 4. Verificar Configuración

```bash
# Ver configuración del cluster
gcloud container clusters describe todo-app-cluster --zone=us-central1-a

# Ver autoescalamiento del node pool
gcloud container node-pools describe default-pool \
  --cluster=todo-app-cluster \
  --zone=us-central1-a
```

## 📊 Monitoreo del Autoescalamiento

### Ver Eventos de Autoescalamiento

```bash
# Logs del cluster autoscaler
kubectl logs -n kube-system deployment/cluster-autoscaler

# Ver eventos del cluster
kubectl get events --all-namespaces --sort-by='.lastTimestamp'

# Ver uso de recursos de los nodos
kubectl top nodes

# Ver uso de recursos de los pods
kubectl top pods -n todo-app
```

### Métricas en GCP Console

1. Ve a **Kubernetes Engine > Clusters**
2. Selecciona tu cluster
3. Pestaña **Nodes**
4. Observa el gráfico de autoescalamiento

## 🎓 Entendiendo los Parámetros

### `cpu_utilization_target` (0.7 = 70%)

**¿Qué hace?**

- GKE monitorea el uso de CPU de los **pods** (no de los nodos)
- Cuando el uso promedio de CPU de los pods alcanza 70%, GKE agrega un nodo

**Ejemplo:**

- Tienes 2 nodos con 2 CPUs cada uno (total: 4 CPUs)
- Tus pods están usando 2.8 CPUs (70% de 4)
- GKE agrega un nodo más → ahora tienes 6 CPUs disponibles

**Valores sugeridos:**

- `0.5-0.6` (50-60%): Para aplicaciones críticas que necesitan headroom
- `0.7-0.8` (70-80%): Balance entre costo y disponibilidad (recomendado)
- `0.8-0.9` (80-90%): Para optimización de costos (más riesgo)

### `memory_utilization_target` (0.8 = 80%)

Similar a CPU pero para memoria.

**Valores sugeridos:**

- `0.6-0.7` (60-70%): Para aplicaciones con memory leaks o spikes
- `0.7-0.8` (70-80%): Balance general (recomendado)
- `0.8-0.9` (80-90%): Para optimización de costos

### `scale_down_utilization_threshold` (0.5 = 50%)

**¿Qué hace?**

- Un nodo se considera "subutilizado" cuando usa menos del 50% de recursos
- Si está subutilizado por `scale_down_unneeded_time`, se remueve

**Ejemplo:**

- Tienes un nodo con 2 CPUs
- Tus pods en ese nodo solo usan 0.8 CPUs (40%)
- Después de 10 minutos (default), GKE remueve ese nodo

**Valores sugeridos:**

- `0.3-0.4` (30-40%): Escalar agresivamente hacia abajo
- `0.4-0.5` (40-50%): Balance (recomendado)
- `0.5-0.7` (50-70%): Mantener más capacidad disponible

### `scale_down_delay_after_add` (600 segundos = 10 min)

**¿Qué hace?**

- Después de agregar un nodo, esperar este tiempo antes de remover cualquier nodo
- Evita el "flapping" (agregar y remover nodos constantemente)

**Valores sugeridos:**

- `300-600s` (5-10 min): Para cargas de trabajo variables
- `600-900s` (10-15 min): Para estabilidad (recomendado)
- `900-1800s` (15-30 min): Para cargas muy estables

### `scale_down_unneeded_time` (600 segundos = 10 min)

**¿Qué hace?**

- Un nodo debe estar subutilizado por este tiempo antes de removerse
- Mayor valor = más conservador (menos cambios)

**Valores sugeridos:**

- `300-600s` (5-10 min): Para optimización de costos
- `600-900s` (10-15 min): Balance (recomendado)
- `900-1800s` (15-30 min): Para máxima estabilidad

## 🚀 Perfiles de Uso Común

### Desarrollo/Testing

```yaml
min_nodes: 1
max_nodes: 3
cpu_utilization_target: 0.8
autoscaling_profile: optimize-utilization
```

### Producción Balanceada

```yaml
min_nodes: 2
max_nodes: 8
cpu_utilization_target: 0.7
autoscaling_profile: balanced
```

### Producción Alta Disponibilidad

```yaml
min_nodes: 3
max_nodes: 15
cpu_utilization_target: 0.6
autoscaling_profile: balanced
```

### Ahorro de Costos

```yaml
min_nodes: 1
max_nodes: 5
cpu_utilization_target: 0.8
autoscaling_profile: optimize-utilization
scale_down_delay_after_add: 300
```

## ⚠️ Consideraciones Importantes

1. **Recursos de Pods**: Define `requests` y `limits` en tus deployments

   ```yaml
   resources:
     requests:
       cpu: 100m
       memory: 128Mi
     limits:
       cpu: 200m
       memory: 256Mi
   ```

2. **PodDisruptionBudget**: Para aplicaciones críticas

   ```yaml
   apiVersion: policy/v1
   kind: PodDisruptionBudget
   metadata:
     name: my-app-pdb
   spec:
     minAvailable: 1
     selector:
       matchLabels:
         app: my-app
   ```

3. **Testing**: Prueba diferentes configuraciones en entorno de desarrollo primero

4. **Monitoreo**: Observa el comportamiento durante al menos una semana

## 📚 Referencias

- [GKE Cluster Autoscaler](https://cloud.google.com/kubernetes-engine/docs/concepts/cluster-autoscaler)
- [Horizontal Pod Autoscaler](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [Autoscaling Profiles](https://cloud.google.com/kubernetes-engine/docs/concepts/cluster-autoscaler#autoscaling_profiles)
- [Best Practices](https://cloud.google.com/kubernetes-engine/docs/best-practices/cluster-autoscaler)
