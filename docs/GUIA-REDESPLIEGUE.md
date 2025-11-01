# 🚀 Guía de Redespliegue Completo

## 📋 Cambios Implementados

### ✅ Nuevo Sistema de Producción

1. **Frontend con Nginx** (en lugar de Vite dev server)

   - Build estático optimizado
   - Puerto 80
   - Tamaño reducido: ~50MB

2. **Ingress con Rewrite**

   - `/api/*` → redirige al backend
   - `/` → sirve el frontend

3. **Configuración Optimizada**
   - Recursos ajustados para Free Tier
   - Health checks mejorados
   - Variables de entorno correctas

## 🎯 Pasos para Redesplegar

### Opción 1: Redespliegue Completo (Recomendado)

Usa este script cuando hayas hecho cambios significativos:

```bash
cd /home/smenaq/Documents/UNSA/cloud/ansible-project/todo-app/gcp

# Asegúrate de estar logueado en Docker Hub
docker login

# Ejecuta el script de redespliegue completo
./full-redeploy.fish
```

**El script automáticamente:**

1. ✅ Construye las imágenes Docker (backend + frontend)
2. ✅ Las sube a Docker Hub
3. ✅ Actualiza la base de datos
4. ✅ Redesplega el backend
5. ✅ Redesplega el frontend con nginx
6. ✅ Actualiza el Ingress
7. ✅ Espera a que todo esté listo
8. ✅ Muestra la URL de acceso

**Tiempo estimado:** 5-10 minutos

### Opción 2: Solo Frontend

Si solo modificaste el frontend:

```bash
cd /home/smenaq/Documents/UNSA/cloud/ansible-project/todo-app/gcp
./redeploy-frontend.fish
```

**Tiempo estimado:** 2-3 minutos

## 📊 Verificación Post-Despliegue

### 1. Verificar que todos los pods estén corriendo

```bash
kubectl get pods -n todo-app
```

Deberías ver algo como:

```
NAME                             READY   STATUS    RESTARTS   AGE
todo-backend-xxx                 1/1     Running   0          2m
todo-backend-yyy                 1/1     Running   0          2m
todo-db-xxx                      1/1     Running   0          3m
todo-frontend-xxx                1/1     Running   0          1m
todo-frontend-yyy                1/1     Running   0          1m
```

### 2. Obtener la IP del Ingress

```bash
kubectl get ingress -n todo-app
```

Espera hasta que aparezca una IP en la columna `ADDRESS`.

### 3. Probar la Aplicación

Abre en tu navegador: `http://<IP-DEL-INGRESS>`

**Deberías ver:**

- ✅ La interfaz de Todo App cargando correctamente
- ✅ Sin errores 504 en la consola del navegador
- ✅ Puedes agregar, editar y eliminar tareas

## 🔍 Troubleshooting

### Problema: Pods no inician

```bash
# Ver estado detallado
kubectl describe pod <POD-NAME> -n todo-app

# Ver logs
kubectl logs <POD-NAME> -n todo-app --tail=100
```

### Problema: Frontend en blanco

```bash
# Ver logs del frontend
kubectl logs -l app=todo-frontend -n todo-app --tail=100

# Verificar que sea build de producción (debe mostrar archivos estáticos)
kubectl exec -it deployment/todo-frontend -n todo-app -- ls -la /usr/share/nginx/html

# Debería mostrar: index.html, assets/, vite.svg, etc.
```

### Problema: Error al conectar con el backend

```bash
# Verificar backend
kubectl logs -l app=todo-backend -n todo-app --tail=100

# Probar backend directamente
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -n todo-app -- \
  curl -v http://todo-backend:5000/todos
```

### Problema: Ingress sin IP

```bash
# Ver estado del Ingress
kubectl describe ingress todo-app-ingress -n todo-app

# Ver eventos
kubectl get events -n todo-app --sort-by='.lastTimestamp'

# Verificar que el ingress controller esté instalado
kubectl get pods -n ingress-nginx
```

