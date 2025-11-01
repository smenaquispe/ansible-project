# ⚡ Quick Start - Redespliegue de Todo-App

## 🎯 Si ya tienes el cluster desplegado

### Paso 1: Pre-flight Check

Verifica que todo esté listo:

```bash
cd /home/smenaq/Documents/UNSA/cloud/ansible-project/todo-app/gcp
./preflight-check.fish
```

Si todo está bien (✓ TODO LISTO), continúa al paso 2.

### Paso 2: Login a Docker Hub

```bash
docker login
# Ingresa tu usuario y password de Docker Hub
```

### Paso 3: Redespliegue Completo

```bash
./full-redeploy.fish
```

**Tiempo estimado:** 5-10 minutos

El script automáticamente:

1. ✅ Construye las imágenes (backend + frontend)
2. ✅ Las sube a Docker Hub
3. ✅ Actualiza todos los componentes en Kubernetes
4. ✅ Espera a que todo esté listo
5. ✅ Muestra la URL de acceso

### Paso 4: Acceder a la Aplicación

Una vez completado el script, verás algo como:

```
ACCEDE A TU APLICACIÓN EN:
  http://34.46.137.183
```

Abre esa URL en tu navegador.

---

## 🆘 Si algo falla

### Frontend en blanco o error 504

```bash
# Ver logs del frontend
kubectl logs -l app=todo-frontend -n todo-app --tail=100 -f

# Verificar que sea build de producción
kubectl exec -it deployment/todo-frontend -n todo-app -- ls -la /usr/share/nginx/html

# Debe mostrar: index.html, assets/, etc. (NO node_modules)
```

### Backend no responde

```bash
# Ver logs del backend
kubectl logs -l app=todo-backend -n todo-app --tail=100 -f

# Verificar conectividad
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -n todo-app -- \
  curl -v http://todo-backend:5000/todos
```

### Pods no inician

```bash
# Ver estado
kubectl get pods -n todo-app

# Ver detalles de un pod específico
kubectl describe pod <POD-NAME> -n todo-app

# Ver logs
kubectl logs <POD-NAME> -n todo-app
```

### Ingress sin IP

```bash
# Verificar Ingress
kubectl get ingress -n todo-app

# Ver detalles
kubectl describe ingress todo-app-ingress -n todo-app

# Verificar ingress controller
kubectl get pods -n ingress-nginx

# Si no existe, instalar:
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
```

---

## 📚 Más Información

- **[RESUMEN-CAMBIOS.md](RESUMEN-CAMBIOS.md)** - Lista completa de cambios
- **[GUIA-REDESPLIEGUE.md](GUIA-REDESPLIEGUE.md)** - Guía detallada con troubleshooting
- **[FIX-FRONTEND-BLANK-PAGE.md](FIX-FRONTEND-BLANK-PAGE.md)** - Documentación técnica del fix
- **[README-GCP-DEPLOYMENT.md](README-GCP-DEPLOYMENT.md)** - Guía completa de despliegue inicial

---

## 🔄 Scripts Disponibles

| Script                   | Descripción             | Uso                 |
| ------------------------ | ----------------------- | ------------------- |
| `preflight-check.fish`   | Verifica pre-requisitos | Antes de desplegar  |
| `full-redeploy.fish`     | Redespliegue completo   | Cambios importantes |
| `redeploy-frontend.fish` | Solo frontend           | Cambios en frontend |
| `deploy-gcp.fish`        | Despliegue inicial      | Primera vez         |

---

## ⚙️ Comandos Útiles

```bash
# Ver todos los pods
kubectl get pods -n todo-app -w

# Ver logs en tiempo real
kubectl logs -l app=todo-frontend -n todo-app --tail=100 -f
kubectl logs -l app=todo-backend -n todo-app --tail=100 -f

# Reiniciar un componente
kubectl rollout restart deployment/todo-frontend -n todo-app

# Escalar réplicas
kubectl scale deployment todo-frontend --replicas=3 -n todo-app

# Ver IP del Ingress
kubectl get ingress todo-app-ingress -n todo-app

# Ver eventos
kubectl get events -n todo-app --sort-by='.lastTimestamp'

# Eliminar todo (evitar costos)
kubectl delete namespace todo-app
# O eliminar el cluster completo:
gcloud container clusters delete todo-app-cluster --zone=us-central1-a
```

---

## ✅ Checklist de Validación

Después del redespliegue, verifica:

- [ ] Todos los pods están en estado `Running` (1/1 READY)
- [ ] Ingress tiene una IP pública asignada
- [ ] La página carga sin pantalla en blanco
- [ ] No hay errores 504 en la consola del navegador
- [ ] Puedes agregar tareas
- [ ] Puedes editar tareas
- [ ] Puedes eliminar tareas
- [ ] Puedes marcar/desmarcar tareas como completadas
- [ ] Los datos persisten al recargar la página

---

**¿Primer despliegue?** Ver [README-GCP-DEPLOYMENT.md](README-GCP-DEPLOYMENT.md)
