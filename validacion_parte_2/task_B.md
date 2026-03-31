# Plan Operativo de Validación Downstream de Algoritmo A

**Estado**: operativo
**Objetivo**: implementar la validación final por etapas, con evidencia reproducible, archivos livianos y criterios claros de cierre.

---

# 1. Meta operativa

Al terminar este plan debes tener:

* una validación downstream completa
* 5 etapas cerradas
* comparación entre:

  * `app.R`
  * R independiente
  * Python independiente
* salidas livianas y trazables
* reportes legibles
* una base sólida para dejar la validación “lista para auditoría”

---

# 2. Enfoque operativo

Este plan se ejecuta por **fases**.

Cada fase tiene:

* **objetivo**
* **entregables**
* **tareas**
* **checklist de cierre**
* **criterio de avance**

## Regla de trabajo

No se avanza de fase hasta que la fase anterior tenga:

* outputs generados
* revisión básica hecha
* discrepancias clasificadas
* checklist marcado

---

# FASE 0 — Preparación del entorno y estructura base

## Objetivo

Dejar lista la estructura mínima del sistema de validación antes de implementar cálculos.

---

## Entregables de la fase

* estructura de carpetas creada
* lista de combos definida
* plantilla de salida canónica definida
* guía de uso inicial creada

---

## Tareas

### 0.1. Crear estructura de carpetas

Crear esta estructura:

```text id="zt2f1f"
validation/
  plan_validacion_final.md
  plan_validacion_operativo.md
  USAGE.md

  run_validation_all.R
  run_validation_all.py

  stage_01_robust_stats.R
  stage_02_homogeneity.R
  stage_03_stability.R
  stage_04_uncertainty_chain.R
  stage_05_scores.R

  stage_01_robust_stats.py
  stage_02_homogeneity.py
  stage_03_stability.py
  stage_04_uncertainty_chain.py
  stage_05_scores.py

  outputs/
    combo_excels/
```

---

### 0.2. Definir los 15 combos objetivo

Dejar una definición única y reutilizable de combos en R y Python.

## Combos

* `co`: `0-μmol/mol`, `4-μmol/mol`, `8-μmol/mol`
* `no`: `0-nmol/mol`, `81-nmol/mol`, `121-nmol/mol`
* `no2`: `0-nmol/mol`, `60-nmol/mol`, `120-nmol/mol`
* `o3`: `0-nmol/mol`, `80-nmol/mol`, `180-nmol/mol`
* `so2`: `0-nmol/mol`, `60-nmol/mol`, `100-nmol/mol`

---

### 0.3. Definir la tabla canónica de comparación

Definir una estructura estándar para todos los CSV:

## Columnas mínimas

* `combo_id`
* `pollutant`
* `level`
* `stage`
* `section`
* `participant_id`
* `metric`
* `app_value`
* `r_value`
* `python_value`
* `excel_value`
* `diff_app_r`
* `diff_app_python`
* `diff_r_python`
* `diff_app_excel`
* `status`
* `tolerance`
* `notes`

---

### 0.4. Crear `USAGE.md` inicial

Debe incluir al menos:

* propósito del sistema
* datasets usados
* cómo correr scripts
* dónde quedan outputs
* significado de `PASS`, `FAIL`, `EDGE_CASE`, `KNOWN_DISCREPANCY`

---

### 0.5. Definir convenciones de estado

Estados válidos:

* `PASS`
* `FAIL`
* `EDGE_CASE`
* `KNOWN_DISCREPANCY`

---

## Checklist de cierre — Fase 0

* [ ] Existe carpeta `validation/`
* [ ] Existe carpeta `validation/outputs/`
* [ ] Existe carpeta `validation/outputs/combo_excels/`
* [ ] Los 15 combos están definidos una sola vez y reutilizables
* [ ] La estructura de columnas canónicas está definida
* [ ] Existe `USAGE.md` inicial
* [ ] Los estados de validación están definidos

---

## Criterio de avance

Puedes pasar a Fase 1 cuando ya exista una base mínima común para no improvisar outputs después.

---

# FASE 1 — Implementación base de Etapa 1 (Robust Stats)

## Objetivo

Cerrar completamente la validación de extracción y estadísticos robustos.

---

## Entregables de la fase

* `stage_01_robust_stats.R`
* `stage_01_robust_stats.py`
* `outputs/stage_01_robust_stats.csv`
* `outputs/stage_01_robust_stats_report.md`

---

## Tareas

### 1.1. Implementar extracción reproducible desde `summary_n13.csv`

Replicar la lógica efectiva de la app para:

