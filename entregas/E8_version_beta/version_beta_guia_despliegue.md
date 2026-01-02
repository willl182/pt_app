# Entregable 8.1: Guía de Despliegue - Versión Beta

Esta guía detalla los pasos necesarios para desplegar la versión beta del aplicativo PT, asegurando su disponibilidad tanto en entornos locales como en servidores remotos.

## 1. Despliegue Local (RStudio)

Para una ejecución óptima en estación de trabajo:
1. **Verificar Dependencias:** Ejecutar `source("entregas/E1_repositorio/verificar_dependencias.R")`.
2. **Configuración de Memoria:** Se recomienda un mínimo de 4GB de RAM para procesar archivos grandes de homogeneidad.
3. **Ejecución:** Abrir `app.R` y presionar "Run App" o ejecutar `shiny::runApp()`.

## 2. Despliegue en la Nube (shinyapps.io)

El aplicativo está optimizado para publicarse en la plataforma de Posit:
1. **Configuración de Cuenta:** Tener instalado el paquete `rsconnect`.
2. **Archivos a Incluir:** 
   - `app.R`
   - Carpeta `R/`
   - Carpeta `reports/`
   - Carpeta `data/` (datos de ejemplo obligatorios)
3. **Comando de Publicación:**
   ```r
   rsconnect::deployApp(appName = "PT-App-Beta")
   ```

## 3. Checklist de Lanzamiento Beta

- [ ] **Funcionalidad:** Todos los módulos cargan y calculan sin errores fatales.
- [ ] **Reportes:** Se ha verificado que `rmarkdown` genera el Word correctamente.
- [ ] **Datos:** Los archivos CSV de la carpeta `data/` tienen el formato decimal configurado por el usuario (punto/coma).
- [ ] **Seguridad:** Los nombres de participantes se anonimizan correctamente en las tablas de visualización.

## 4. Gestión de Errores Comunes

| Error | Causa Probable | Solución |
|-------|----------------|----------|
| `pandoc document not found` | RMarkdown no encuentra Pandoc. | Instalar RStudio o Pandoc por separado. |
| `unexpected end of input` | Paréntesis o llaves sin cerrar. | Revisar sintaxis con `lintr` o depurador de RStudio. |
| `memory limit exceeded` | Archivos de datos excesivamente grandes. | Limpiar sesiones previas con `rm(list=ls())`. |
