# Plan de implementación `pcodex_gpt54`

## Resumen

Implementar la validación downstream post-Algoritmo A para `summary_n13`
usando una validación tripartita autoritativa entre:

- lógica real de `app.R`
- cálculo independiente en R
- cálculo independiente en Python

Los workbooks Excel se mantienen como artefacto de auditoría y revisión
humana, pero no como tercera fuente computacional autoritativa. El alcance
cubre las 15 combinaciones fijadas por contaminante y niveles 1, 3 y 5, e
incluye homogeneidad, estabilidad, propagación de incertidumbres, puntajes
`z`, `z'`, `zeta`, `En`, evaluaciones cualitativas y resúmenes downstream
dependientes de esos puntajes.

## Cambios de implementación

- Crear un orquestador R que replique exactamente la cadena operativa usada en
  `app.R`, incluyendo agregación por participante, extracción de referencia,
  llamada a homogeneidad, estabilidad y construcción de las cuatro
  combinaciones de puntajes.
- Fijar como comportamiento normativo del validador el que hoy ejecuta la app:
  `u_hom = hom_res$ss` y `u_stab = d_max / sqrt(3)` incondicional, aunque
  difiera de la función pura `calculate_u_stab()`.
- Crear un cálculo independiente en R, separado de la lógica de la app, que
  reimplemente fórmulas sin reutilizar el flujo de servidor; sí puede
  reutilizar funciones matemáticas puras de `R/pt_robust_stats.R`,
  `R/pt_homogeneity.R` y `R/pt_scores.R` cuando no introduzcan dependencia
  circular con la extracción desde app.
- Crear un cálculo independiente en Python que replique toda la cadena
  downstream con las mismas 15 combinaciones, mismas reglas de `NA`, mismas
  etiquetas cualitativas y mismas tolerancias numéricas.
- Estandarizar una salida canónica tabular por combinación, método y métrica
  con columnas de trazabilidad mínimas: `combo_id`, `pollutant`, `level`,
  `method`, `section`, `participant_id`, `metric`, `app_value`, `r_value`,
  `python_value`, `diff_app_r`, `diff_app_python`, `diff_r_python`, `status`,
  `tolerance`.
- Generar un resumen maestro con conteos `PASS/FAIL` por combinación y
  sección, y un listado detallado de discrepancias con contexto suficiente
  para depuración.
- Mantener la producción de workbooks Excel por combinación como salida de
  soporte, con hojas para entrada, cadena de incertidumbre, puntajes, chequeos
  globales y comparación; estas hojas consumirán la salida canónica ya
  validada en lugar de constituir una implementación paralela adicional.
- Ordenar la implementación por dependencia:
  1. extracción autoritativa desde app,
  2. comparador tabular,
  3. reimplementación R independiente,
  4. reimplementación Python independiente,
  5. workbooks y resumen maestro.

## Interfaces y entregables

- Script R de extracción autoritativa post-Algoritmo A desde la app.
- Script R de validación independiente downstream.
- Script Python de validación independiente downstream.
- CSV o tabla maestra consolidada con estado por métrica y combinación.
- 15 workbooks Excel de auditoría, uno por combinación objetivo.
- Documento `logs/plans/pcodex_gpt54.md` como plan fuente de implementación.

## Casos de prueba y aceptación

- Resolver exactamente las 15 combinaciones objetivo desde
  `data/summary_n13.csv` con selección por niveles 1, 3 y 5 en orden
  ascendente.
- Verificar coincidencia entre app, R independiente y Python independiente
  para `x_pt`, `sigma_pt`, `u_xpt`, `u_hom`, `u_stab`, `u_xpt_def`, `U_xpt`.
- Verificar coincidencia para `z`, `z'`, `zeta`, `En` por participante y para
  las etiquetas cualitativas asociadas.
- Validar que los niveles `0-*` queden cubiertos como casos borde: si
  `sigma_pt <= 0` o denominadores no válidos, los puntajes deben producir `NA`
  y evaluación `N/A`, idéntico a la app.
- Confirmar que el resumen maestro no tenga `FAIL`; cualquier discrepancia
  residual debe quedar listada con combinación, sección, métrica,
  participante, valores de las tres fuentes y diferencia observada.
- Confirmar que cada workbook generado incluya las hojas esperadas y sea
  consistente con la salida canónica ya comparada.

## Supuestos y decisiones fijadas

- `plan_a2.md` define el alcance downstream y las combinaciones objetivo; el
  plan A1 aporta el tercer verificador independiente en Python.
- La comparación tripartita computacional es `app.R vs R independiente vs
  Python independiente`; Excel queda como artefacto de evidencia, no como
  fuente de verdad adicional.
- La referencia operativa prevalece sobre la pureza teórica: si hay
  divergencia entre funciones puras y la app, se valida contra el
  comportamiento actual de la app y la diferencia se documenta.
- `summary_n13` se interpreta como `data/summary_n13.csv`, complementado por
  `data/homogeneity_n13.csv` y `data/stability_n13.csv`.
- No se revalida el núcleo iterativo del Algoritmo A en esta fase; solo se
  consume su salida para validar el flujo downstream.
