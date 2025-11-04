#!/usr/bin/env fish
#
# Utilidades compartidas para todos los scripts
# Este archivo debe ser sourced desde otros scripts
#

# Directorio raíz del proyecto
set -g PROJECT_ROOT (dirname (dirname (status -f)))

# Archivo de configuración
set -g CONFIG_FILE "$PROJECT_ROOT/config.env"

# Función para cargar configuración
function load_config
    if not test -f "$CONFIG_FILE"
        echo "Error: No se encontró el archivo de configuración: $CONFIG_FILE"
        exit 1
    end
    
    # Leer el archivo y exportar variables
    while read -l line
        # Ignorar comentarios y líneas vacías
        if test -z "$line"; or string match -q '#*' "$line"
            continue
        end
        
        # Parsear KEY=VALUE
        set -l parts (string split -m 1 '=' "$line")
        if test (count $parts) -eq 2
            set -gx $parts[1] $parts[2]
        end
    end < "$CONFIG_FILE"
end

# Función para obtener PROJECT_ID de gcloud o config
function get_project_id
    if test -n "$GCP_PROJECT_ID"
        echo "$GCP_PROJECT_ID"
    else
        gcloud config get-value project 2>/dev/null
    end
end

# Colores para output
set -g COLOR_GREEN (set_color green)
set -g COLOR_YELLOW (set_color yellow)
set -g COLOR_RED (set_color red)
set -g COLOR_BLUE (set_color blue)
set -g COLOR_NORMAL (set_color normal)

# Funciones de logging
function log_info
    echo "$COLOR_GREEN[INFO]$COLOR_NORMAL" $argv
end

function log_warn
    echo "$COLOR_YELLOW[WARN]$COLOR_NORMAL" $argv
end

function log_error
    echo "$COLOR_RED[ERROR]$COLOR_NORMAL" $argv
end

function log_step
    echo "$COLOR_BLUE▶$COLOR_NORMAL" $argv
end

# Función para verificar prerrequisitos comunes
function check_prerequisites
    set -l tools $argv
    
    for tool in $tools
        if not command -q $tool
            log_error "$tool no está instalado"
            return 1
        end
    end
    
    log_info "Todos los prerrequisitos cumplidos"
    return 0
end

# Función para mostrar configuración
function show_config
    echo ""
    echo "$COLOR_YELLOW═══════════════════════════════════════════════$COLOR_NORMAL"
    echo "$COLOR_YELLOW        CONFIGURACIÓN ACTUAL                   $COLOR_NORMAL"
    echo "$COLOR_YELLOW═══════════════════════════════════════════════$COLOR_NORMAL"
    echo ""
    echo "  Docker User:     $DOCKER_USER"
    echo "  GCP Zone:        $GCP_ZONE"
    echo "  GCP Region:      $GCP_REGION"
    echo "  Cluster Name:    $CLUSTER_NAME"
    echo "  Machine Type:    $MACHINE_TYPE"
    echo "  Num Nodes:       $NUM_NODES"
    echo "  Namespace:       $K8S_NAMESPACE"
    echo ""
end
