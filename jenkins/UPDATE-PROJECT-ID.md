# Actualizar PROJECT_ID en Jenkins

## 🔧 Problema Actual

El pipeline está usando un `PROJECT_ID` incorrecto. El proyecto correcto es:
```
ansible-project-475919
```

## ✅ Solución: Actualizar Credencial en Jenkins

### Opción 1: Actualizar desde la UI de Jenkins

1. **Ve a Jenkins**: http://localhost:8080
2. **Navega a**: Manage Jenkins → Manage Credentials
3. **Selecciona**: (global) → Update/Add credential
4. **Busca o crea** la credencial con ID: `gcp-project-id`
   - **Kind**: Secret text
   - **Secret**: `ansible-project-475919`
   - **ID**: `gcp-project-id`
   - **Description**: GCP Project ID para ansible-project
5. **Guarda** los cambios

### Opción 2: Verificar y actualizar con Jenkins CLI

```bash
# Ver credenciales existentes
docker exec jenkins cat /var/jenkins_home/credentials.xml

# O actualizar directamente la credencial de texto
# (Necesitas el plugin Jenkins CLI o usar la UI)
```

## 🔐 Permisos Ya Configurados

Ya se habilitaron las APIs necesarias y se dieron los permisos correctos a la cuenta de servicio:

✅ **APIs Habilitadas:**
- Cloud Resource Manager API
- Container Registry API  
- Artifact Registry API

✅ **Permisos Asignados a `cicd-service@ansible-project-475919.iam.gserviceaccount.com`:**
- `roles/storage.admin` - Para subir imágenes a GCR
- `roles/artifactregistry.writer` - Para Artifact Registry

## 🚀 Después de Actualizar

1. **Ejecuta el pipeline nuevamente** desde Jenkins UI
2. El stage "Push Docker Images" debería funcionar correctamente
3. Las imágenes se subirán a: `gcr.io/ansible-project-475919/`

## 📝 Verificación

Puedes verificar que el proyecto es correcto ejecutando:

```bash
gcloud config get-value project
# Debería mostrar: ansible-project-475919

# Ver las imágenes después del push exitoso
gcloud container images list --project=ansible-project-475919
```

## ⚠️ Nota Importante

El `Jenkinsfile` obtiene el `PROJECT_ID` de la credencial con ID `gcp-project-id`. Asegúrate de que esta credencial exista y tenga el valor correcto: `ansible-project-475919`
