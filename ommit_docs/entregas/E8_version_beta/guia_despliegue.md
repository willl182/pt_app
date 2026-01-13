# Entregable 8.1: Guía de Despliegue - Versión Beta

**Proyecto:** Aplicativo para Evaluación de Ensayos de Aptitud (PT App)  
**Organización:** Laboratorio CALAIRE - Universidad Nacional de Colombia  
**Versión:** Beta 2.0  
**Fecha:** 2026-01-03

---

## 1. Introducción

Esta guía proporciona instrucciones detalladas para desplegar la versión beta del aplicativo PT en diferentes entornos: local (desarrollo), servidor interno (staging) y nube (producción).

---

## 2. Requisitos Previos

### 2.1. Hardware Mínimo

| Componente | Mínimo | Recomendado |
|------------|--------|-------------|
| RAM | 4 GB | 8 GB |
| CPU | 2 cores | 4 cores |
| Disco | 1 GB libre | 5 GB libre |
| Red | 10 Mbps | 100 Mbps |

### 2.2. Software Requerido

| Software | Versión Mínima | Propósito |
|----------|----------------|-----------|
| R | 4.0.0 | Runtime del aplicativo |
| Pandoc | 2.0 | Generación de informes Word |
| Git | 2.0 | Control de versiones |
| Visual Studio Code | 1.70 | IDE recomendado |

### 2.3. Verificación de Prerrequisitos

```bash
# Verificar versión de R
R --version

# Verificar Pandoc
pandoc --version

# Verificar Git
git --version

# Verificar conectividad a CRAN
Rscript -e "curl::has_internet()"
```

---

## 3. Despliegue Local (Desarrollo)

### 3.1. Paso 1: Clonar el Repositorio

```bash
git clone [URL_DEL_REPOSITORIO]
cd pt_app
```

### 3.2. Paso 2: Instalar Dependencias

```bash
Rscript entregas/E1_repositorio/verificar_dependencias.R
```

Si hay paquetes faltantes:

```r
install.packages(c(
  "shiny", "tidyverse", "vroom", "DT", "rhandsontable",
  "shinythemes", "outliers", "patchwork", "bsplus",
  "plotly", "rmarkdown", "knitr", "kableExtra", "stringr"
))
```

### 3.3. Paso 3: Verificar Datos de Ejemplo

```bash
ls -la data/
# Debe contener:
# - homogeneity.csv
# - stability.csv
# - summary_n4.csv, summary_n7.csv, etc.
```

### 3.4. Paso 4: Ejecutar la Aplicación

```bash
# Opción A: Desde terminal
Rscript -e "shiny::runApp('app.R', port = 3838)"

# Opción B: Desde R interactivo
R
> library(shiny)
> runApp("app.R")
```

### 3.5. Paso 5: Acceder a la Aplicación

Abrir navegador en: `http://localhost:3838`

---

## 4. Despliegue en shinyapps.io (Producción)

### 4.1. Crear Cuenta en shinyapps.io

1. Ir a https://www.shinyapps.io/
2. Registrarse con cuenta de Google o GitHub
3. Obtener token de autenticación

### 4.2. Configurar rsconnect

```r
install.packages("rsconnect")

# Configurar credenciales (reemplazar con sus valores)
rsconnect::setAccountInfo(
  name = "your_account_name",
  token = "your_token",
  secret = "your_secret"
)
```

### 4.3. Preparar Archivos para Despliegue

Estructura requerida:
```
pt_app/
├── app.R                 # ✓ Obligatorio
├── R/
│   └── utils.R           # ✓ Si se usa
├── reports/
│   └── report_template.Rmd  # ✓ Obligatorio
├── data/                 # ✓ Datos de ejemplo
│   ├── homogeneity.csv
│   ├── stability.csv
│   └── summary_*.csv
└── www/                  # Opcional (CSS, imágenes)
```

### 4.4. Ejecutar el Despliegue

```r
rsconnect::deployApp(
  appDir = ".",
  appName = "PT-App-Beta",
  appTitle = "Aplicativo Ensayos de Aptitud",
  account = "your_account_name",
  forceUpdate = TRUE
)
```

### 4.5. Verificar Despliegue

La aplicación estará disponible en:
`https://your_account_name.shinyapps.io/PT-App-Beta/`

---

## 5. Despliegue en Servidor Interno (Shiny Server)

### 5.1. Instalar Shiny Server (Ubuntu/Debian)

```bash
# Instalar R
sudo apt-get update
sudo apt-get install r-base

# Descargar Shiny Server
wget https://download3.rstudio.org/ubuntu-18.04/x86_64/shiny-server-1.5.20.1002-amd64.deb
sudo dpkg -i shiny-server-1.5.20.1002-amd64.deb
```

### 5.2. Instalar Paquetes de R

```bash
sudo R -e "install.packages(c('shiny', 'rmarkdown'))"
sudo R -e "install.packages(c('tidyverse', 'vroom', 'DT', 'rhandsontable'))"
sudo R -e "install.packages(c('shinythemes', 'outliers', 'patchwork', 'bsplus', 'plotly'))"
sudo R -e "install.packages(c('knitr', 'kableExtra', 'stringr'))"
```

