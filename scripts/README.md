# Scripts de Despliegue

Esta carpeta contiene los scripts necesarios para gestionar el ciclo completo de despliegue de la aplicación Todo-App en Google Kubernetes Engine (GKE).

## 📋 Scripts Disponibles

### 1. `push-images.fish` - Subir Imágenes a Docker Hub

Construye las imágenes Docker y las sube a Docker Hub.

**Uso:**

```bash
./scripts/push-images.fish [version]
```

**Ejemplos:**

```bash
# Subir con tag "latest"
./scripts/push-images.fish

# Subir con versión específica (también taggeará como latest)
./scripts/push-images.fish 1.0.0
./scripts/push-images.fish 2.1.3
```

**Prerequisitos:**

- Docker instalado y corriendo
- Login en Docker Hub: `docker login`
- Usuario configurado en el script: `smenaq`

**Lo que hace:**

1. Construye imagen del backend desde `src/app/backend/`
2. Construye imagen del frontend desde `src/app/frontend/`
3. Construye imagen de la base de datos desde `src/app/db/`
4. Sube todas las imágenes a Docker Hub
5. Taguea automáticamente como `latest`

---

### 2. `create-cluster.fish` - Crear Cluster GKE

Crea un cluster de Kubernetes en Google Cloud Platform usando gcloud CLI.

**Uso:**

```bash
./scripts/create-cluster.fish
```

**Prerequisitos:**

- `gcloud` CLI instalado y configurado
- `kubectl` instalado
- Proyecto GCP configurado: `gcloud config set project YOUR_PROJECT_ID`
- APIs habilitadas (el script las habilita automáticamente)
- Facturación habilitada en el proyecto GCP

**Configuración del Cluster:**

- **Nombre:** `todo-app-cluster`
- **Zona:** `us-central1-a`
- **Tipo de máquina:** `e2-small` (2 vCPU, 2GB RAM)
- **Número de nodos:** 2 (con autoscaling 2-3)
- **Disco:** 20GB standard por nodo

**Lo que hace:**

1. Verifica prerrequisitos (gcloud, kubectl)
2. Habilita APIs necesarias de GCP
3. Crea el cluster GKE (5-10 minutos)
4. Configura kubectl para conectarse al cluster
5. Verifica la conexión

**Costos estimados:**

- GKE Cluster management: ~$74/mes
- Load Balancer: ~$18/mes
- **Total:** ~$92/mes (primeros 3 meses gratis con $300 de crédito)

---

### 3. `delete-cluster.fish` - Eliminar Cluster GKE

Elimina el cluster GKE para evitar costos cuando no lo necesitas.

**Uso:**

```bash
./scripts/delete-cluster.fish
```

**Lo que hace:**

1. Verifica que el cluster existe
2. Muestra información del cluster y costos estimados
3. Pide doble confirmación (seguridad)
4. Elimina el cluster completamente
5. Sugiere verificar recursos huérfanos (Load Balancers, discos, IPs)

**⚠️ ADVERTENCIA:**
Esta acción es irreversible y eliminará:

- El cluster GKE completo
- Todos los pods y deployments
- Todos los servicios y Load Balancers
- Los datos en la base de datos

**Recomendación:** Elimina el cluster cuando no lo estés usando para evitar cargos innecesarios.

---

### 4. `deploy.fish` - Desplegar/Redesplegar Aplicación

Despliega o actualiza la aplicación en GKE usando Ansible.

**Uso:**

```bash
# Deploy inicial completo
./scripts/deploy.fish

# Actualizar/redesplegar (restart de pods)
./scripts/deploy.fish --update
```

**Prerequisitos:**

- `kubectl` instalado y configurado
- `ansible` instalado: `pip install ansible`
- Colección de Ansible: `ansible-galaxy collection install kubernetes.core`
- Cluster GKE creado y accesible
- Imágenes subidas a Docker Hub

**Lo que hace (deploy completo):**

1. Crea el namespace `todo-app`
2. Despliega PostgreSQL (base de datos)
3. Espera a que la DB esté lista
4. Despliega el Backend (Node.js)
5. Espera a que el backend esté listo
6. Despliega el Frontend (React + Nginx)
7. Espera a que el frontend esté listo
8. Configura el Ingress (Load Balancer)
9. Muestra el estado y la IP externa

**Lo que hace (update):**

1. Reinicia todos los deployments
2. Espera a que los nuevos pods estén listos
3. Muestra el estado actualizado

**Después del deploy:**

