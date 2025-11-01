#!/usr/bin/env fish
#
# Script para construir y subir imágenes Docker a Docker Hub
#
# Uso:
#   ./push-images.fish [version]
#   ./push-images.fish 1.0.0
#

set GREEN (set_color green)
set YELLOW (set_color yellow)
set RED (set_color red)
set BLUE (set_color blue)
set NORMAL (set_color normal)

# Configuración
set DOCKER_USER "smenaq"
set VERSION (test -n "$argv[1]"; and echo $argv[1]; or echo "latest")
set PROJECT_ROOT (dirname (dirname (status -f)))

echo "$BLUE========================================================$NORMAL"
echo "$BLUE       PUSH DOCKER IMAGES TO DOCKER HUB               $NORMAL"
echo "$BLUE========================================================$NORMAL"
echo ""
echo "$YELLOW Configuración:$NORMAL"
echo "  Docker User: $DOCKER_USER"
echo "  Version:     $VERSION"
echo ""

# Verificar Docker
if not command -q docker
    echo "$RED Error: Docker no está instalado$NORMAL"
    exit 1
end

# Verificar login en Docker Hub
echo "$YELLOW Verificando login en Docker Hub...$NORMAL"
if not docker info | grep -q "Username: $DOCKER_USER"
    echo "$RED No estás logueado en Docker Hub.$NORMAL"
    echo "Por favor ejecuta: docker login"
    exit 1
end
echo "$GREEN ✓ Login verificado$NORMAL"
echo ""

# Función para construir y subir imagen
function build_and_push
    set SERVICE $argv[1]
    set DOCKERFILE $argv[2]
    set CONTEXT $argv[3]
    
    echo "$BLUE========================================================$NORMAL"
    echo "$BLUE  Building and pushing: $SERVICE$NORMAL"
    echo "$BLUE========================================================$NORMAL"
    
    set IMAGE_NAME "$DOCKER_USER/todo-$SERVICE"
    
    echo "$YELLOW [1/3] Construyendo imagen...$NORMAL"
    docker build -t $IMAGE_NAME:$VERSION \
        -f $CONTEXT/$DOCKERFILE \
        $CONTEXT
    
    if test $status -ne 0
        echo "$RED Error al construir $SERVICE$NORMAL"
        return 1
    end
    
    echo "$GREEN ✓ Imagen construida: $IMAGE_NAME:$VERSION$NORMAL"
    
    # Tag como latest si no es latest
    if test "$VERSION" != "latest"
        echo "$YELLOW [2/3] Taggeando como latest...$NORMAL"
        docker tag $IMAGE_NAME:$VERSION $IMAGE_NAME:latest
    end
    
    echo "$YELLOW [3/3] Subiendo imagen a Docker Hub...$NORMAL"
    docker push $IMAGE_NAME:$VERSION
    
    if test $status -ne 0
        echo "$RED Error al subir $SERVICE$NORMAL"
        return 1
    end
    
    if test "$VERSION" != "latest"
        docker push $IMAGE_NAME:latest
    end
    
    echo "$GREEN ✓ $SERVICE subido exitosamente$NORMAL"
    echo ""
end

# Construir y subir cada servicio
cd $PROJECT_ROOT

echo "$BLUE Iniciando build de todos los servicios...$NORMAL"
echo ""

# Backend
build_and_push "backend" "Dockerfile" "src/app/backend"
set backend_status $status

# Frontend
build_and_push "frontend" "Dockerfile" "src/app/frontend"
set frontend_status $status

# Database
build_and_push "db" "Dockerfile" "src/app/db"
set db_status $status

# Resumen
echo ""
echo "$BLUE========================================================$NORMAL"
echo "$BLUE                     RESUMEN                          $NORMAL"
echo "$BLUE========================================================$NORMAL"
echo ""

if test $backend_status -eq 0
    echo "$GREEN ✓ Backend:  $DOCKER_USER/todo-backend:$VERSION$NORMAL"
else
    echo "$RED ✗ Backend:  FAILED$NORMAL"
end

if test $frontend_status -eq 0
    echo "$GREEN ✓ Frontend: $DOCKER_USER/todo-frontend:$VERSION$NORMAL"
else
    echo "$RED ✗ Frontend: FAILED$NORMAL"
end

if test $db_status -eq 0
    echo "$GREEN ✓ Database: $DOCKER_USER/todo-db:$VERSION$NORMAL"
else
    echo "$RED ✗ Database: FAILED$NORMAL"
end

echo ""

if test $backend_status -eq 0 -a $frontend_status -eq 0 -a $db_status -eq 0
    echo "$GREEN========================================================$NORMAL"
    echo "$GREEN         ✓ TODAS LAS IMÁGENES SUBIDAS               $NORMAL"
    echo "$GREEN========================================================$NORMAL"
    echo ""
    echo "$YELLOW Imágenes disponibles en Docker Hub:$NORMAL"
    echo "  https://hub.docker.com/u/$DOCKER_USER"
    echo ""
    echo "$YELLOW Siguiente paso:$NORMAL"
    echo "  ./scripts/deploy.fish  # Para desplegar en GCP"
    exit 0
else
    echo "$RED========================================================$NORMAL"
    echo "$RED              HUBO ERRORES EN EL BUILD                $NORMAL"
    echo "$RED========================================================$NORMAL"
    exit 1
end
