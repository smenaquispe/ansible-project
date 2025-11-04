# Resumen: Políticas de Autoescalamiento Personalizables

## ✅ Cambios Realizados

### 📝 Variables Agregadas (`group_vars/all.yml`)

```yaml
# Perfil de autoescalamiento
autoscaling_profile: balanced # balanced u optimize-utilization

# Políticas de autoescalamiento personalizables
cluster_autoscaler_settings:
  cpu_utilization_target: 0.7 # 70% - Escalar cuando CPU > 70%
  memory_utilization_target: 0.8 # 80% - Escalar cuando memoria > 80%
  scale_down_delay_after_add: 600 # 10 min - Espera antes de escalar abajo
  scale_down_unneeded_time: 600 # 10 min - Tiempo subutilizado antes de remover
  scale_down_utilization_threshold: 0.5 # 50% - Umbral para considerar subutilizado
```

### 🔧 Playbooks Actualizados

1. **`create-cluster.yml`**

   - ✅ Agregado soporte para `autoscaling_profile`
   - ✅ Agregado `cluster_autoscaling` con límites de recursos
   - ✅ Agregado `resource_limits` para CPU y memoria
   - ✅ Display mejorado mostrando configuración de autoescalamiento

2. **`update-cluster.yml`**
   - ✅ Mismo soporte que create-cluster.yml
   - ✅ Permite actualizar políticas sin recrear el cluster

### 📚 Documentación Nueva

- **`AUTOSCALING.md`** - Guía completa de configuración de autoescalamiento

## 🎯 Cómo Usar

### 1. Configurar Políticas Personalizadas

Edita `ansible/group_vars/all.yml`:

```yaml
# Ejemplo: Escalar cuando CPU > 60%
cluster_autoscaler_settings:
  cpu_utilization_target: 0.6 # 60%
  memory_utilization_target: 0.75 # 75%

min_nodes: 2
max_nodes: 8
autoscaling_profile: balanced
```

### 2. Crear Cluster con Políticas

```bash
ansible-playbook -i ansible/inventory/hosts ansible/playbooks/create-cluster.yml
```

### 3. Actualizar Políticas en Cluster Existente

```bash
# Edita group_vars/all.yml y luego:
ansible-playbook -i ansible/inventory/hosts ansible/playbooks/update-cluster.yml
```

### 4. Override en Runtime

```bash
# Cambiar solo para esta ejecución
ansible-playbook -i ansible/inventory/hosts ansible/playbooks/create-cluster.yml \
  -e "autoscaling_profile=optimize-utilization" \
  -e '{"cluster_autoscaler_settings": {"cpu_utilization_target": 0.8}}'
```

## 📊 Comparación: Antes vs Ahora

### ❌ Antes

```yaml
# Solo podías configurar cantidad de nodos
min_nodes: 2
max_nodes: 5
# No había control sobre CUÁNDO escalar
# GKE usaba valores por defecto (60% CPU)
```

### ✅ Ahora

```yaml
# Controlas cantidad de nodos
min_nodes: 2
max_nodes: 5

# Y ADEMÁS controlas CUÁNDO escalar
cluster_autoscaler_settings:
  cpu_utilization_target: 0.7 # TÚ decides el umbral
  memory_utilization_target: 0.8
  scale_down_utilization_threshold: 0.5

# Y el perfil de comportamiento
autoscaling_profile: balanced
```

## 🎓 Ejemplos Prácticos

### Aplicación con Picos de CPU

Tu aplicación tiene picos de CPU repentinos:

```yaml
cluster_autoscaler_settings:
  cpu_utilization_target: 0.6 # Escalar temprano (60%)
  memory_utilization_target: 0.8
  scale_down_delay_after_add: 900 # Esperar 15 min antes de escalar abajo

min_nodes: 3 # Mantener capacidad base
max_nodes: 10
autoscaling_profile: balanced
```

### Aplicación con Uso Estable (Ahorro de Costos)

Tu aplicación tiene carga predecible:

```yaml
cluster_autoscaler_settings:
  cpu_utilization_target: 0.8 # Tolerar más uso (80%)
  memory_utilization_target: 0.85
  scale_down_delay_after_add: 300 # Escalar abajo rápido (5 min)
  scale_down_unneeded_time: 300
  scale_down_utilization_threshold: 0.4 # Remover nodos subutilizados

min_nodes: 1 # Mínimo posible
max_nodes: 5
autoscaling_profile: optimize-utilization # Priorizar ahorro
```

