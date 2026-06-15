# Session State: PT Analysis Application

**Last Updated**: 2026-05-22 14:03 -05

## Session Objective

Eliminar dependencias de archivos precargados en `data/` y mover la carga de
insumos críticos a la GUI del aplicativo.

## Current State

- [x] `data/` quedó sin archivos; solo permanecen las carpetas de trabajo.
- [x] Se agregaron controles de carga en la GUI para la tabla de niveles y el
  diseño de estabilidad/homogeneidad.
- [x] `preprocesar_calaire.R` y `pipeline_calaire.R` ahora aceptan rutas
  explícitas para esos insumos.
- [x] Se eliminó el respaldo automático de equipos desde `data/processed/*_equipos.csv`.
- [x] Se documentó el significado de cada archivo en `docs/archivos-carga-gui.md`.

## Critical Technical Context

- El archivo `niveles_calaire.csv` debe cargarse por GUI porque cambia según la
  ronda.
- El archivo `diseno_estabilidad_homogeneidad.csv` también debe cargarse por GUI
  si se usa el flujo de preprocesamiento de estabilidad/homogeneidad.
- El aplicativo ya no debe asumir respaldos en `data/processed/` para equipos.
- Los ejemplos y casos de uso quedaron en `data_use_cases/`.

## Next Steps

1. Revisar si la interfaz necesita validaciones más estrictas para los CSV de
   niveles y diseño antes de ejecutar el preprocesador.
2. Decidir si conviene agregar ejemplos descargables en `docs/` o `reports/`
   para que el usuario entienda el formato esperado.
