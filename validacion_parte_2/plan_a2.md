# Plan A2: Validación downstream de Algoritmo A con `summary_n13`

**Fecha**: 2026-03-30 10:55 -05
**Estado**: draft

## Resumen

Diseñar e implementar una validación cruzada de los cálculos posteriores al
Algoritmo A en `pt_app`, comparando tres fuentes por combinación objetivo:

- `app.R`
- código R de validación reproducible
- hoja Excel de validación

La validación usará `data/summary_n13.csv` como dataset principal, y
`data/homogeneity_n13.csv` junto con `data/stability_n13.csv` para reproducir
la cadena completa de incertidumbres aguas abajo.

## Alcance fijado

Se validará todo el flujo downstream de Algoritmo A:

- `x_pt`, `sigma_pt`, `u_xpt`
- `u_hom`, `u_stab`, `u_xpt_def`, `U_xpt`
- puntajes `z`, `z'`, `zeta`, `En`
- evaluaciones cualitativas asociadas
- resúmenes y tablas numéricas del informe global que dependan de esos puntajes

No se incluye en A2 la revalidación del núcleo iterativo de Algoritmo A, porque
esa línea ya tiene validadores específicos en `VAL_*` y `validation/`.

## Combinaciones objetivo

La regla aprobada es usar, para cada contaminante, los niveles 1, 3 y 5 en
orden creciente de concentración dentro de `summary_n13`.

Las 15 combinaciones objetivo quedan fijadas así:

- `co`: `0-μmol/mol`, `4-μmol/mol`, `8-μmol/mol`
- `no`: `0-nmol/mol`, `81-nmol/mol`, `121-nmol/mol`
- `no2`: `0-nmol/mol`, `60-nmol/mol`, `120-nmol/mol`
- `o3`: `0-nmol/mol`, `80-nmol/mol`, `180-nmol/mol`
- `so2`: `0-nmol/mol`, `60-nmol/mol`, `100-nmol/mol`

## Enfoque de implementación

### 1. Capa de extracción reproducible desde `app.R`

Crear un script R nuevo que replique exactamente la lógica real de `app.R`
para evitar diferencias por reinterpretación de fórmulas:

- agregación por participante previa a Algoritmo A
- ejecución de Algoritmo A sobre la serie agregada
- cálculo de `u_hom` desde homogeneidad
- cálculo de `u_stab` desde estabilidad
- cálculo de `u_xpt_def` y `U_xpt`
- cálculo de `z`, `z'`, `zeta`, `En` y sus evaluaciones
- armado de tablas resumen downstream

La prioridad es reutilizar funciones existentes y copiar la lógica efectiva de
`compute_homogeneity_metrics()`, `compute_stability_metrics()` y
`compute_scores_metrics()` de `app.R`.

### 2. Salida canónica en R

El script debe producir una salida tabular estable por combinación y por
sección, con columnas mínimas:

- `combo_id`
- `pollutant`
- `level`
- `section`
- `participant_id`
- `metric`
- `app_value`
- `r_value`
- `excel_value`
- `diff_app_r`
- `diff_app_excel`
- `diff_r_excel`
- `status`
- `tolerance`

También debe generar un resumen maestro con conteos `PASS/FAIL` por combo y por
sección.

### 3. Excels de validación

Se generará un archivo Excel por combinación objetivo. Convención sugerida:

- `validation/A2_CO_0_umol.xlsx`
- `validation/A2_NO2_60_nmol.xlsx`
- etc.

Cada workbook tendrá al menos estas hojas:

- `00_input`
- `01_algorithm_a_feed`
- `02_uncertainty_chain`
- `03_scores`
- `04_global_checks`
- `05_comparison`

Contenido esperado por hoja:

- `00_input`: datos fuente, parámetros, identificadores y trazabilidad
- `01_algorithm_a_feed`: serie agregada por participante que entra a
  Algoritmo A
- `02_uncertainty_chain`: `u_xpt`, `u_hom`, `u_stab`, `u_xpt_def`, `U_xpt`
- `03_scores`: z, z', zeta y En por participante
- `04_global_checks`: tablas o agregados downstream equivalentes a la app
- `05_comparison`: comparación `app.R` vs R vs Excel con diferencias y estado

### 4. Reglas de comparación

Tolerancias por defecto:

- `1e-12` para R vs Excel cuando la hoja replique exactamente la fórmula
- `1e-9` para agregados o cadenas con posible redondeo acumulado
- igualdad exacta para etiquetas de evaluación:
  `Satisfactorio`, `Cuestionable`, `No satisfactorio`

Toda diferencia fuera de tolerancia debe quedar listada con:

- combinación
- sección
- métrica
- participante si aplica
- valor de cada fuente
- magnitud de la diferencia

## Archivos a crear o actualizar

- `plan_a2.md`
- un script R nuevo para validación cruzada downstream
- un generador nuevo o extensión del flujo Excel en `validation/`
- archivos `.xlsx` por combinación objetivo
- un CSV o tabla maestra resumen de resultados

## Pruebas y aceptación

La implementación se considerará correcta si cumple todo lo siguiente:

1. Resuelve sin ambigüedad las 15 combinaciones objetivo desde
   `summary_n13.csv`.
2. Reproduce la lógica de `app.R` para la cadena completa downstream.
3. Genera 15 workbooks válidos, uno por combinación.
4. Cada workbook contiene las 6 hojas esperadas.
5. Coinciden `x_pt`, `sigma_pt`, `u_xpt`, `u_hom`, `u_stab`, `u_xpt_def` y
   `U_xpt`.
6. Coinciden `z`, `z'`, `zeta`, `En` por participante.
7. Coinciden las evaluaciones cualitativas.
8. El resumen maestro no reporta `FAIL`.

## Supuestos fijados

- `summary_13` se interpreta como `data/summary_n13.csv`.
- Para las incertidumbres downstream se usarán `data/homogeneity_n13.csv` y
  `data/stability_n13.csv`.
- Se conserva la validación previa de Algoritmo A; A2 cubre lo posterior.
- El criterio rector es reproducir la lógica efectiva de la app, no una versión
  simplificada de las fórmulas.