* filtrar por `pollutant`
* filtrar por `level`
* excluir `participant_id == "ref"`
* agrupar por participante
* calcular:

  * `result = mean(mean_value)`
  * `sd_value = mean(sd_value)`

---

### 1.2. Implementar cálculo independiente en R

Calcular en R independiente:

* serie `xi`
* mediana
* MAD
* MADe
* Q1
* Q3
* IQR
* nIQR

---

### 1.3. Implementar cálculo independiente en Python

Reimplementar exactamente lo mismo en Python.

---

### 1.4. Construir comparación tripartita

Comparar para cada combo y métrica:

* valor app
* valor R
* valor Python

---

### 1.5. Generar CSV de resultados

Crear:

* `outputs/stage_01_robust_stats.csv`

---

### 1.6. Generar reporte Markdown

Crear:

* `outputs/stage_01_robust_stats_report.md`

## El reporte debe incluir

* combos procesados
* métricas evaluadas
* conteo PASS/FAIL
* discrepancias
* observaciones

---

## Checklist de cierre — Fase 1

* [ ] La extracción de participantes replica la app
* [ ] `ref` queda excluido correctamente
* [ ] La serie `xi` coincide entre fuentes
* [ ] Mediana validada
* [ ] MAD validado
* [ ] MADe validado
* [ ] Q1 validado
* [ ] Q3 validado
* [ ] IQR validado
* [ ] nIQR validado
* [ ] Existe CSV de salida
* [ ] Existe reporte Markdown
* [ ] Discrepancias, si existen, están clasificadas

---

## Criterio de avance

No avanzar a Fase 2 hasta que la extracción y los estadísticos robustos estén estables.

---

# FASE 2 — Implementación base de Etapa 2 (Homogeneidad)

## Objetivo

Cerrar completamente la validación de homogeneidad.

---

## Entregables de la fase

* `stage_02_homogeneity.R`
* `stage_02_homogeneity.py`
* `outputs/stage_02_homogeneity.csv`
* `outputs/stage_02_homogeneity_report.md`

---

## Tareas

### 2.1. Implementar lectura y pivoteo de `homogeneity_n13.csv`

Para cada combo:

* filtrar contaminante y nivel
* pivotear réplicas a formato ancho
* validar consistencia de muestras

---

### 2.2. Implementar cálculo independiente en R

Calcular:

* `g`
* `m`
* media general
* `x_pt`
* `s²_x̄`
* `sw`
* `ss²`
* `ss`
* `MADe_hom`
* `sigma_pt`
* `u(sigma_pt)`
* criterio `c`
* criterio expandido
* evaluación

---

### 2.3. Implementar cálculo independiente en Python

Reproducir lo mismo en Python.

---

### 2.4. Construir comparación tripartita

Comparar:

* app
* R
* Python

---

### 2.5. Generar CSV de resultados

Crear:

* `outputs/stage_02_homogeneity.csv`

---

### 2.6. Generar reporte Markdown

Crear:

* `outputs/stage_02_homogeneity_report.md`

---

## Checklist de cierre — Fase 2

* [ ] El pivoteo de réplicas es correcto
* [ ] `g` validado
* [ ] `m` validado
* [ ] media general validada
* [ ] `x_pt` validado
* [ ] `s²_x̄` validado
* [ ] `sw` validado
* [ ] `ss²` validado
* [ ] `ss` validado
* [ ] `MADe_hom` validado
* [ ] `sigma_pt` validado
* [ ] `u(sigma_pt)` validado
* [ ] criterio `c` validado
* [ ] criterio expandido validado
* [ ] evaluación final validada
* [ ] Existe CSV de salida
* [ ] Existe reporte Markdown
* [ ] Discrepancias clasificadas

---

## Criterio de avance

No avanzar hasta que homogeneidad esté cerrada, porque estabilidad e incertidumbres dependen de ella.

---

# FASE 3 — Implementación base de Etapa 3 (Estabilidad)

## Objetivo

Cerrar la validación de estabilidad y dejar documentada la discrepancia conocida.

---

## Entregables de la fase

* `stage_03_stability.R`
* `stage_03_stability.py`
* `outputs/stage_03_stability.csv`
* `outputs/stage_03_stability_report.md`

---

## Tareas

### 3.1. Implementar lectura de `stability_n13.csv`

Para cada combo:

* filtrar contaminante y nivel
* agregar correctamente por muestra/réplica

---

### 3.2. Implementar cálculo independiente en R

Calcular:

* media general de estabilidad
* `d_max`
* criterio simple
* criterio expandido
* `u_stab`
* evaluación

---

