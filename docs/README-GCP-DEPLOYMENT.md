# 🚀 Guía de Despliegue de Todo-App en GCP (Google Cloud Platform)

## 📋 Tabla de Contenidos

- [🆕 Actualización: Redespliegue](#-actualización-nuevo-sistema-de-producción)
- [Prerequisitos](#prerequisitos)
- [Configuración de GCP Free Tier](#configuración-de-gcp-free-tier)
- [Instalación de Herramientas](#instalación-de-herramientas)
- [Opción 1: Despliegue Automático](#opción-1-despliegue-automático-recomendado)
- [Opción 2: Despliegue Manual](#opción-2-despliegue-manual)
- [Verificación del Despliegue](#verificación-del-despliegue)
- [Monitoreo y Troubleshooting](#monitoreo-y-troubleshooting)
- [Costos y Límites del Free Tier](#costos-y-límites-del-free-tier)
- [Limpieza de Recursos](#limpieza-de-recursos)

---

## 📌 Prerequisitos

### 1. Cuenta de Google Cloud Platform

- ✅ Crear cuenta en [cloud.google.com](https://cloud.google.com)
- ✅ Activar **Free Trial** ($300 de crédito por 90 días)
- ✅ **IMPORTANTE**: Aunque es "Free Tier", necesitas agregar una tarjeta de crédito
  - No se cobrará automáticamente al terminar el trial
  - Los $300 cubren ampliamente este proyecto por 3 meses

### 2. Crear Proyecto en GCP

```bash
# Desde Google Cloud Console (https://console.cloud.google.com)
# 1. Click en el selector de proyectos (arriba)
# 2. "New Project"
# 3. Nombre: "todo-app-project" (o el que prefieras)
# 4. Anota el PROJECT_ID (ej: todo-app-project-123456)

```

- Real ansible-project-475919

### 3. Habilitar Facturación

```bash
# Desde Google Cloud Console
# 1. Navegación > Billing
# 2. Link your project to a billing account
# 3. Usar la cuenta del Free Trial
```

---

## 🔧 Instalación de Herramientas

### 1. Instalar Google Cloud SDK (gcloud)

**Linux:**

```bash
curl https://sdk.cloud.google.com | bash
exec -l $SHELL  # Reiniciar shell
gcloud init
```

**macOS:**

```bash
brew install google-cloud-sdk
gcloud init
```

**Arch Linux:**

```bash
sudo pacman -S google-cloud-sdk
gcloud init
```

### 2. Autenticar con GCP

```bash
# Login interactivo
gcloud auth login

# Configurar proyecto
gcloud config set project TU_PROJECT_ID

# Verificar configuración
gcloud config list
```

### 3. Instalar kubectl

```bash
# Via gcloud (recomendado)
gcloud components install kubectl

# O via package manager
# Ubuntu/Debian:
sudo apt-get install kubectl

# macOS:
brew install kubectl

# Arch Linux:
sudo pacman -S kubectl
```

---

## � ACTUALIZACIÓN: Nuevo Sistema de Producción

**Fecha:** Octubre 2025

Se ha actualizado la aplicación para usar un **build de producción optimizado**:

- ✅ **Frontend con Nginx** (en lugar de Vite dev server)
- ✅ **Build estático optimizado** (~50MB vs ~300MB)
- ✅ **Puerto 80** (estándar HTTP)
- ✅ **Ingress con rewrite** para routing correcto
- ✅ **Scripts automatizados** para redespliegue

### 📚 Documentación Actualizada

- **[RESUMEN-CAMBIOS.md](RESUMEN-CAMBIOS.md)** - Resumen visual de todos los cambios
- **[GUIA-REDESPLIEGUE.md](GUIA-REDESPLIEGUE.md)** - Guía completa de redespliegue
- **[FIX-FRONTEND-BLANK-PAGE.md](FIX-FRONTEND-BLANK-PAGE.md)** - Documentación del fix

---

## Pasos para Desplegar

### 🎯 Despliegue Inicial

Si es la **primera vez** que despliegas:

### Opción 1: Script Automatizado (Recomendado)

### Usar el Script Automatizado

```bash
# Navegar al directorio del proyecto
cd /home/smenaq/Documents/UNSA/cloud/ansible-project/todo-app/gcp

# Ejecutar script (Fish Shell)
./deploy-gcp.fish

# O si usas Bash/Zsh
./deploy-gcp.sh
```

El script hará automáticamente:

1. ✅ Configurar proyecto GCP
2. ✅ Habilitar APIs necesarias
3. ✅ Crear cluster GKE (2 nodos e2-small)
4. ✅ Desplegar base de datos PostgreSQL
5. ✅ Desplegar backend (Node.js)
6. ✅ Desplegar frontend (React)
7. ✅ Configurar Load Balancer (Ingress)
8. ✅ Mostrar información de acceso

**Tiempo estimado:** 10-15 minutos

---

## 🛠️ Opción 2: Despliegue Manual

### Paso 1: Crear Cluster GKE

```bash
# Variables de configuración
PROJECT_ID="tu-project-id"
REGION="us-central1"
ZONE="us-central1-a"
CLUSTER_NAME="todo-app-cluster"

# Configurar proyecto
gcloud config set project $PROJECT_ID
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE

# Habilitar APIs
gcloud services enable container.googleapis.com
gcloud services enable compute.googleapis.com

# Crear cluster (esto tarda ~5-10 minutos)
gcloud container clusters create $CLUSTER_NAME \
    --zone=$ZONE \
    --machine-type=e2-small \
    --num-nodes=2 \
    --disk-size=20 \
    --disk-type=pd-standard \
    --enable-autoscaling \
    --min-nodes=2 \
    --max-nodes=3 \
    --enable-autorepair \
    --enable-autoupgrade \
    --addons=HorizontalPodAutoscaling,HttpLoadBalancing
```

### Paso 2: Obtener Credenciales

```bash
# Conectar kubectl al cluster
gcloud container clusters get-credentials $CLUSTER_NAME --zone=$ZONE

# Verificar conexión
kubectl cluster-info
kubectl get nodes
```

### Paso 3: Desplegar Aplicación

```bash
# Navegar al directorio GCP
cd /home/smenaq/Documents/UNSA/cloud/ansible-project/todo-app/gcp

# 1. Crear namespace
kubectl apply -f namespace.yaml

# 2. Desplegar base de datos
kubectl apply -f db-gcp.yaml

# Esperar a que PostgreSQL esté listo
kubectl wait --for=condition=ready pod -l app=todo-db -n todo-app --timeout=300s

# 3. Desplegar backend
kubectl apply -f backend-gcp.yaml

# Esperar a que backend esté listo
kubectl wait --for=condition=ready pod -l app=todo-backend -n todo-app --timeout=300s

# 4. Desplegar frontend
kubectl apply -f frontend-gcp.yaml

# Esperar a que frontend esté listo
kubectl wait --for=condition=ready pod -l app=todo-frontend -n todo-app --timeout=300s

# 5. Desplegar Ingress (Load Balancer)
kubectl apply -f ingress-gcp.yaml
```

### Paso 4: Obtener IP Pública

```bash
# El Ingress tarda 5-10 minutos en obtener una IP pública
kubectl get ingress -n todo-app --watch

# Una vez que aparezca la IP:
# NAME                CLASS    HOSTS   ADDRESS         PORTS   AGE
# todo-app-ingress    <none>   *       34.120.45.123   80      10m

# Guardar la IP
EXTERNAL_IP=$(kubectl get ingress todo-app-ingress -n todo-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Tu aplicación está disponible en: http://$EXTERNAL_IP"
```

---

## ✅ Verificación del Despliegue

### 1. Verificar Pods

```bash
# Ver todos los pods
kubectl get pods -n todo-app

# Salida esperada:
# NAME                            READY   STATUS    RESTARTS   AGE
# todo-backend-xxxxxxxxx-xxxxx    1/1     Running   0          5m
# todo-backend-xxxxxxxxx-xxxxx    1/1     Running   0          5m
# todo-db-xxxxxxxxx-xxxxx         1/1     Running   0          6m
# todo-frontend-xxxxxxxxx-xxxxx   1/1     Running   0          4m
# todo-frontend-xxxxxxxxx-xxxxx   1/1     Running   0          4m
```

### 2. Verificar Servicios

```bash
kubectl get svc -n todo-app

# Salida esperada:
# NAME            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
# todo-backend    ClusterIP   10.XX.XXX.XX    <none>        5000/TCP   5m
# todo-db         ClusterIP   10.XX.XXX.XX    <none>        5432/TCP   6m
# todo-frontend   ClusterIP   10.XX.XXX.XX    <none>        80/TCP     4m
```

### 3. Verificar Ingress

```bash
kubectl get ingress -n todo-app

# Esperar a que EXTERNAL-IP tenga una dirección IP
# Puede tardar 5-10 minutos
```

### 4. Probar la Aplicación

```bash
# Obtener la IP
EXTERNAL_IP=$(kubectl get ingress todo-app-ingress -n todo-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Probar frontend
curl http://$EXTERNAL_IP/

# Probar backend API
curl http://$EXTERNAL_IP/api/todos

# Abrir en navegador
echo "Abre en tu navegador: http://$EXTERNAL_IP"
```

---

## 🔍 Monitoreo y Troubleshooting

### Ver Logs

```bash
# Logs del backend
kubectl logs -l app=todo-backend -n todo-app --tail=50 -f

# Logs del frontend
kubectl logs -l app=todo-frontend -n todo-app --tail=50 -f

# Logs de la base de datos
kubectl logs -l app=todo-db -n todo-app --tail=50 -f

# Ver logs de un pod específico
kubectl logs <pod-name> -n todo-app
```

### Ver Eventos

```bash
# Ver eventos recientes del namespace
kubectl get events -n todo-app --sort-by='.lastTimestamp'

# Ver eventos de un pod específico
kubectl describe pod <pod-name> -n todo-app
```

### Acceso Interactivo

```bash
# Conectar al backend
kubectl exec -it deployment/todo-backend -n todo-app -- /bin/sh

# Conectar a PostgreSQL
kubectl exec -it deployment/todo-db -n todo-app -- psql -U todouser -d tododb

# Port-forward para debugging local
kubectl port-forward svc/todo-backend -n todo-app 5000:5000
kubectl port-forward svc/todo-frontend -n todo-app 8080:80
```

### Problemas Comunes

#### 1. Pod en estado "Pending"

```bash
# Ver por qué el pod no se programa
kubectl describe pod <pod-name> -n todo-app

# Común: Recursos insuficientes
# Solución: Reducir requests/limits en los YAML
```

#### 2. Ingress sin IP Externa

```bash
# Verificar que el controlador de Ingress esté corriendo
kubectl get pods -n kube-system | grep ingress

# Esperar más tiempo (puede tardar hasta 10 minutos)
kubectl get ingress -n todo-app --watch
```

#### 3. Backend no conecta con DB

```bash
# Verificar que la DB esté corriendo
kubectl get pods -l app=todo-db -n todo-app

# Verificar logs de backend para errores de conexión
kubectl logs -l app=todo-backend -n todo-app | grep -i "error\|connection"
```

#### 4. Error de Cuota Excedida

```bash
# Ver cuotas del proyecto
gcloud compute project-info describe --project=TU_PROJECT_ID

# Si excedes el Free Tier, considera:
# - Reducir número de nodos
# - Usar machine-type más pequeño (e2-micro si está disponible)
```

---

## 💰 Costos y Límites del Free Tier

### Recursos Incluidos en GCP Free Trial

| Recurso                  | Free Trial           | Always Free (después del trial) |
| ------------------------ | -------------------- | ------------------------------- |
| **Crédito**              | $300 por 90 días     | -                               |
| **Compute Engine**       | Incluido en los $300 | 1 e2-micro (US regions)         |
| **Cloud Storage**        | Incluido en los $300 | 5 GB regional                   |
| **Cloud Load Balancing** | Incluido en los $300 | -                               |
| **Persistent Disk**      | Incluido en los $300 | 30 GB HDD                       |

### Configuración Actual - Costos Estimados

```
Cluster GKE:
├── Control Plane: $74.40/mes
├── Nodos (2x e2-small):
│   ├── Compute: 2 vCPU, 2GB RAM cada uno
│   ├── Costo: ~$25/mes por nodo = $50/mes total
│   └── Disk: 20GB standard = ~$4/mes
├── Load Balancer: ~$18/mes
└── TOTAL: ~$146/mes

✅ Con $300 de crédito = ~2 meses cubiertos completamente
```

### Optimizaciones para Reducir Costos

#### 1. Usar GKE Autopilot (Más Barato)

```bash
# Autopilot solo cobra por los pods que usas
gcloud container clusters create-auto todo-app-autopilot \
    --region=us-central1
```

#### 2. Pausar Cluster cuando no lo uses

```bash
# No hay forma oficial de "pausar" GKE
# Mejor opción: eliminar y recrear
gcloud container clusters delete todo-app-cluster --zone=us-central1-a

# Recrear cuando lo necesites
./deploy-gcp.fish
```

#### 3. Usar Compute Engine Directamente

```bash
# Alternativa: 1 VM con Docker Compose (MUCHO más barato)
# Ver archivo: docker-compose.yml en la carpeta todo-app
```

---

## 🧹 Limpieza de Recursos

### Eliminar Solo la Aplicación (Mantener Cluster)

```bash
# Eliminar todos los recursos de la app
kubectl delete namespace todo-app

# Eliminar Ingress (para evitar cobro de Load Balancer)
kubectl delete ingress todo-app-ingress -n todo-app
```

### Eliminar Todo el Cluster

```bash
# Eliminar cluster completo
gcloud container clusters delete todo-app-cluster \
    --zone=us-central1-a \
    --quiet

# Esto eliminará:
# - Todos los nodos
# - Todos los pods y servicios
# - Load Balancers
# - Persistent Disks
```

### Verificar que No Queden Recursos

```bash
# Ver Load Balancers activos
gcloud compute forwarding-rules list

# Ver discos persistentes
gcloud compute disks list

# Ver IPs estáticas reservadas
gcloud compute addresses list

# Eliminar recursos huérfanos si los hay
gcloud compute forwarding-rules delete <nombre> --region=us-central1
gcloud compute disks delete <nombre> --zone=us-central1-a
```

---

## 📊 Monitoreo de Costos

### Ver Costos Actuales

```bash
# Desde Google Cloud Console
# 1. Navegación > Billing > Reports
# 2. Filtrar por "This month"
# 3. Ver breakdown por servicio

# Configurar alertas de presupuesto:
# Billing > Budgets & alerts
# - Set budget: $50/mes
# - Alert at: 50%, 90%, 100%
```

### Dashboard de Costos Recomendado

```bash
# Ver en tiempo real
gcloud beta billing accounts list
gcloud beta billing budgets list --billing-account=XXXXXX-XXXXXX-XXXXXX
```

---

## 🎓 Próximos Pasos

### 1. Configurar Dominio Propio

```bash
# Comprar dominio en Google Domains o Namecheap
# Configurar DNS A record apuntando a EXTERNAL_IP
# Actualizar ingress-gcp.yaml con tu dominio
# Habilitar HTTPS automático con Google Managed Certificates
```

### 2. Configurar CI/CD

```bash
# Usar Google Cloud Build
# O GitHub Actions con GKE
```

### 3. Implementar Monitoreo

```bash
# Google Cloud Operations (ex-Stackdriver)
# O Prometheus + Grafana en el cluster
```

### 4. Configurar Backups

```bash
# Snapshots automáticos del Persistent Disk
gcloud compute disks snapshot <disk-name> --zone=us-central1-a
```

---

## 📞 Recursos Adicionales

- 📚 [Documentación GKE](https://cloud.google.com/kubernetes-engine/docs)
- 💵 [Calculadora de Precios GCP](https://cloud.google.com/products/calculator)
- 🎓 [GCP Free Tier](https://cloud.google.com/free)
- 🔧 [Kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- 🐛 [GKE Troubleshooting](https://cloud.google.com/kubernetes-engine/docs/troubleshooting)

---

## ⚠️ IMPORTANTE - Recordatorios Finales

1. **SIEMPRE elimina recursos cuando no los uses** para evitar cargos
2. **Configura alertas de presupuesto** en Google Cloud Console
3. **Monitorea tu uso de créditos** regularmente
4. **El Free Trial expira en 90 días** - después pagas o migras a otra solución
5. **Haz backups** de tu base de datos regularmente

---

¡Listo! Tu aplicación Todo-App debería estar corriendo en GCP. 🚀