- El Load Balancer puede tardar 5-10 minutos en obtener una IP externa
- Verifica la IP con: `kubectl get ingress -n todo-app`
- Accede a la app en: `http://EXTERNAL-IP`

---

## 🚀 Flujo de Trabajo Completo

### Primera vez (Setup inicial):

```bash
# 1. Subir imágenes a Docker Hub
./scripts/push-images.fish 1.0.0

# 2. Crear cluster en GCP
./scripts/create-cluster.fish

# 3. Desplegar la aplicación
./scripts/deploy.fish

# 4. Obtener la IP externa (espera 5-10 min)
kubectl get ingress -n todo-app
```

### Actualizar la aplicación (después de cambios en el código):

```bash
# 1. Subir nuevas imágenes
./scripts/push-images.fish 1.1.0

# 2. Redesplegar
./scripts/deploy.fish --update
```

### Limpiar todo (para evitar costos):

```bash
# Eliminar el cluster completo
./scripts/delete-cluster.fish
```

---

## 📊 Comandos Útiles

### Ver estado de la aplicación:

```bash
# Todos los recursos
kubectl get all -n todo-app

# Solo pods
kubectl get pods -n todo-app

# Servicios e Ingress
kubectl get svc,ingress -n todo-app
```

### Ver logs:

```bash
# Backend
kubectl logs -l app=todo-backend -n todo-app --tail=50 -f

# Frontend
kubectl logs -l app=todo-frontend -n todo-app --tail=50 -f

# Base de datos
kubectl logs -l app=todo-db -n todo-app --tail=50 -f
```

### Escalar servicios:

```bash
# Escalar backend a 3 réplicas
kubectl scale deployment todo-backend --replicas=3 -n todo-app

# Escalar frontend a 2 réplicas
kubectl scale deployment todo-frontend --replicas=2 -n todo-app
```

### Debug:

```bash
# Describir un pod
kubectl describe pod POD_NAME -n todo-app

# Ver eventos
kubectl get events -n todo-app --sort-by='.lastTimestamp'

# Conectarse a un pod
kubectl exec -it POD_NAME -n todo-app -- /bin/bash
```

---

## 🔧 Configuración

### Cambiar usuario de Docker Hub:

Edita `push-images.fish` y cambia:

```bash
set DOCKER_USER "smenaq"  # <- Cambia esto
```

### Cambiar configuración del cluster:

Edita `create-cluster.fish` y ajusta:

```bash
set ZONE "us-central1-a"        # Zona de GCP
set CLUSTER_NAME "todo-app-cluster"  # Nombre del cluster
set MACHINE_TYPE "e2-small"     # Tipo de máquina
set NUM_NODES "2"               # Número de nodos
```

---

## ⚠️ Notas Importantes

1. **Costos:** El cluster GKE genera costos (~$92/mes). Elimínalo cuando no lo uses.
2. **Créditos Free Tier:** GCP ofrece $300 en créditos por 90 días para nuevos usuarios.
3. **Load Balancer:** Tarda 5-10 minutos en obtener IP externa después del deploy.
4. **Imágenes:** Asegúrate de que las imágenes en Docker Hub sean públicas o configura imagePullSecrets.
5. **Namespace:** Toda la aplicación se despliega en el namespace `todo-app`.

---

## 🐛 Troubleshooting

### El cluster no se crea:

- Verifica que tengas un proyecto GCP configurado
- Asegúrate de que la facturación esté habilitada
- Verifica que tengas permisos suficientes

### Los pods no inician:

- Verifica que las imágenes estén en Docker Hub y sean públicas
- Revisa los logs: `kubectl logs POD_NAME -n todo-app`
- Describe el pod: `kubectl describe pod POD_NAME -n todo-app`

### No obtengo IP externa:

- Espera 5-10 minutos después del deploy
- Verifica el Ingress: `kubectl describe ingress -n todo-app`
- Revisa eventos: `kubectl get events -n todo-app`

### La aplicación muestra página en blanco:

- Verifica logs del frontend: `kubectl logs -l app=todo-frontend -n todo-app`
- Verifica que el backend esté funcionando: `kubectl get pods -n todo-app`
- Verifica la configuración del Ingress: `kubectl get ingress -n todo-app -o yaml`

---

## 📚 Referencias

- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [Ansible Kubernetes Collection](https://docs.ansible.com/ansible/latest/collections/kubernetes/core/index.html)
- [Docker Hub](https://hub.docker.com/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
