# Validacion Definitiva

Fecha de consolidacion: 2026-05-22

Esta carpeta consolida el material disponible para la validacion `validation_1`
del aplicativo PT. Incluye scripts, salidas, informes, hojas Excel, datos fuente
disponibles y contexto de ejecucion.

## Estructura

- `validation_1/`: copia completa del directorio original de validacion,
  incluyendo scripts R/Python, outputs CSV/Markdown, libros Excel, informes y
  logs internos de esa validacion.
- `validation_1/outputs/`: salidas por etapa:
  - `stage_01_robust_stats*`
  - `stage_02_homogeneity*`
  - `stage_03_stability*`
  - `stage_04_uncertainty_chain*`
  - `stage_04b_algorithm_a_iterations*`
  - `stage_05_scores*`
  - `hardcopy_calculos_validacion.md`
- `validation_1/validation/`: informes y anexos:
  - `informe_validacion_o3.md`
  - `informe_global_validacion.md`
  - `anexo_calculos.md`
- `validation_1/validation/excel/`: libros Excel de validacion por etapa.
- `validation_1/validation/excel/validacion_o3/`: snapshot y libros de
  validacion O3.
- `validation_1/validation/excel/validacion_o3/formulas/`: libros con formulas,
  inventario y resumen de validacion por formulas.
- `fuentes_usadas/for_validation/`: copia de los CSV disponibles en
  `data_use_cases/data/for_validation`.
- `fuentes_usadas/data_actual/`: copia del directorio `data/` tal como estaba en
  el workspace al consolidar esta carpeta.
- `fuentes_usadas/ptcalc/`: copia del paquete de calculo usado como referencia.
- `fuentes_usadas/app.R`: copia del aplicativo Shiny usado como referencia.
- `contexto_validacion/`: planes y registros historicos relacionados con la
  validacion.
- `contexto_validacion/session_outputs/`: salidas auxiliares y scripts
  semiautomaticos conservados desde `session_outputs/`.
- `informes_app/reports/`: informes `.docx` y plantilla de reporte disponibles
  en `reports/` al momento de la consolidacion.

## Datos Fuente Identificados

Los scripts de `validation_1` referencian principalmente:

- `../data/for_validation/summary_n4.csv`
- `../data/for_validation/homogeneity_n4.csv`
- `../data/for_validation/stability_n4.csv`
- `../data/pt_data_n13.csv`
- salidas intermedias en `validation_1/outputs/`

En el estado actual del workspace, `data/for_validation` no contenia esos CSV;
los archivos `summary_n4.csv`, `homogeneity_n4.csv`, `stability_n4.csv` y
`participants_data4.csv` estaban disponibles en
`data_use_cases/data/for_validation` y fueron copiados a
`fuentes_usadas/for_validation/`.

## Nota de Trazabilidad

El arbol de trabajo tenia cambios previos y multiples archivos de `data/`
marcados como eliminados por Git al momento de esta consolidacion. No se
revirtieron esos cambios. Esta carpeta conserva lo disponible en el workspace
actual y una copia completa de `validation_1`.
