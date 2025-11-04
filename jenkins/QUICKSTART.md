## 🚀 CI/CD con Jenkins

Este proyecto ahora incluye configuración completa de CI/CD con Jenkins. Los cambios en código o infraestructura se despliegan automáticamente.

### Inicio Rápido

```bash
# Instalar Jenkins con Docker
cd jenkins
./setup-jenkins.fish docker

# O en Kubernetes
./setup-jenkins.fish kubernetes
```

Ver documentación completa en [`jenkins/README.md`](jenkins/README.md)

### Pipeline Automático

El pipeline detecta automáticamente:

- ✅ Cambios en código → Construye y despliega
- ✅ Cambios en infraestructura → Actualiza cluster
- ✅ Cambios en configuración → Redespliega

### Webhooks

Configura webhooks en GitHub/GitLab para despliegues automáticos al hacer push.
