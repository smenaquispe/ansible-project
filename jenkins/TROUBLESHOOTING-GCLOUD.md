# Solución al Error: "gcloud: not found" en Jenkins

## 🐛 Problema

Al ejecutar el pipeline de Jenkins en el stage "Push Docker Images", aparecía el error:

```
/var/jenkins_home/workspace/.../script.sh.copy: 3: gcloud: not found
script returned exit code 127
```

## 🔍 Causa

El contenedor de Jenkins no tenía Google Cloud SDK (`gcloud` CLI) instalado, necesario para autenticarse y subir imágenes Docker a Google Container Registry (GCR).

## ✅ Solución Aplicada

### 1. Agregar repositorio de Google Cloud SDK

El repositorio ya estaba agregado previamente, pero si no estuviera:

```bash
docker exec -u root jenkins bash -c '
  curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
  gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg && \
  echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" > /etc/apt/sources.list.d/google-cloud-sdk.list
'
```

### 2. Instalar Google Cloud SDK y kubectl

```bash
docker exec -u root jenkins apt-get update
docker exec -u root jenkins apt-get install -y google-cloud-cli google-cloud-cli-gke-gcloud-auth-plugin kubectl
```

### 3. Verificar instalación

```bash
docker exec jenkins gcloud --version
docker exec jenkins kubectl version --client
```

Salida esperada:
```
Google Cloud SDK 546.0.0
...
kubectl 1.33.5
```

## 🔧 Solución Alternativa: Usar el script de setup

El script `jenkins/setup-jenkins.fish` o `jenkins/setup-jenkins.sh` ya incluye la instalación de todas las herramientas necesarias:

```fish
# Si usas Fish shell
./jenkins/setup-jenkins.fish
```

```bash
# Si usas Bash
./jenkins/setup-jenkins.sh
```

## 📝 Notas

- **Versión instalada**: Google Cloud SDK 546.0.0
- **Plugins incluidos**: 
  - `gke-gcloud-auth-plugin`: Autenticación con GKE
  - `kubectl`: Cliente de Kubernetes
  - `anthoscli`: Herramientas Anthos (opcional)

## 🚀 Siguiente Paso

Después de instalar `gcloud`, asegúrate de tener configuradas las credenciales de GCP en Jenkins:

1. **Jenkins → Manage Jenkins → Manage Credentials**
2. Agregar dos credenciales:
   - **Secret file** con ID `gcp-service-account-key`: JSON de la cuenta de servicio
   - **Secret text** con ID `gcp-project-id`: ID del proyecto GCP

## ✅ Verificación

El pipeline debería ahora pasar el stage "Push Docker Images" exitosamente:

```
📤 Publicando imágenes a GCR...
Activated service account credentials for: [jenkins@PROJECT_ID.iam.gserviceaccount.com]
Configured Docker to push to gcr.io
✅ Push completed successfully
```

## 🔗 Referencias

- [Google Cloud SDK Documentation](https://cloud.google.com/sdk/docs)
- [Installing Google Cloud SDK on Debian/Ubuntu](https://cloud.google.com/sdk/docs/install#deb)
- [GKE Authentication Plugin](https://cloud.google.com/blog/products/containers-kubernetes/kubectl-auth-changes-in-gke)
