# Entregable 01 - Repositorio de Código y Scripts Iniciales

**Fase:** 1 - Fundación  
**Fecha de creación:** 2026-01-24  
**Estado:** Completado

## Objetivo

Crear snapshot del código original como línea base del proyecto. Este entregable establece el punto de partida antes de realizar modificaciones.

## Descripción

Este entregable contiene copias exactas de:
- La aplicación Shiny principal (`app_original.R`)
- Las cuatro funciones principales de cálculo:
  - `pt_homogeneity.R` - Cálculos de homogeneidad
  - `pt_robust_stats.R` - Estadísticos robustos
  - `pt_scores.R` - Cálculo de puntajes PT
  - `utils.R` - Funciones utilitarias

## Archivos Incluidos

| Archivo | Descripción | Ubicación |
|---------|-------------|-----------|
| `README.md` | Este documento | `/` |
| `app_original.R` | Copia de `pt_app/app.R` | `/` |
| `R/pt_homogeneity.R` | Funciones de homogeneidad | `R/` |
| `R/pt_robust_stats.R` | Estadísticos robustos | `R/` |
| `R/pt_scores.R` | Cálculo de puntajes | `R/` |
| `R/utils.R` | Utilidades | `R/` |
| `tests/test_01_existencia_archivos.R` | Tests de verificación | `tests/` |
| `tests/test_01_existencia_archivos.md` | Guía de uso | `tests/` |

## Verificación de Integridad

Todos los archivos han sido verificados para asegurar que son copias idénticas de los originales. El test `test_01_existencia_archivos.R` valida:

1. Existencia de archivos origen en `pt_app/`
2. Correspondencia de hash SHA256 entre original y copia
3. Validación de sintaxis R básica

## Uso de los Tests

Para ejecutar las verificaciones:

```r
# Desde la raíz del proyecto
source("deliv/01_repo_inicial/tests/test_01_existencia_archivos.R")
```

Ver el archivo `tests/test_01_existencia_archivos.md` para instrucciones detalladas.

## Próximos Pasos

Este entregable es la línea base. Los siguientes entregables utilizarán este código como referencia para:
- Documentar funciones usadas (Entregable 02)
- Implementar cálculos standalone (Entregable 03)
- Desarrollar módulo de puntajes (Entregable 04)