### Aplicación Crítica (Alta Disponibilidad)

No puedes tolerar latencia por falta de recursos:

```yaml
cluster_autoscaler_settings:
  cpu_utilization_target: 0.5 # Escalar muy temprano (50%)
  memory_utilization_target: 0.6
  scale_down_delay_after_add: 1200 # Esperar 20 min
  scale_down_unneeded_time: 1200
  scale_down_utilization_threshold: 0.3 # Solo remover si MUY subutilizado

min_nodes: 4 # Capacidad base alta
max_nodes: 15
autoscaling_profile: balanced
```

## 🔍 Monitoreo

### Ver Configuración Aplicada

```bash
# Ver cluster completo
gcloud container clusters describe todo-app-cluster --zone=us-central1-a

# Ver solo autoescalamiento
gcloud container clusters describe todo-app-cluster \
  --zone=us-central1-a \
  --format="yaml(autoscaling)"
```

### Ver Comportamiento en Tiempo Real

```bash
# Ver uso de recursos de nodos
kubectl top nodes

# Ver uso de recursos de pods
kubectl top pods -n todo-app

# Ver eventos de autoescalamiento
kubectl get events --all-namespaces | grep -i scale
```

## 📈 Entendiendo los Umbrales

### `cpu_utilization_target: 0.7` (70%)

**Significado:** Cuando tus pods usan el 70% del CPU solicitado (`requests`), GKE agrega un nodo.

**Ejemplo:**

```yaml
# En tu deployment
resources:
  requests:
    cpu: 500m # Cada pod pide 500 milicores

# Si tienes 4 pods (4 * 500m = 2000m = 2 CPUs solicitados)
# GKE escalará cuando el uso real sea > 70% de 2 CPUs = 1.4 CPUs
```

**Valores sugeridos por escenario:**

- **0.5-0.6** (50-60%): Aplicaciones críticas, alta disponibilidad
- **0.7-0.8** (70-80%): Balance general (recomendado)
- **0.8-0.9** (80-90%): Optimización de costos

### `scale_down_utilization_threshold: 0.5` (50%)

**Significado:** Un nodo se puede remover si usa menos del 50% de sus recursos.

**Ejemplo:**

```yaml
# Nodo con 2 CPUs y 4 GB RAM
# Si los pods en ese nodo usan:
#   - 0.8 CPUs (40%)
#   - 1.5 GB RAM (37.5%)
# GKE puede remover este nodo (está por debajo del 50%)
```

## ⚠️ Importante: Diferencia con `gcp_compute_autoscaler`

El módulo `gcp_compute_autoscaler` que viste en la documentación es para **Compute Engine Instance Groups** (VMs normales), NO para GKE.

Para GKE, el autoescalamiento se configura directamente en el cluster con `gcp_container_cluster`, que es lo que implementamos.

## 🚀 Beneficios

1. ✅ **Control Total**: Decides exactamente cuándo escalar
2. ✅ **Optimización de Costos**: Ajusta para usar menos recursos
3. ✅ **Mejor Performance**: Escalar antes de que haya problemas
4. ✅ **Flexibilidad**: Cambia políticas sin recrear el cluster
5. ✅ **Transparente**: Todo en variables, fácil de entender y modificar

## 📚 Documentación

Lee `ansible/AUTOSCALING.md` para:

- Explicación detallada de cada parámetro
- Más ejemplos de configuración
- Mejores prácticas
- Guías de monitoreo
- Troubleshooting

## 🎉 Resultado Final

Ahora puedes controlar completamente el autoescalamiento de tu cluster GKE modificando simplemente las variables en `group_vars/all.yml`:

```yaml
# ¿Quieres escalar con menos CPU? Cambia esto:
cpu_utilization_target: 0.6 # Era 0.7, ahora 60%

# ¿Quieres optimizar costos? Cambia esto:
autoscaling_profile: optimize-utilization # Era balanced

# ¿Quieres más nodos? Cambia esto:
max_nodes: 10 # Era 5

# Y aplica los cambios:
# ansible-playbook playbooks/update-cluster.yml
```

¡Todo completamente configurable y documentado! 🚀