### 5.3. Copiar Aplicación

```bash
sudo cp -r pt_app /srv/shiny-server/pt_app
sudo chown -R shiny:shiny /srv/shiny-server/pt_app
```

### 5.4. Configurar Shiny Server

Editar `/etc/shiny-server/shiny-server.conf`:

```
server {
  listen 3838;
  
  location /pt_app {
    app_dir /srv/shiny-server/pt_app;
    log_dir /var/log/shiny-server;
  }
}
```

### 5.5. Reiniciar Servicio

```bash
sudo systemctl restart shiny-server
sudo systemctl status shiny-server
```

### 5.6. Acceder a la Aplicación

`http://[IP_DEL_SERVIDOR]:3838/pt_app/`

---

## 6. Checklist de Verificación Pre-Lanzamiento

### 6.1. Funcionalidad

| Verificación | Estado | Notas |
|--------------|--------|-------|
| [ ] Carga de archivo homogeneidad | | |
| [ ] Carga de archivo estabilidad | | |
| [ ] Carga de archivos resumen (múltiples) | | |
| [ ] Cálculo de homogeneidad | | |
| [ ] Cálculo de estabilidad | | |
| [ ] Algoritmo A converge | | |
| [ ] Cálculo de puntajes z, z', zeta, En | | |
| [ ] Generación de informe Word | | |
| [ ] Heatmap se renderiza | | |
| [ ] Tablas DT funcionan | | |

### 6.2. Datos

| Verificación | Estado | Notas |
|--------------|--------|-------|
| [ ] Archivos CSV tienen formato correcto | | |
| [ ] Columnas obligatorias presentes | | |
| [ ] Separador decimal es punto (.) | | |
| [ ] Encoding es UTF-8 | | |

### 6.3. Rendimiento

| Verificación | Estado | Notas |
|--------------|--------|-------|
| [ ] Tiempo de carga inicial < 10s | | |
| [ ] Cálculos completan en < 5s | | |
| [ ] Informe genera en < 30s | | |
| [ ] Memoria no excede 2GB | | |

### 6.4. Seguridad

| Verificación | Estado | Notas |
|--------------|--------|-------|
| [ ] Nombres de participantes anonimizados | | |
| [ ] Sin credenciales hardcoded | | |
| [ ] HTTPS configurado (producción) | | |

---

## 7. Gestión de Errores Comunes

### 7.1. Errores de Instalación

| Error | Causa | Solución |
|-------|-------|----------|
| `package 'X' is not available` | CRAN repository no configurado | `options(repos = c(CRAN = "https://cran.r-project.org"))` |
| `ERROR: compilation failed` | Faltan herramientas de compilación | Ubuntu: `sudo apt-get install build-essential` |
| `cannot open shared object file` | Librería del sistema faltante | Instalar dependencia específica (ver log) |

### 7.2. Errores de Ejecución

| Error | Causa | Solución |
|-------|-------|----------|
| `pandoc document conversion failed` | Pandoc no encontrado | Instalar Pandoc o verificar PATH |
| `Error in file(file, "rt")` | Archivo no encontrado | Verificar rutas relativas |
| `cannot allocate vector of size X` | Memoria insuficiente | Aumentar RAM o reducir datos |
| `unexpected end of input` | Error de sintaxis en R | Verificar paréntesis/llaves |

### 7.3. Errores de Despliegue

| Error | Causa | Solución |
|-------|-------|----------|
| `Unable to deploy application` | Token inválido | Regenerar token en shinyapps.io |
| `Application failed to start` | Paquete no instalado en servidor | Agregar al código o instalar |
| `Timeout` | App tarda mucho en iniciar | Optimizar código de inicio |

---

## 8. Monitoreo Post-Despliegue

### 8.1. Logs en shinyapps.io

```r
# Ver logs de la aplicación
rsconnect::showLogs(appName = "PT-App-Beta")
```

### 8.2. Logs en Shiny Server

```bash
# Ver logs en tiempo real
sudo tail -f /var/log/shiny-server/pt_app-*.log

# Ver últimos 100 líneas
sudo tail -100 /var/log/shiny-server/pt_app-*.log
```

### 8.3. Métricas a Monitorear

| Métrica | Umbral Alerta | Acción |
|---------|---------------|--------|
| Uso de CPU | > 80% | Optimizar código o escalar |
| Uso de RAM | > 90% | Aumentar memoria o limpiar sesiones |
| Tiempo de respuesta | > 10s | Revisar queries o cálculos |
| Errores 500 | > 1/hora | Revisar logs inmediatamente |

---

## 9. Rollback

Si el despliegue falla o la nueva versión tiene problemas:

### 9.1. En shinyapps.io

```r
# Desplegar versión anterior
rsconnect::deployApp(
  appDir = "path/to/previous/version",
  appName = "PT-App-Beta",
  forceUpdate = TRUE
)
```

### 9.2. En Shiny Server

```bash
# Restaurar desde backup
sudo cp -r /backup/pt_app_v1 /srv/shiny-server/pt_app
sudo systemctl restart shiny-server
```

---

**Siguiente documento:** E8.2 - Documentación Final Compilada
