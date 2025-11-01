# 📝 Checklist Pre-Despliegue GCP

Usa esta lista para verificar que tienes todo listo antes de desplegar en GCP.

## ✅ Cuenta y Configuración Inicial

- [ ] **Cuenta de GCP creada**
  - Ir a: https://cloud.google.com
  - Crear cuenta Gmail si no tienes
- [ ] **Free Trial activado**
  - $300 de crédito por 90 días
  - Tarjeta de crédito agregada (requerido, pero no se cobra automáticamente)
- [ ] **Proyecto de GCP creado**
  - Nombre sugerido: `todo-app-project`
  - Anotar el PROJECT_ID: `________________________`
- [ ] **Facturación habilitada**
  - Proyecto vinculado a cuenta de facturación
  - Verificado en: Console > Billing

---

## ✅ Herramientas Instaladas

- [ ] **gcloud CLI instalado**

  ```bash
  gcloud --version
  # Debe mostrar: Google Cloud SDK xxx.x.x
  ```

- [ ] **gcloud autenticado**

  ```bash
  gcloud auth list
  # Debe mostrar tu cuenta activa
  ```

- [ ] **kubectl instalado**

  ```bash
  kubectl version --client
  # Debe mostrar versión sin error
  ```

- [ ] **Proyecto configurado en gcloud**
  ```bash
  gcloud config set project TU_PROJECT_ID
  gcloud config list
  ```

---

## ✅ APIs Habilitadas (el script lo hace automáticamente)

- [ ] **Kubernetes Engine API**

  ```bash
  gcloud services enable container.googleapis.com
  ```

- [ ] **Compute Engine API**
  ```bash
  gcloud services enable compute.googleapis.com
  ```

---

## ✅ Imágenes Docker Disponibles

Verificar que las imágenes existen en Docker Hub:

- [ ] **Frontend**: `smenaq/todo-frontend:2.1`
  - Verificar: https://hub.docker.com/r/smenaq/todo-frontend
- [ ] **Backend**: `smenaq/todo-backend:2.0`
  - Verificar: https://hub.docker.com/r/smenaq/todo-backend
- [ ] **Database**: `smenaq/todo-db:2.0`
  - Verificar: https://hub.docker.com/r/smenaq/todo-db

Si las imágenes no existen, construirlas:

```bash
cd todo-app/frontend
docker build -t smenaq/todo-frontend:2.1 .
docker push smenaq/todo-frontend:2.1

cd ../backend
docker build -t smenaq/todo-backend:2.0 .
docker push smenaq/todo-backend:2.0

cd ../db
docker build -t smenaq/todo-db:2.0 .
docker push smenaq/todo-db:2.0
```

---

## ✅ Archivos de Configuración

Verificar que existen estos archivos en `todo-app/gcp/`:

- [ ] `namespace.yaml`
- [ ] `db-gcp.yaml`
- [ ] `backend-gcp.yaml`
- [ ] `frontend-gcp.yaml`
- [ ] `ingress-gcp.yaml`
- [ ] `deploy-gcp.fish` (o `deploy-gcp.sh`)

---

## ✅ Configuración de Costos

- [ ] **Presupuesto configurado**

  - Console > Billing > Budgets & alerts
  - Límite sugerido: $50/mes
  - Alertas al 50%, 90%, 100%

- [ ] **Email de alertas verificado**
  - Recibirás notificaciones cuando se acerque al límite

---

## ✅ Decisiones Técnicas

- [ ] **Región seleccionada**: `us-central1` (más barata)
  - Alternativas: `us-east1`, `us-west1`
- [ ] **Tipo de máquina**: `e2-small` (2 vCPU, 2GB RAM)
  - Más barato: `e2-micro` (no recomendado para GKE)
  - Más potente: `e2-medium` (más caro)
- [ ] **Número de nodos**: 2
  - Mínimo para HA (High Availability)
  - Puede escalar a 3 con autoscaling

---

## ✅ Plan de Backup

- [ ] **Estrategia de backup decidida**
  - Opción 1: Snapshots manuales del PVC
  - Opción 2: Script automatizado
  - Opción 3: Velero para backups completos

---

## ✅ Plan de Eliminación

- [ ] **Fecha de revisión programada**

  - Revisar uso cada semana
  - Fecha de eliminación si no se usa: `____/____/____`

- [ ] **Comando de eliminación conocido**
  ```bash
  gcloud container clusters delete todo-app-cluster --zone=us-central1-a
  ```

---

## 🚀 Listo para Desplegar

Si marcaste TODAS las casillas, estás listo para ejecutar:

```bash
cd /home/smenaq/Documents/UNSA/cloud/ansible-project/todo-app/gcp
./deploy-gcp.fish
```

O para despliegue manual, sigue: `README-GCP-DEPLOYMENT.md`

---

## 📞 En Caso de Problemas

### Error: "Quota exceeded"

- Solución: Reducir número de nodos a 1
- O esperar y reintentar

### Error: "Billing not enabled"

- Solución: Console > Billing > Link project

### Error: "Images not found"

- Solución: Verificar que las imágenes existen en Docker Hub
- O cambiar a imágenes públicas de prueba

### Cluster tarda mucho en crearse

- Normal: 5-10 minutos
- Si pasa de 15 minutos, cancelar y reintentar

---

## 💡 Tips Finales

1. **Guarda el PROJECT_ID** en un lugar seguro
2. **Toma screenshots** de la configuración inicial
3. **Documenta cambios** que hagas a los YAML
4. **Prueba localmente** con Kind antes de GCP si es posible
5. **No expongas secretos** en los YAML (usa Secrets de K8s)

---

✨ **¡Buena suerte con tu despliegue!** ✨