Si el ingress-nginx no está instalado:

```bash
# Instalar nginx ingress controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
```

### Problema: Error al subir a Docker Hub

```bash
# Hacer login
docker login

# Verificar que las imágenes se construyeron
docker images | grep todo

# Retaggear si es necesario
docker tag smenaq/todo-frontend:3.0 smenaq/todo-frontend:3.0
docker push smenaq/todo-frontend:3.0
```

## 📝 Comandos Útiles

### Monitoreo en Tiempo Real

```bash
# Ver todos los pods actualizándose
kubectl get pods -n todo-app -w

# Logs en tiempo real del frontend
kubectl logs -l app=todo-frontend -n todo-app --tail=100 -f

# Logs en tiempo real del backend
kubectl logs -l app=todo-backend -n todo-app --tail=100 -f
```

### Debugging

```bash
# Entrar a un pod del frontend
kubectl exec -it deployment/todo-frontend -n todo-app -- /bin/sh

# Dentro del pod, verificar nginx
cat /etc/nginx/conf.d/default.conf
ls -la /usr/share/nginx/html

# Entrar al pod del backend
kubectl exec -it deployment/todo-backend -n todo-app -- /bin/sh

# Probar conexión a la DB desde el backend
kubectl exec -it deployment/todo-backend -n todo-app -- \
  node -e "console.log(process.env.DB_HOST)"
```

### Reiniciar Componentes

```bash
# Reiniciar frontend
kubectl rollout restart deployment/todo-frontend -n todo-app

# Reiniciar backend
kubectl rollout restart deployment/todo-backend -n todo-app

# Reiniciar base de datos (CUIDADO: perderás datos)
kubectl rollout restart statefulset/todo-db -n todo-app
```

### Escalar Componentes

```bash
# Escalar frontend a 3 réplicas
kubectl scale deployment todo-frontend --replicas=3 -n todo-app

# Escalar backend a 3 réplicas
kubectl scale deployment todo-backend --replicas=3 -n todo-app

# Ver el escalado en acción
kubectl get pods -n todo-app -w
```

## 🧹 Limpieza (Evitar Costos)

### Eliminar solo la aplicación (mantener cluster)

```bash
kubectl delete namespace todo-app
```

### Eliminar todo el cluster

```bash
gcloud container clusters delete todo-app-cluster --zone=us-central1-a
```

## 📊 Diferencias: Antes vs Ahora

| Componente          | Antes (Dev)       | Ahora (Prod)       |
| ------------------- | ----------------- | ------------------ |
| **Frontend Server** | Vite Dev (5173)   | Nginx (80)         |
| **Frontend Size**   | ~300MB            | ~50MB              |
| **Frontend Build**  | Source + HMR      | Static Optimized   |
| **API Routing**     | Direct to backend | Via Ingress `/api` |
| **Environment**     | Development       | Production         |
| **Performance**     | Slower            | Faster             |
| **Memory Usage**    | 256Mi             | 128Mi              |

## ✅ Checklist de Validación

Después del redespliegue, verifica:

- [ ] Todos los pods están en estado `Running`
- [ ] Ingress tiene una IP pública asignada
- [ ] La página carga sin errores 504
- [ ] No hay errores en la consola del navegador
- [ ] Puedes agregar tareas
- [ ] Puedes editar tareas
- [ ] Puedes eliminar tareas
- [ ] Puedes marcar tareas como completadas
- [ ] Los datos persisten después de recargar la página

## 🆘 Soporte

Si algo no funciona:

1. Revisa los logs de cada componente
2. Verifica que todas las imágenes Docker estén disponibles en Docker Hub
3. Confirma que el Ingress Controller está instalado
4. Verifica la configuración de red del cluster
5. Revisa los eventos de Kubernetes para errores

---

**Última actualización:** Octubre 2025  
**Autor:** Deploy automatizado para GCP Free Tier