### 3.3. Implementar cálculo independiente en Python

Reproducir lo mismo en Python.

---

### 3.4. Implementar tratamiento explícito de discrepancia conocida

Registrar formalmente el caso:

* `u_stab` en `app.R` se calcula incondicionalmente
* función pura puede comportarse distinto

Esto no debe quedar “escondido”; debe salir en el reporte.

---

### 3.5. Generar CSV de resultados

Crear:

* `outputs/stage_03_stability.csv`

---

### 3.6. Generar reporte Markdown

Crear:

* `outputs/stage_03_stability_report.md`

---

## Checklist de cierre — Fase 3

* [ ] La lectura de estabilidad es correcta
* [ ] media general validada
* [ ] `d_max` validado
* [ ] criterio simple validado
* [ ] criterio expandido validado
* [ ] `u_stab` validado
* [ ] evaluación final validada
* [ ] La discrepancia conocida quedó documentada
* [ ] Existe CSV de salida
* [ ] Existe reporte Markdown
* [ ] Discrepancias clasificadas

---

## Criterio de avance

No avanzar a incertidumbres hasta que `u_stab` y la lógica efectiva de la app estén cerradas.

---

# FASE 4 — Implementación base de Etapa 4 (Cadena de incertidumbre)

## Objetivo

Cerrar la validación de la propagación downstream de incertidumbres.

---

## Entregables de la fase

* `stage_04_uncertainty_chain.R`
* `stage_04_uncertainty_chain.py`
* `outputs/stage_04_uncertainty_chain.csv`
* `outputs/stage_04_uncertainty_chain_report.md`

---

## Tareas

### 4.1. Implementar integración de resultados previos

Consumir correctamente resultados de:

* Etapa 1
* Etapa 2
* Etapa 3

---

### 4.2. Implementar cálculo por método en R

Validar por separado:

1. Referencia
2. Consenso MADe
3. Consenso nIQR
4. Algoritmo A

---

### 4.3. Validar métricas por método

Para cada método validar:

* `x_pt`
* `sigma_pt`
* `u_xpt`
* `u_hom`
* `u_stab`
* `u_xpt_def`
* `U_xpt`

---

### 4.4. Implementar cálculo equivalente en Python

Reproducir toda la cadena.

---

### 4.5. Generar CSV de resultados

Crear:

* `outputs/stage_04_uncertainty_chain.csv`

---

### 4.6. Generar reporte Markdown

Crear:

* `outputs/stage_04_uncertainty_chain_report.md`

---

## Checklist de cierre — Fase 4

* [ ] Se integran correctamente resultados de etapas 1–3
* [ ] Método referencia validado
* [ ] Método consenso MADe validado
* [ ] Método consenso nIQR validado
* [ ] Método Algoritmo A validado
* [ ] `x_pt` validado
* [ ] `sigma_pt` validado
* [ ] `u_xpt` validado
* [ ] `u_hom` validado
* [ ] `u_stab` validado
* [ ] `u_xpt_def` validado
* [ ] `U_xpt` validado
* [ ] Existe CSV de salida
* [ ] Existe reporte Markdown
* [ ] Discrepancias clasificadas

---

## Criterio de avance

No avanzar a scores hasta que la cadena de incertidumbre esté totalmente estable.

---

# FASE 5 — Implementación base de Etapa 5 (Scores)

## Objetivo

Cerrar la validación de los puntajes finales de desempeño.

---

## Entregables de la fase

* `stage_05_scores.R`
* `stage_05_scores.py`
* `outputs/stage_05_scores.csv`
* `outputs/stage_05_scores_report.md`

---

## Tareas

### 5.1. Implementar cálculo de scores en R

Validar:

* `z`
* `z'`
* `zeta`
* `En`

---

### 5.2. Implementar evaluaciones cualitativas

Validar:

* `Satisfactorio`
* `Cuestionable`
* `No satisfactorio`

---

### 5.3. Implementar cálculo equivalente en Python

Reproducir exactamente los scores.

---

### 5.4. Generar CSV de resultados

Crear:

* `outputs/stage_05_scores.csv`

---

### 5.5. Generar reporte Markdown

Crear:

* `outputs/stage_05_scores_report.md`

---

## Checklist de cierre — Fase 5

* [ ] `z` validado
* [ ] `z'` validado
* [ ] `zeta` validado
* [ ] `En` validado
* [ ] Evaluaciones cualitativas coinciden exactamente
* [ ] Existe CSV de salida
* [ ] Existe reporte Markdown
* [ ] Discrepancias clasificadas

---

## Criterio de avance

La fase cierra cuando los scores y sus etiquetas estén completamente trazados.

