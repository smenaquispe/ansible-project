# 🚀 Guía de Inicio Rápido

Esta guía te ayudará a comenzar con el proyecto en menos de 5 minutos.

## Prerrequisitos

```bash
# Verificar Python
python --version  # >= 3.11

# Instalar uv si no lo tienes
curl -LsSf https://astral.sh/uv/install.sh | sh
```

## Inicio en 3 Pasos

### 1️⃣ Configurar Entorno

```bash
# Fish shell
./scripts/setup.fish

# Bash shell
./scripts/setup.sh
```

Esto instala:

- ✅ Todas las dependencias
- ✅ Herramientas de desarrollo
- ✅ Pre-commit hooks

### 2️⃣ Crear Cluster Kubernetes

```bash
# Fish
./scripts/create-cluster.fish

# Bash
./scripts/create-cluster.sh
```

### 3️⃣ Desplegar Aplicación

```bash
uv run deploy
```

## ✅ Verificar Despliegue

```bash
# Ver pods
kubectl get pods

# Ver servicios
kubectl get services

# Port-forward
kubectl port-forward service/todo-frontend 30080:5173
```

Acceder a: http://localhost:30080

## 📝 Comandos Útiles

```bash
# Ejecutar tests
uv run pytest

# Linting
uv run ruff check src/

# Formato
uv run ruff format src/

# O usar make
make test
make lint
make format
```

## 🆘 Problemas Comunes

### uv no encontrado

```bash
# Instalar uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Agregar a PATH (fish)
fish_add_path ~/.cargo/bin
```

### Kind no instalado

```bash
# Linux
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

### Puerto ya en uso

```bash
# Cambiar puerto en port-forward
kubectl port-forward service/todo-frontend 8080:5173
```

## 📚 Más Información

- [README completo](README.md)
- [Guía de contribución](CONTRIBUTING.md)
- [Resumen de refactorización](REFACTORING-SUMMARY.md)

## 💡 Tips

- Usa `uv run` para todos los comandos Python
- Los scripts están en `scripts/` (fish y bash)
- La documentación está en `docs/`
- Los tests están en `tests/`

---

**¿Listo para producción?** Revisa `docs/README-GCP-DEPLOYMENT.md` para GCP.
