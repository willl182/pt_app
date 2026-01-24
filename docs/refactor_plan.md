# Plan de refactorizacion de calculos PT

## Objetivo
Unificar la logica estadistica en `ptcalc/` y eliminar implementaciones duplicadas en `app.R` y `reports/report_template.Rmd`, garantizando resultados consistentes entre UI y reportes.

## Alcance
- Consolidar calculos de homogeneidad, estabilidad, estimadores robustos y puntajes.
- Reducir duplicacion entre `app.R`, `reports/report_template.Rmd` y `ptcalc/`.
- Mantener comportamiento funcional y formatos de salida actuales.

## Fase 0: Inventario y contratos
- Mapear todas las funciones duplicadas y sus firmas actuales.
- Documentar entradas/salidas esperadas (incluyendo errores y valores NA).
- Identificar parametros de reporte que dependen de calculos internos.

## Fase 1: Centralizacion en ptcalc
- Migrar formulas in-line en `app.R` a funciones de `ptcalc/`.
- Exponer utilitarios faltantes en `ptcalc/` (si hay formulas solo en app/Rmd).
- Agregar validaciones de entrada comunes (sigma_pt, longitud minima, NA/Inf).

## Fase 2: Integracion en app.R
- Reemplazar `compute_homogeneity_metrics` y `compute_stability_metrics` por wrappers a `ptcalc/`.
- Reemplazar evaluaciones in-line (z, z', zeta, En) por `ptcalc::evaluate_*`.
- Reinstalar chequeos de sigma_pt y manejo explicito de errores.

## Fase 3: Integracion en report_template.Rmd
- Eliminar funciones locales duplicadas y usar `ptcalc/`.
- Asegurar que los params pasados desde `app.R` son suficientes para el reporte.
- Revisar compatibilidad de formatos de tabla y textos.

## Fase 4: Limpieza y modularizacion
- Extraer bloques de server/UI a modulos si es viable.
- Eliminar helpers duplicados en scripts/herramientas si no son usados.

## Validacion
- Ejecutar pruebas existentes en `tests/` y `deliv/*/tests/`.
- Comparar resultados de UI vs reporte para un dataset de referencia.
- Confirmar que los reportes siguen generandose en HTML/DOCX.

## Riesgos y mitigaciones
- Diferencias numericas por cambios de tolerancia o validaciones.
  - Mitigacion: snapshots con datasets fijos y tolerancias definidas.
- Dependencia de `devtools::load_all` en produccion.
  - Mitigacion: documentar flujo y planificar cambio a `library(ptcalc)`.

## Entregables
- Codigo unificado en `ptcalc/`.
- `app.R` y `report_template.Rmd` sin duplicaciones criticas.
- Registro de pruebas y comparativos de resultados.
