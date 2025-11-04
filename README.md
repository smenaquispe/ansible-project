# Ansible Kubernetes Todo App 🚀

[![Python 3.11+](https://img.shields.io/badge/python-3.11+-blue.svg)](https://www.python.org/downloads/)
[![uv](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/astral-sh/uv/main/assets/badge/v0.json)](https://github.com/astral-sh/uv)
[![Ansible](https://img.shields.io/badge/ansible-%3E%3D10.0-red.svg)](https://www.ansible.com/)
[![Kubernetes](https://img.shields.io/badge/kubernetes-ready-brightgreen.svg)](https://kubernetes.io/)

Proyecto completo de despliegue automatizado de una aplicación Todo List usando Ansible, Kubernetes, y herramientas cloud-native. Este proyecto utiliza **uv** como gestor de paquetes y entornos virtuales para Python.

## 📋 Tabla de Contenidos

- [Características](#-características)
- [Requisitos](#-requisitos)
- [Instalación Rápida](#-instalación-rápida)
- [Estructura del Proyecto](#-estructura-del-proyecto)
- [Uso](#-uso)
- [Desarrollo](#-desarrollo)
- [Documentación Adicional](#-documentación-adicional)

## ✨ Características

- **Arquitectura de Microservicios**: Frontend (React+Vite), Backend (Node.js+Express), Base de Datos (PostgreSQL)
- **Despliegue Automatizado**: Ansible playbooks para despliegue en Kubernetes
- **CI/CD con Jenkins**: Pipeline automático para builds, tests y despliegues
- **Multi-entorno**: Soporte para Kind (local) y Google Cloud Platform (GCP)
- **Monitoreo**: Integración con Prometheus y Grafana
- **Gestión con uv**: Todo el proyecto usa uv para máxima velocidad y reproducibilidad
- **Scripts Fish y Bash**: Soporte para ambos shells

## 🔧 Requisitos

### Herramientas Requeridas

```bash
# Python 3.11+
python --version

# uv (gestor de paquetes)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Docker
docker --version

# Kind (Kubernetes in Docker)
kind --version

# kubectl
kubectl version --client

# (Opcional) gcloud CLI para despliegues en GCP
gcloud --version
```

### Instalación de Herramientas

```bash
# Instalar uv (recomendado)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Instalar Kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Instalar kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

## 🚀 Quick Start

### 1. Clonar el Repositorio

```bash
git clone https://github.com/unsa-cloud/ansible-project.git
cd ansible-project
```

### 2. Configurar Prerrequisitos

```bash
# Instalar Python, Docker, kubectl, gcloud CLI
# Ver sección de requisitos arriba

# Instalar dependencias de Python
pip install ansible kubernetes
ansible-galaxy collection install kubernetes.core
```

### 3. Workflow Completo de Despliegue

```bash
# Paso 1: Subir imágenes a Docker Hub
./scripts/push-images.fish 1.0.0

# Paso 2: Crear cluster en GCP
./scripts/create-cluster.fish

# Paso 3: Desplegar la aplicación
./scripts/deploy.fish

# Paso 4: Obtener la IP del Load Balancer (espera 5-10 min)
kubectl get ingress -n todo-app
```

### 4. Actualizar la Aplicación

```bash
# Después de hacer cambios en el código:
./scripts/push-images.fish 1.1.0
./scripts/deploy.fish --update
```

### 5. Limpiar (para evitar costos)

```bash
./scripts/delete-cluster.fish
```

## 📁 Estructura del Proyecto

```
ansible-project/
├── src/
│   └── app/                     # Aplicación Todo (frontend, backend, db)
│       ├── frontend/            # React + Vite
│       ├── backend/             # Node.js + Express
│       └── db/                  # PostgreSQL
├── ansible/                     # Ansible automation
│   ├── playbooks/               # Playbooks de Ansible
│   │   ├── deploy-gcp.yml       # Deploy a GKE
│   │   ├── create-cluster.yml   # Crear cluster
│   │   ├── update-cluster.yml   # Actualizar infraestructura
│   │   └── build-images.yml     # Construir imágenes Docker
│   └── roles/                   # Roles de Ansible
│       └── deploy-app/
│           ├── tasks/
│           └── README.md
├── kubernetes/
│   ├── base/                    # Manifiestos para Kind local
│   │   ├── backend.yaml
│   │   ├── frontend.yaml
│   │   ├── db.yaml
│   │   ├── kind-config.yaml
│   │   └── docker-compose.yml
│   └── gcp/                     # Manifiestos para GCP
│       ├── backend-gcp.yaml
│       ├── frontend-gcp.yaml
│       ├── db-gcp.yaml
│       ├── ingress-gcp.yaml
│       └── namespace.yaml
├── jenkins/                     # CI/CD con Jenkins 🆕
│   ├── README.md                # Guía completa de Jenkins
│   ├── QUICKSTART.md            # Inicio rápido
│   ├── setup-jenkins.fish       # Script de instalación
│   ├── setup-jenkins.sh         # Script de instalación (bash)
│   └── jenkins-values.yaml      # Valores para Helm
├── scripts/                     # Scripts de gestión y deployment
│   ├── push-images.fish         # Subir imágenes a Docker Hub
│   ├── create-cluster.fish      # Crear cluster GKE
│   ├── delete-cluster.fish      # Eliminar cluster GKE
│   ├── deploy.fish              # Desplegar/redesplegar con Ansible
│   └── README.md                # Documentación de scripts
├── docs/                        # Documentación
├── tests/                       # Tests unitarios
├── Jenkinsfile                  # Pipeline de CI/CD 🆕
├── pyproject.toml              # Configuración del proyecto
└── README.md
```

## 🎯 Uso

### Comandos Principales con uv

````bash
# Desplegar aplicación
uv run python scripts/deploy.py
# o usar el script directo
./scripts/deploy.fish  # o ./scripts/deploy.sh

# Ejecutar tests
uv run pytest

# Linting y formato
uv run ruff check scripts/
uv run ruff format scripts/

# Lint de Ansible playbooks
uv run ansible-lint ansible/
## 📚 Scripts Disponibles

Para información detallada sobre cada script, ver [scripts/README.md](scripts/README.md)

### 1. Push Images - Subir a Docker Hub

```bash
./scripts/push-images.fish [version]
````

### 2. Create Cluster - Crear cluster GKE

```bash
./scripts/create-cluster.fish
```

### 3. Deploy - Desplegar aplicación

```bash
# Deploy completo
./scripts/deploy.fish

# Actualizar/redesplegar
./scripts/deploy.fish --update
```

### 4. Delete Cluster - Eliminar cluster

```bash
./scripts/delete-cluster.fish
```

## 🔍 Comandos Útiles de Kubernetes

```bash
# Ver todos los recursos
kubectl get all -n todo-app

# Ver pods
kubectl get pods -n todo-app

# Ver logs
kubectl logs -l app=todo-backend -n todo-app --tail=50 -f
kubectl logs -l app=todo-frontend -n todo-app --tail=50 -f

# Describir recursos
kubectl describe pod POD_NAME -n todo-app
kubectl describe ingress -n todo-app

# Ver eventos
kubectl get events -n todo-app --sort-by='.lastTimestamp'

# Escalar deployments
kubectl scale deployment todo-backend --replicas=3 -n todo-app
```

## 🛠️ Desarrollo

### Estructura de la Aplicación

- **Frontend**: React + Vite + Nginx
- **Backend**: Node.js + Express
- **Database**: PostgreSQL

### Modificar el Código

1. Edita los archivos en `src/app/`
2. Construye y sube nuevas imágenes: `./scripts/push-images.fish 1.x.x`
3. Actualiza el deployment: `./scripts/deploy.fish --update`
   uv run pre-commit run --all-files

````

## � CI/CD con Jenkins

Este proyecto incluye configuración completa de CI/CD que automatiza todo el proceso de despliegue.

### Inicio Rápido con Jenkins

```bash
cd jenkins
./setup-jenkins.fish docker  # Instala Jenkins con Docker
````

### Características del Pipeline

- ✅ **Detección automática de cambios** en código, infraestructura y configuración
- ✅ **Tests automáticos** con cobertura de código
- ✅ **Build y push de imágenes Docker** a Google Container Registry
- ✅ **Despliegue automático** a GKE usando Ansible
- ✅ **Verificación de salud** post-despliegue
- ✅ **Webhooks** para GitHub/GitLab

### Configuración

Ver la [guía completa de Jenkins](jenkins/README.md) para:

- Instalación en Docker o Kubernetes
- Configuración de credenciales
- Setup de webhooks
- Troubleshooting

## �📚 Documentación Adicional

- **CI/CD**: [jenkins/README.md](jenkins/README.md) - Guía completa de CI/CD con Jenkins 🆕
- **Aplicación**: [TODO-APP.md](docs/TODO-APP.md) - Descripción detallada de la aplicación
- **Inicio Rápido**: [QUICK-START.md](docs/QUICK-START.md) - Guía de inicio rápido para GCP
- **Redespliegue**: [GUIA-REDESPLIEGUE.md](docs/GUIA-REDESPLIEGUE.md) - Guía de redespliegue
- **Estructura**: [ESTRUCTURA.md](docs/ESTRUCTURA.md) - Estructura de archivos detallada

### Scripts de GCP

Para despliegues en Google Cloud Platform, revisar:

- `scripts/deploy-gcp.fish` / `scripts/deploy-gcp.sh`
- `scripts/preflight-check.fish`
- `scripts/quick-frontend.fish`
- `scripts/full-redeploy.fish`

## 🤝 Contribuir

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📝 Licencia

Este proyecto está bajo la licencia MIT - ver el archivo [LICENSE](LICENSE) para más detalles.

## 👥 Autores

UNSA Cloud Team - Universidad Nacional de San Agustín

## 🙏 Agradecimientos

- Equipo de Ansible por las excelentes herramientas de automatización
- Comunidad de Kubernetes
- Proyecto uv por el gestor de paquetes ultrarrápido
- Todos los contribuidores del proyecto

---

**Nota**: Este proyecto utiliza `uv` para gestión de dependencias. Para más información sobre uv, visita [https://github.com/astral-sh/uv](https://github.com/astral-sh/uv)

```

```
