## **Aplicación de To-Do List para Administrar Tareas usando Kubernetes**

### **Descripción**

Esta propuesta presenta una aplicación web completa de gestión de tareas (To-Do List) desplegada en un entorno de contenedores orquestado por Kubernetes. La aplicación permite a los usuarios crear, visualizar y administrar sus tareas de manera eficiente a través de una interfaz web moderna y una arquitectura de microservicios robusta.

El proyecto implementa una solución cloud-native que combina tecnologías modernas de desarrollo web con herramientas de orquestación de contenedores, monitoreo avanzado y observabilidad del sistema, proporcionando una experiencia completa tanto para usuarios finales como para administradores del sistema.

### **Descripción de Microservicios y Escalabilidad**

La aplicación está diseñada con una **arquitectura de microservicios** compuesta por tres componentes principales:

#### **1. Frontend (React + Vite)**
- **Tecnología**: React 18.2.0 con Vite como bundler
- **Función**: Interfaz de usuario responsive que consume la API REST del backend
- **Escalabilidad**: Deployments independientes con múltiples réplicas, balanceador de carga mediante Kubernetes Services tipo NodePort
- **Puerto**: 5173 (contenedor) → 30080 (NodePort)

#### **2. Backend (Node.js + Express)**
- **Tecnología**: Express.js con Node.js para API REST
- **Función**: Lógica de negocio, endpoints para CRUD de tareas, middleware CORS
- **Escalabilidad**: Stateless design permite escalado horizontal automático, múltiples instancias sin estado compartido
- **Puerto**: 5000 (contenedor) → 30081 (NodePort)

#### **3. Base de Datos (PostgreSQL)**
- **Tecnología**: PostgreSQL con persistencia de datos
- **Función**: Almacenamiento persistente de tareas con transacciones ACID
- **Escalabilidad**: PersistentVolumeClaim de 1Gi, preparado para clustering y replicación read-only
- **Puerto**: 5432 (interno del cluster)

#### **Estrategia de Escalabilidad:**
- **Escalado horizontal**: Cada microservicio puede escalar independientemente usando `kubectl scale`
- **Load balancing**: Kubernetes Services distribuyen tráfico automáticamente
- **Configuración multi-nodo**: Kind cluster con 1 control-plane + 2 workers para alta disponibilidad
- **Resource management**: Límites y requests de CPU/memoria configurables por servicio

### **Justificación de Herramientas Utilizadas**

#### **1. Kubernetes con Kind**
**Justificación**: Kind (Kubernetes in Docker) proporciona un entorno de desarrollo local que replica fielmente un cluster de producción. Permite:
- **Desarrollo ágil**: Iteración rápida sin costos de cloud
- **Consistencia**: Mismo comportamiento en desarrollo y producción
- **Multi-nodo**: Simulación de clusters reales con 3 nodos (1 master + 2 workers)
- **Port mapping**: Configuración de puertos específicos para acceso externo

#### **2. Prometheus + Grafana**
**Justificación**: Stack de monitoreo y observabilidad estándar de la industria que proporciona:
- **Métricas en tiempo real**: Monitoreo de CPU, memoria, red y métricas custom
- **Alerting**: Notificaciones proactivas de problemas del sistema
- **Visualización**: Dashboards interactivos para análisis de performance
- **Escalabilidad**: Integración nativa con Kubernetes para service discovery automático
- **Troubleshooting**: Capacidad de identificar cuellos de botella y optimizar recursos

#### **3. Docker + Containerización**
**Justificación**: Containerización garantiza:
- **Portabilidad**: "Runs everywhere" - desarrollo, testing, producción
- **Aislamiento**: Dependencias encapsuladas por servicio
- **Eficiencia**: Menor overhead que VMs tradicionales
- **DevOps**: Integración con CI/CD pipelines

### **Otros Datos Relevantes**

#### **Arquitectura de Red:**
- **Comunicación interna**: Service discovery automático vía DNS de Kubernetes
- **Acceso externo**: NodePort services para frontend (30080) y backend (30081)
- **Seguridad**: Network policies implícitas de Kubernetes, CORS configurado

#### **Persistencia y Datos:**
- **PostgreSQL**: Base de datos relacional con esquema SQL definido
- **PVC**: Persistent Volume Claims para garantizar durabilidad de datos
- **Backup strategy**: Volúmenes persistentes independientes del ciclo de vida de pods

#### **Monitoreo y Observabilidad:**
- **Prometheus**: Scraping de métricas de Kubernetes y aplicaciones
- **Grafana**: Dashboard en puerto 3000 para visualización de métricas
- **Port forwarding**: Acceso local para desarrollo y debugging

#### **Deployment y DevOps:**
- **Manifiestos YAML**: Declarative infrastructure as code
- **Separación de concerns**: Archivos separados por servicio (backend.yaml, frontend.yaml, db.yaml)
- **Container registry**: Imágenes almacenadas en Docker Hub (smenaq/todo-*)

#### **Configuración del Entorno:**
```bash
# Cluster setup
kind create cluster --config kind-config.yaml

# Application deployment
kubectl apply -f db.yaml
kubectl apply -f backend.yaml
kubectl apply -f frontend.yaml

# Access points
kubectl port-forward service/todo-frontend 30080:5173
kubectl port-forward service/todo-backend 5000:5000
kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80
```

Esta propuesta demuestra una implementación completa de DevOps moderno, combinando desarrollo de aplicaciones, orquestación de contenedores, y observabilidad del sistema en un entorno escalable y mantenible.