# POC GPT53CDX: Implementacion A1 + A2 (Validacion post Algoritmo A)

**Fecha**: 2026-03-30  
**Estado**: en_progreso  
**Base**: `plan_a2.md` + `logs/plans/260330_1118_plan_a1_validacion_post_algoA.md`

## 1) Objetivo

Implementar una validacion reproducible de toda la cadena **downstream** al
Algoritmo A en `pt_app`, comparando tres fuentes por cada combinacion objetivo:

1. **APP**: resultados extraidos de la logica efectiva de `app.R`
2. **R independiente**: reimplementacion controlada en script de validacion
3. **Excel**: formulas trazables por hoja para auditoria

Adicionalmente, incluir validacion cruzada en Python (A1) para blindar los
calculos criticos y detectar divergencias ocultas.

## 2) Alcance consolidado

Se cubren los siguientes bloques para las 15 combinaciones (niveles 1, 3, 5):

- Robust stats de participantes agregados
- Homogeneidad
- Estabilidad
- Cadena de incertidumbres (`u_xpt`, `u_hom`, `u_stab`, `u_xpt_def`, `U_xpt`)
- Puntajes (`z`, `zprime`, `zeta`, `En`) y evaluaciones cualitativas
- Resumenes globales dependientes de estos puntajes

Fuera de alcance:

- Revalidar el nucleo iterativo de Algoritmo A (ya cubierto por validadores
  dedicados)

## 3) Combinaciones objetivo

Se adoptan exactamente las combinaciones aprobadas en A2:

- `co`: `0-umol/mol`, `4-umol/mol`, `8-umol/mol`
- `no`: `0-nmol/mol`, `81-nmol/mol`, `121-nmol/mol`
- `no2`: `0-nmol/mol`, `60-nmol/mol`, `120-nmol/mol`
- `o3`: `0-nmol/mol`, `80-nmol/mol`, `180-nmol/mol`
- `so2`: `0-nmol/mol`, `60-nmol/mol`, `100-nmol/mol`

## 4) Decisiones tecnicas

1. **Fuente de verdad funcional**: comportamiento real de `app.R`.
2. **u_stab**: usar `d_max/sqrt(3)` incondicional (como en `app.R`).
3. **Tolerancia Algoritmo A**: usar `tol = 1e-04` cuando aplique flujo app.
4. **Niveles 0**: `sigma_pt` cercano a 0 y puntajes NA son resultado esperado.
5. **Estilo de salida**: un CSV maestro canonico + workbooks de auditoria.

## 5) Entregables

```text
validation/
  val3/
    poc_gpt53cdx_val.R          # Script R principal (app_r_excel + merge_py)
    poc_gpt53cdx_val.py          # Script Python puro (sin deps externas)
    Val_01_Robust_Stats.xlsx     # [GENERADO]
    Val_02_Homogeneity.xlsx      # [GENERADO]
    Val_03_Stability.xlsx        # [GENERADO]
    Val_04_Uncertainties.xlsx    # [GENERADO]
    Val_05_Scores.xlsx           # [GENERADO]
    poc_gpt53cdx_master.csv      # [GENERADO] 7665 checks, 3219 PASS
    poc_gpt53cdx_py_results.csv  # [GENERADO] 7665 rows desde Python
    poc_gpt53cdx_runlog.md       # [GENERADO] resumen ejecucion
```

Columnas canonicas del master:

`combo_id, pollutant, level, section, participant_id, metric, app_value, r_value, excel_value, py_value, diff_app_r, diff_app_excel, diff_app_py, diff_r_excel, diff_r_py, status, tolerance`

## 6) Arquitectura de implementacion

### 6.1 Capa APP (extraccion fiel)

En `poc_gpt53cdx_val.R` se crean helpers que replican la logica efectiva de:

- `compute_scores_for_selection()`
- `compute_homogeneity_metrics()`
- `compute_stability_metrics()`
- `compute_scores_metrics()`

Objetivo: minimizar reinterpretaciones y asegurar que `app_value` sea trazable.

### 6.2 Capa R independiente

Reimplementacion matematica equivalente (sin reutilizar la misma cadena de
orquestacion del app), para generar `r_value`.

### 6.3 Capa Excel

Cada workbook por seccion contiene hojas de combo + `INDICE` + `RESUMEN`
(y `FORMULAS` donde convenga). Las hojas de combo exponen formulas y diffs
contra APP y R.

### 6.4 Capa Python independiente

`poc_gpt53cdx_val.py` calcula `py_value` desde cero y exporta
`poc_gpt53cdx_py_results.csv` para merge en el flujo R.

## 7) Plan por fases

### Fase 0 - Scaffolding [DONE]

- [x] Crear `validation/val3/`
- [x] Crear `poc_gpt53cdx_val.R` con constantes, 15 combos, loaders CSV
- [x] Crear `poc_gpt53cdx_val.py` (stdlib puro, sin numpy/pandas) con misma logica
- [x] Validar lectura de `data/summary_n13.csv`, `data/homogeneity_n13.csv`,
  `data/stability_n13.csv`

### Fase 1 - Seccion 01 (Robust Stats) [DONE]

- [x] Replicar agregacion por participante (excluyendo `ref`)
- [x] Calcular mediana, MAD, MADe, Q1, Q3, IQR, nIQR
- [x] Escribir `Val_01_Robust_Stats.xlsx` con 15 hojas + INDICE + RESUMEN

