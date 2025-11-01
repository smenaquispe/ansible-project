# Deploy App Role

Role de Ansible para desplegar la aplicación Todo en Kubernetes.

## Descripción

Este role maneja el despliegue completo de la aplicación Todo, incluyendo:

- Base de datos PostgreSQL
- Backend API (Node.js)
- Frontend web (React)

## Variables

```yaml
kubeconfig_path: ~/.kube/config # Path al archivo kubeconfig
namespace: default # Namespace de Kubernetes
```

## Dependencias

- `kubernetes.core` collection
- Cluster de Kubernetes activo
- kubectl configurado

## Ejemplo de Uso

```yaml
- hosts: localhost
  roles:
    - deploy-app
  vars:
    kubeconfig_path: ~/.kube/config
    namespace: todo-app
```

## Tasks

### main.yaml

Incluye todas las tasks necesarias para el despliegue:

1. Despliegue de base de datos
2. Despliegue de backend
3. Despliegue de frontend
