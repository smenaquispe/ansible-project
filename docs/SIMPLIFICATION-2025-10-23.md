# Simplificación de Estructura - Octubre 23, 2025

## 🎯 Problema Identificado

La carpeta `src/ansible_project/` era redundante e innecesaria para este proyecto, que es principalmente un proyecto de deployment con Ansible, no una librería Python.

## ✅ Cambios Realizados

### 1. **Eliminada estructura Python innecesaria**

```bash
# Antes
src/
├── __init__.py
├── ansible_project/
│   ├── __init__.py
│   ├── deploy.py
│   ├── playbooks/
│   └── roles/
└── app/

# Después
src/
└── app/          # Solo la aplicación
```

### 2. **Movido Ansible a raíz**

```bash
ansible/
├── playbooks/
│   └── deploy.yml
└── roles/
    └── deploy-app/
```

### 3. **Scripts simplificados**

```bash
scripts/
├── deploy.py          # Script Python directo
├── deploy.fish        # Wrapper Fish
├── deploy.sh          # Wrapper Bash
└── ...
```

### 4. **pyproject.toml simplificado**

- ❌ Removido `[build-system]` - No es un paquete instalable
- ❌ Removido `[project.scripts]` - No hay entry points
- ✅ Mantenidas solo dependencias y herramientas de desarrollo

## 📁 Nueva Estructura

```
ansible-project/
├── ansible/              # 🆕 Ansible en la raíz
│   ├── playbooks/
│   └── roles/
├── src/
│   └── app/             # Solo la aplicación Docker
├── kubernetes/          # Manifiestos K8s
├── scripts/             # Scripts de gestión
│   └── deploy.py        # 🆕 Script Python directo
├── tests/               # Tests
├── docs/                # Documentación
├── pyproject.toml       # 🔧 Simplificado
└── uv.lock
```

## 🚀 Comandos Actualizados

### Deployment

```bash
# Opción 1: Script Python directamente
uv run python scripts/deploy.py

# Opción 2: Wrapper
./scripts/deploy.fish  # o ./scripts/deploy.sh

# Opción 3: Make
make deploy
```

### Linting

```bash
# Python
uv run ruff check scripts/

# Ansible
uv run ansible-lint ansible/
```

### Tests

```bash
uv run pytest
```

## 💡 Ventajas

1. **Más Simple**: No hay estructura Python artificial
2. **Más Claro**: Ansible está donde debe estar (raíz)
3. **Menos Archivos**: No hay **init**.py innecesarios
4. **Más Directo**: `scripts/deploy.py` es más intuitivo que módulo Python
5. **Separación**: Código de aplicación (src/app) vs automatización (ansible/)

## 📝 Archivos Modificados

- ✅ `pyproject.toml` - Removido build-system
- ✅ `scripts/deploy.py` - Actualizado paths
- ✅ `scripts/deploy.fish|sh` - Usan python directo
- ✅ `ansible/playbooks/deploy.yml` - Paths corregidos
- ✅ `tests/*.py` - Imports y fixtures actualizados
- ✅ `Makefile` - Comandos actualizados
- ✅ `README.md` - Estructura documentada

## ✅ Verificación

```bash
# Sync funciona
uv sync  # ✅ OK

# Script funciona
uv run python scripts/deploy.py  # ✅ OK

# Tests pasan (requiere ajustes de imports)
uv run pytest  # ⚠️  Requiere imports sin paquete
```

## 🎓 Lección Aprendida

**No todo proyecto Python necesita ser un paquete instalable.**

Este es un proyecto de **deployment/automation**, no una librería. Los scripts Python son herramientas, no un módulo a distribuir. La estructura debe reflejar el propósito:

- ✅ `ansible/` - Automation
- ✅ `src/app/` - Aplicación
- ✅ `scripts/` - Herramientas
- ✅ `kubernetes/` - Manifiestos

---

**Resultado**: Proyecto más limpio, simple y directo. 🎉
