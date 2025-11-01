# Guía de Contribución

¡Gracias por tu interés en contribuir a este proyecto! Esta guía te ayudará a comenzar.

## 🔧 Configuración del Entorno de Desarrollo

### 1. Requisitos Previos

Asegúrate de tener instalado:

- Python 3.11 o superior
- [uv](https://github.com/astral-sh/uv) - Gestor de paquetes
- Docker y Kind
- kubectl

### 2. Fork y Clone

```bash
# Fork el repositorio en GitHub
# Luego clona tu fork
git clone https://github.com/tu-usuario/ansible-project.git
cd ansible-project
```

### 3. Configurar el Entorno

```bash
# Instalar dependencias
./scripts/setup.fish  # o ./scripts/setup.sh

# O manualmente
uv sync
uv sync --group dev
uv run pre-commit install
```

## 📝 Proceso de Desarrollo

### 1. Crear una Rama

```bash
git checkout -b feature/mi-nueva-funcionalidad
```

### 2. Hacer Cambios

- Escribe código limpio y documentado
- Añade tests para nuevas funcionalidades
- Actualiza la documentación si es necesario

### 3. Ejecutar Tests

```bash
# Tests
uv run pytest

# Linting
uv run ruff check src/
uv run ansible-lint src/ansible_project/

# Formato
uv run ruff format src/
```

### 4. Commit

```bash
# Pre-commit hooks se ejecutarán automáticamente
git add .
git commit -m "feat: descripción de tu cambio"
```

### Convención de Commits

Usamos [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` - Nueva funcionalidad
- `fix:` - Corrección de bug
- `docs:` - Cambios en documentación
- `style:` - Cambios de formato (sin cambios de código)
- `refactor:` - Refactorización de código
- `test:` - Añadir o modificar tests
- `chore:` - Tareas de mantenimiento

### 5. Push y Pull Request

```bash
git push origin feature/mi-nueva-funcionalidad
```

Luego crea un Pull Request en GitHub con:

- Descripción clara de los cambios
- Referencias a issues relacionados
- Screenshots si aplica

## 🧪 Testing

### Ejecutar Tests

```bash
# Todos los tests
uv run pytest

# Tests específicos
uv run pytest tests/test_deploy.py

# Con coverage
uv run pytest --cov=src --cov-report=html
```

### Escribir Tests

```python
def test_mi_funcionalidad():
    """Descripción clara del test."""
    # Arrange
    input_data = prepare_data()

    # Act
    result = my_function(input_data)

    # Assert
    assert result == expected_output
```

## 📋 Estándares de Código

### Python

- Seguimos PEP 8
- Usamos type hints
- Documentamos con docstrings
- Line length: 100 caracteres

### Ansible

- YAML válido
- Nombres descriptivos de tasks
- Idempotencia en playbooks
- Documentación en roles

## 🔍 Code Review

Los PRs serán revisados considerando:

1. **Funcionalidad**: ¿Resuelve el problema?
2. **Tests**: ¿Tiene tests adecuados?
3. **Documentación**: ¿Está bien documentado?
4. **Estilo**: ¿Sigue los estándares del proyecto?
5. **Performance**: ¿Es eficiente?

## 🐛 Reportar Bugs

Usa el [issue tracker](https://github.com/unsa-cloud/ansible-project/issues) y proporciona:

- Descripción clara del problema
- Pasos para reproducir
- Comportamiento esperado vs actual
- Logs relevantes
- Entorno (OS, versión de Python, etc.)

## 💡 Proponer Funcionalidades

1. Abre un issue primero para discutir la idea
2. Espera feedback antes de implementar
3. Sigue el proceso normal de PR

## 📞 Contacto

- GitHub Issues: Para reportar bugs y proponer features
- Pull Requests: Para contribuciones de código

## ⚖️ Licencia

Al contribuir, aceptas que tus contribuciones serán licenciadas bajo la misma licencia del proyecto.