---

# FASE 6 — Integración final y consolidación maestra

## Objetivo

Unificar todo en una salida final revisable y lista para entregar.

---

## Entregables de la fase

* `run_validation_all.R`
* `run_validation_all.py`
* `outputs/validation_summary_master.csv`
* `outputs/validation_fail_log.csv`
* Exceles livianos por combo (si se decide generarlos)
* cierre global de validación

---

## Tareas

### 6.1. Consolidar todos los CSV

Unir:

* `stage_01_robust_stats.csv`
* `stage_02_homogeneity.csv`
* `stage_03_stability.csv`
* `stage_04_uncertainty_chain.csv`
* `stage_05_scores.csv`

---

### 6.2. Generar resumen maestro

Crear:

* `outputs/validation_summary_master.csv`

## Debe incluir al menos

* combo
* etapa
* conteo PASS
* conteo FAIL
* conteo EDGE_CASE
* conteo KNOWN_DISCREPANCY

---

### 6.3. Generar fail log consolidado

Crear:

* `outputs/validation_fail_log.csv`

## Debe incluir

* combo
* etapa
* métrica
* participante si aplica
* valor app
* valor R
* valor Python
* diferencia
* notas

---

### 6.4. Generar Excel liviano por combo (opcional recomendado)

Si se usa Excel, generar:

* **1 Excel por combo**
* **1 sola hoja**
* con tabla canónica de comparación

---

### 6.5. Validar cierre global

Revisar si hay:

* `FAIL` reales
* `EDGE_CASE` esperados
* `KNOWN_DISCREPANCY` documentadas

---

## Checklist de cierre — Fase 6

* [ ] Los 5 CSV de etapa existen
* [ ] Los 5 reportes Markdown existen
* [ ] Existe `validation_summary_master.csv`
* [ ] Existe `validation_fail_log.csv`
* [ ] Las discrepancias están clasificadas
* [ ] Los casos borde están documentados
* [ ] Existe trazabilidad por combo y etapa
* [ ] La validación puede correrse de extremo a extremo

---

## Criterio de cierre global

La validación se considera operativamente cerrada cuando:

* todas las fases están ejecutadas
* existe evidencia reproducible por etapa
* existe resumen maestro
* no hay `FAIL` sin explicación

---

# 3. Checklist maestro general

Este es el checklist global que puedes usar como tablero de control.

---

# Checklist Maestro de Validación

## Preparación

* [ ] Estructura de carpetas creada
* [ ] Combos definidos
* [ ] Tabla canónica definida
* [ ] `USAGE.md` creado

## Etapa 1 — Robust Stats

* [ ] Script R implementado
* [ ] Script Python implementado
* [ ] CSV generado
* [ ] Reporte generado
* [ ] Etapa revisada

## Etapa 2 — Homogeneidad

* [ ] Script R implementado
* [ ] Script Python implementado
* [ ] CSV generado
* [ ] Reporte generado
* [ ] Etapa revisada

## Etapa 3 — Estabilidad

* [ ] Script R implementado
* [ ] Script Python implementado
* [ ] CSV generado
* [ ] Reporte generado
* [ ] Discrepancia `u_stab` documentada
* [ ] Etapa revisada

## Etapa 4 — Incertidumbres

* [ ] Script R implementado
* [ ] Script Python implementado
* [ ] CSV generado
* [ ] Reporte generado
* [ ] Etapa revisada

## Etapa 5 — Scores

* [ ] Script R implementado
* [ ] Script Python implementado
* [ ] CSV generado
* [ ] Reporte generado
* [ ] Etapa revisada

## Integración final

* [ ] Resumen maestro generado
* [ ] Fail log generado
* [ ] Excels por combo generados (si aplica)
* [ ] Validación completa ejecutable de extremo a extremo

---

# 4. Recomendación práctica de trabajo

Si quieres hacerlo sin trabarte, el orden más sano es este:

## Semana / bloque 1

* Fase 0
* Fase 1

## Semana / bloque 2

* Fase 2
* Fase 3

## Semana / bloque 3

* Fase 4
* Fase 5

## Semana / bloque 4

* Fase 6
* limpieza final
* revisión de discrepancias
* cierre

---

# 5. Criterio práctico para no sobrecargar el proyecto

Si en algún momento notas que te estás yendo a “demasiada hoja, demasiado formato, demasiado archivo”, vuelve a esta regla:

## Regla de control

**La validación principal vive en CSV + Markdown.**
**Excel solo existe como apoyo humano.**

Esa sola decisión te va a ahorrar bastante peso y caos.
