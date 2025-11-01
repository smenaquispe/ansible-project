# Fix: Frontend mostrando página en blanco - Error 504

## Problema Identificado

El frontend estaba usando **modo desarrollo de Vite** en producción, causando:

- Error 504 al intentar cargar módulos de Vite desde `node_modules/.vite/deps/`
- Página completamente en blanco
- La aplicación intentaba cargar archivos de desarrollo en lugar de un build estático

## Solución Implementada

### 1. Dockerfile de Producción

**Archivo**: `frontend/Dockerfile`

Se cambió de un Dockerfile de desarrollo a uno de **producción multi-stage**:

- **Stage 1 (Build)**: Compila la aplicación con `npm run build`
- **Stage 2 (Production)**: Sirve archivos estáticos con nginx

```dockerfile
# Build stage
FROM node:18-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci --no-audit --no-fund
COPY . .
RUN npm run build

# Production stage
FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

### 2. Configuración de Nginx

**Archivo**: `frontend/nginx.conf` (nuevo)

Configuración optimizada para SPA (Single Page Application):

- Redirección de todas las rutas a `index.html` (para enrutamiento de React)
- Compresión gzip para mejor rendimiento
- Cache para assets estáticos (JS, CSS, imágenes)
- Sin cache para `index.html`

### 3. Actualización del Deployment

**Archivo**: `gcp/frontend-gcp.yaml`

Cambios principales:

- Nueva versión de imagen: `smenaq/todo-frontend:3.0`
- Puerto cambiado de **5173** (Vite dev) a **80** (nginx)
- Reducción de recursos (nginx es más liviano que Vite dev server)
- Eliminada variable de entorno `VITE_BACKEND_URL` (se configura en build time)

```yaml
containers:
  - name: frontend
    image: smenaq/todo-frontend:3.0
    ports:
      - containerPort: 80
```

### 4. Ingress con Rewrite

**Archivo**: `gcp/ingress-gcp.yaml`

Se agregó rewrite para manejar correctamente `/api`:

```yaml
annotations:
  kubernetes.io/ingress.class: "nginx"
  nginx.ingress.kubernetes.io/rewrite-target: /$2
  nginx.ingress.kubernetes.io/use-regex: "true"
spec:
  rules:
    - http:
        paths:
          - path: /api(/|$)(.*)
            pathType: ImplementationSpecific
            backend:
              service:
                name: todo-backend
                port:
                  number: 5000
```

Esto permite que:

- `http://34.46.137.183/api/todos` → `http://todo-backend:5000/todos`
- `http://34.46.137.183/` → `http://todo-frontend:80/`

### 5. Script de Redespliegue

**Archivo**: `gcp/redeploy-frontend.fish` (nuevo)

Script automatizado que:

1. Obtiene la IP del Ingress
2. Construye la imagen con `VITE_API_URL` correcto
3. Sube la imagen a Docker Hub
4. Actualiza el deployment en Kubernetes
5. Fuerza recreación de pods
6. Verifica el estado

## Pasos para Aplicar la Solución

### 1. Actualizar el Ingress

```bash
cd /home/smenaq/Documents/UNSA/cloud/ansible-project/todo-app/gcp
kubectl apply -f ingress-gcp.yaml
```

### 2. Ejecutar el Script de Redespliegue

```bash
./redeploy-frontend.fish
```

El script automáticamente:

- Construirá la nueva imagen con build de producción
- La subirá a Docker Hub
- Actualizará el deployment
- Esperará a que los pods estén listos

### 3. Verificar el Despliegue

```bash
# Ver pods
kubectl get pods -n todo-app -l app=todo-frontend

# Ver logs
kubectl logs -l app=todo-frontend -n todo-app --tail=50 -f

# Verificar que esté sirviendo archivos estáticos
kubectl exec -it deployment/todo-frontend -n todo-app -- ls -la /usr/share/nginx/html
```

### 4. Acceder a la Aplicación

La aplicación estará disponible en: `http://34.46.137.183/`

## Diferencias: Desarrollo vs Producción

| Aspecto        | Desarrollo (Antes)  | Producción (Ahora)           |
| -------------- | ------------------- | ---------------------------- |
| **Servidor**   | Vite Dev Server     | Nginx                        |
| **Puerto**     | 5173                | 80                           |
| **Archivos**   | Código fuente + HMR | Build estático optimizado    |
| **Tamaño**     | ~300MB              | ~50MB                        |
| **Memoria**    | 256Mi               | 128Mi                        |
| **Startup**    | ~30s                | ~5s                          |
| **Hot Reload** | ✅ Sí               | ❌ No (no necesario en prod) |

## Verificación de la Solución

Una vez desplegado, deberías ver:

1. **Página cargando correctamente** (no más pantalla en blanco)
2. **Sin errores 504** en la consola del navegador
3. **Assets cargando desde nginx** (no más referencias a Vite)
4. **Llamadas a la API funcionando** (`/api/todos`, etc.)

## Troubleshooting

### Si la página sigue en blanco:

```bash
# Ver logs del frontend
kubectl logs -l app=todo-frontend -n todo-app --tail=100

# Ver logs del nginx dentro del pod
kubectl exec -it deployment/todo-frontend -n todo-app -- cat /var/log/nginx/error.log
```

### Si las llamadas a la API fallan:

```bash
# Verificar que el backend esté corriendo
kubectl get pods -n todo-app -l app=todo-backend

# Ver logs del backend
kubectl logs -l app=todo-backend -n todo-app --tail=50 -f

# Probar el backend directamente
kubectl run -it --rm debug --image=busybox --restart=Never -n todo-app -- wget -O- http://todo-backend:5000/todos
```

### Si el Ingress no tiene IP:

```bash
# Ver estado del Ingress
kubectl get ingress -n todo-app
kubectl describe ingress todo-app-ingress -n todo-app

# Ver logs del ingress controller
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller
```

## Archivos Modificados

- ✏️ `frontend/Dockerfile` - Convertido a build multi-stage con nginx
- ➕ `frontend/nginx.conf` - Configuración de nginx para SPA
- ✏️ `gcp/frontend-gcp.yaml` - Actualizado para usar nginx en puerto 80
- ✏️ `gcp/ingress-gcp.yaml` - Agregado rewrite para `/api`
- ➕ `gcp/redeploy-frontend.fish` - Script de redespliegue automatizado

## Notas Importantes

1. **Build Time vs Runtime**: La URL de la API se configura en build time con `VITE_API_URL`, no en runtime
2. **Caché del Navegador**: Puede ser necesario hacer hard refresh (Ctrl+Shift+R) para ver los cambios
3. **Tiempo de Propagación**: Los cambios pueden tardar 1-2 minutos en aplicarse completamente
