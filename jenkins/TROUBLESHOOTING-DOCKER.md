# Solución al Error: "docker: not found" en Jenkins

## 🐛 Problema

Al ejecutar el pipeline de Jenkins, aparecía el error:

```
/var/jenkins_home/workspace/.../script.sh.copy: 2: docker: not found
script returned exit code 127
```

## 🔍 Causa

El contenedor de Jenkins no tenía Docker instalado. Aunque el socket de Docker (`/var/run/docker.sock`) estaba montado desde el host, faltaba el binario `docker` CLI dentro del contenedor.

## ✅ Solución Aplicada

### 1. Instalar Docker en el contenedor

```bash
docker exec -u root jenkins bash -c "rm -f /etc/apt/sources.list.d/google-cloud-sdk.list && apt-get update && apt-get install -y docker.io"
```

### 2. Agregar usuario jenkins al grupo docker

```bash
docker exec -u root jenkins usermod -aG docker jenkins
```

### 3. Dar permisos al socket de Docker

```bash
docker exec -u root jenkins chmod 666 /var/run/docker.sock
```

### 4. Reiniciar Jenkins

```bash
docker restart jenkins
```

### 5. Verificar que funciona

```bash
docker exec -u jenkins jenkins docker ps
```

### 6. Actualizar Jenkinsfile

Se modificó el `Jenkinsfile` para hacer el cleanup de Docker opcional con un try-catch:

```groovy
try {
    sh "docker image prune -f"
    echo '🗑️ Imágenes Docker limpiadas'
} catch (Exception e) {
    echo '⚠️ No se pudo limpiar imágenes Docker (no crítico)'
}
```

## 🔄 Para Instalaciones Futuras

Si instalas Jenkins desde cero, usa el script actualizado que incluye Docker automáticamente:

```bash
cd jenkins
./setup-jenkins.fish docker
```

O si ya tienes Jenkins corriendo, ejecuta estos comandos una sola vez:

```bash
# 1. Instalar Docker
docker exec -u root jenkins bash -c "apt-get update && apt-get install -y docker.io"

# 2. Configurar permisos
docker exec -u root jenkins usermod -aG docker jenkins
docker exec -u root jenkins chmod 666 /var/run/docker.sock

# 3. Reiniciar
docker restart jenkins
```

## ✅ Verificación

Después de aplicar estos cambios, el pipeline debe ejecutarse sin problemas. Puedes verificarlo:

1. Ve a Jenkins Dashboard
2. Ejecuta el job nuevamente
3. En la consola output deberías ver:
   - ✅ Pipeline completado exitosamente!
   - 🗑️ Imágenes Docker limpiadas

## 📝 Notas Importantes

1. **Este error es común cuando se instala Jenkins manualmente** en vez de usar el script de instalación proporcionado que ya incluye Docker.

2. **Los permisos del socket Docker pueden perderse** después de reiniciar el host o Jenkins. Si vuelve a aparecer el error `permission denied`, ejecuta:

   ```bash
   docker exec -u root jenkins chmod 666 /var/run/docker.sock
   ```

3. **Alternativa más segura**: En lugar de `chmod 666`, puedes usar grupos:
   ```bash
   docker exec -u root jenkins usermod -aG docker jenkins
   docker restart jenkins
   ```