### Fase 2 - Seccion 02 (Homogeneity) [DONE]

- [x] Pivoteo por replica y calculo de estadisticos homogeneidad
- [x] Criterio simple y expandido
- [x] Evaluacion cualitativa y export a `Val_02_Homogeneity.xlsx`

### Fase 3 - Seccion 03 (Stability) [DONE]

- [x] Calcular `d_max`, criterios y evaluacion
- [x] Fijar `u_stab = d_max / sqrt(3)` segun comportamiento app
- [x] Exportar `Val_03_Stability.xlsx`

### Fase 4 - Seccion 04 (Uncertainties) [DONE]

- [x] Implementar 4 metodos (Referencia, MADe, nIQR, Algoritmo A)
- [x] Propagar a `u_xpt_def` y `U_xpt`
- [x] Exportar `Val_04_Uncertainties.xlsx`

### Fase 5 - Seccion 05 (Scores) [DONE]

- [x] Calcular `z`, `zprime`, `zeta`, `En` por participante y metodo
- [x] Evaluar etiquetas cualitativas
- [x] Exportar `Val_05_Scores.xlsx`

### Fase 6 - Integracion Python [DONE]

- [x] Implementar formulas puras Python (sin dependencias externas)
- [x] Generar `poc_gpt53cdx_py_results.csv` (7665 rows)
- [x] Hacer merge en R via `--mode merge_py`, recalcular diffs y estados

### Fase 7 - Consolidacion [PENDIENTE]

- [x] Generar `poc_gpt53cdx_master.csv` con estructura canonica completa
- [x] Generar `poc_gpt53cdx_runlog.md` con resumen PASS/FAIL
- [ ] **Resolver ~4446 FAIL** (muchos por diffs APP vs Python en robust_stats
  y scores; posiblemente tolerancia demasiado estricta o diferencias de
  agregacion participant-level vs raw). Se necesita diagnostico detallado.
- [ ] Clasificar niveles-0 como `NA_EXPECTED` donde corresponda
- [ ] Verificacion final de conformidad sobre 15 combinaciones y 5 secciones
- [ ] Ajuste de tolerancias si fallas son por acumulacion numerica

## 7.1) Estado actual de resultados

```
Total checks : 7665
PASS         : 3219  (42%)
FAIL         : 4446  (58%)
NA_EXPECTED  : 0

Por seccion:
  robust_stats  : 480  total, 123 PASS, 357 FAIL
  homogeneity   : 195  total,  77 PASS, 118 FAIL
  stability     :  90  total,  22 PASS,  68 FAIL
  uncertainties : 1140 total,  58 PASS, 1082 FAIL
  scores        : 5760 total, 2939 PASS, 2821 FAIL
```

Principales causas de FAIL pendientes de diagnostico:
1. Diferencias APP vs Python en mediana/MADe/Qn (algoritmos de cuantil)
2. Propagacion de diffs en incertidumbres y puntajes downstream
3. Niveles 0 con sigma_pt cercano a 0 generando NA no capturados como NA_EXPECTED

## 8) Reglas de comparacion

- `1e-12`: formulas equivalentes sin acumulacion relevante
- `1e-9`: cadenas agregadas con posible redondeo acumulado
- `1e-6`: componentes asociados a iteracion de Algoritmo A
- Igualdad exacta: evaluaciones cualitativas

Regla de estado:

- `PASS` si todas las comparaciones aplicables cumplen tolerancia
- `FAIL` si al menos una comparacion no cumple
- `NA_EXPECTED` para casos borde documentados (ej. sigma_pt ~ 0)

## 9) Criterios de aceptacion

1. Se generan los 5 workbooks sin errores.
2. Cada workbook contiene `INDICE`, 15 hojas de combo y `RESUMEN`.
3. Existe `poc_gpt53cdx_master.csv` con estructura canonica completa.
4. Coinciden variables de incertidumbre y puntajes dentro de tolerancia.
5. Coinciden evaluaciones cualitativas de forma exacta.
6. Casos borde de niveles 0 quedan documentados como esperados.
7. No hay `FAIL` no justificados en el resumen maestro.

## 10) Riesgos y mitigacion

- **Divergencia R vs app por defaults**: fijar constantes explicitamente en script.
- **Dependencia de formato Excel**: separar calculo (CSV maestro) de presentacion.
- **NA por denominadores cercanos a 0**: etiquetar como `NA_EXPECTED`.
- **Dualidad `R/` vs `ptcalc/`**: validar contra flujo efectivo que usa `app.R`.

## 11) Secuencia de ejecucion operativa

```text
1) Rscript validation/val3/poc_gpt53cdx_val.R --mode app_r_excel   # [OK]
2) python3 validation/val3/poc_gpt53cdx_val.py                      # [OK]
3) Rscript validation/val3/poc_gpt53cdx_val.R --mode merge_py       # [OK]
4) Resolver ~4446 FAIL pendientes (diagnostico + ajuste tolerancias) # [PENDIENTE]
```

## 12) Definicion de listo (DoD)

El POC se considera listo cuando:

- El flujo completo corre de punta a punta sin intervencion manual.
- Los artefactos quedan versionados y reproducibles.
- El resumen maestro muestra conformidad o justificacion explicita por excepcion.
- Se puede auditar cualquier numero desde APP hasta Excel/Python con trazabilidad.
