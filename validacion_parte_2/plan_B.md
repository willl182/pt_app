# Plan Final de Validación Downstream de Algoritmo A

**Fecha**: 2026-03-31
**Estado**: propuesta consolidada final

---

# 1. Objetivo

Diseñar e implementar una validación reproducible de todos los cálculos **posteriores al Algoritmo A** en la aplicación `pt_app`, asegurando concordancia entre:

* la lógica efectiva de `app.R`
* una implementación independiente en **R**
* una implementación independiente en **Python**

La validación debe ser:

* **modular por etapa**
* **liviana en archivos**
* **fácil de revisar**
* **fácil de rerun**
* y suficientemente detallada para servir como **evidencia técnica de validación**

---

# 2. Alcance

Este plan cubre todo el flujo **downstream** de Algoritmo A, es decir:

* estadísticos robustos de consenso
* homogeneidad
* estabilidad
* propagación de incertidumbres
* puntajes de desempeño:

  * `z`
  * `z'`
  * `zeta`
  * `En`
* evaluaciones cualitativas asociadas
* comparaciones entre fuentes
* trazabilidad de resultados por combinación

## Fuera de alcance

No se incluye aquí la revalidación del núcleo iterativo de Algoritmo A, porque esa parte ya tiene validadores específicos previos.
Este plan solo valida **lo que ocurre después de Algoritmo A**.

---

# 3. Evaluación consolidada de planes previos

## 3.1. Fortalezas heredadas de A1

Se conserva de A1:

* el **alto detalle técnico por etapa**
* las **fórmulas explícitas**
* la identificación de **funciones responsables**
* la trazabilidad a lógica efectiva de `app.R`
* la documentación de **casos borde**
* la validación cruzada tripartita:

  * `app.R`
  * R independiente
  * Python independiente

## 3.2. Fortalezas heredadas de A2

Se conserva de A2:

* la organización **más limpia y operativa**
* la idea de una **salida canónica tabular**
* el enfoque por **combo**
* el uso de **resúmenes PASS/FAIL**
* la orientación a auditoría y revisión

## 3.3. Debilidades corregidas en este plan

Este plan corrige explícitamente los problemas detectados en A1 y A2:

### Se corrige de A1:

* evitar archivos Excel grandes y monolíticos por tema
* evitar navegación pesada entre muchas hojas
* añadir informe y guía de uso

### Se corrige de A2:

* añadir el detalle técnico faltante por etapa
* conservar Python como tercera fuente de validación
* definir criterios de aceptación por etapa

---

# 4. Principios de diseño del plan final

Este plan se rige por los siguientes principios:

1. **Simplicidad por etapa**
   Cada etapa debe poder correrse, revisarse y aprobarse por separado.

2. **Archivos livianos**
   Se priorizan CSV, Markdown y tablas canónicas sobre Excel pesados.

3. **Triple validación cruzada**
   Se mantienen tres fuentes:

   * app
   * R independiente
   * Python independiente

4. **Trazabilidad completa**
   Todo resultado debe poder rastrearse a:

   * combo
   * etapa
   * métrica
   * participante (si aplica)

5. **Reproducibilidad**
   Todo output debe poder regenerarse automáticamente.

6. **Aprobación por etapa**
   Cada etapa tendrá su propio criterio de aceptación.

---

# 5. Dataset y combinaciones objetivo

## Datos fuente

* `data/summary_n13.csv`
* `data/homogeneity_n13.csv`
* `data/stability_n13.csv`

## Combinaciones objetivo

Se validarán 15 combinaciones, usando los niveles 1, 3 y 5 en orden creciente de concentración:

* `co`: `0-μmol/mol`, `4-μmol/mol`, `8-μmol/mol`
* `no`: `0-nmol/mol`, `81-nmol/mol`, `121-nmol/mol`
* `no2`: `0-nmol/mol`, `60-nmol/mol`, `120-nmol/mol`
* `o3`: `0-nmol/mol`, `80-nmol/mol`, `180-nmol/mol`
* `so2`: `0-nmol/mol`, `60-nmol/mol`, `100-nmol/mol`

## Casos borde a documentar

Los niveles `0-*` pueden producir:

* `sigma_pt ≈ 0`
* divisiones problemáticas
* `NA` en puntajes

Estos casos no deben tratarse como error de implementación por defecto, sino como **casos borde esperados** que deben quedar documentados.

---

# 6. Estructura final de validación

La validación se dividirá en **5 etapas**.
Cada etapa generará **tres entregables mínimos**:

1. **script ejecutable**
2. **resultado tabular liviano**
3. **informe Markdown de resultados**

## Entregables por etapa

Cada etapa debe producir:

* un **script autocontenido** con sección `## Uso`
* un **CSV liviano** de resultados
* un **informe Markdown** con:

  * resumen PASS/FAIL
  * discrepancias
  * casos borde
  * observaciones

## Excel

El uso de Excel será **mínimo y opcional para trazabilidad humana**, no como repositorio principal de la validación.

Si se genera Excel, será:

* **1 archivo por combo**
* **1 sola hoja por combo**
* con la tabla canónica de comparación

No se generarán workbooks pesados de múltiples hojas por tema, salvo que se requiera explícitamente.

---

# 7. Salida canónica de comparación

Toda validación debe consolidarse en una tabla estándar con estas columnas mínimas:

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
* `excel_value` *(opcional si se genera)*
* `diff_app_r`
* `diff_app_python`
* `diff_r_python`
* `diff_app_excel` *(si aplica)*
* `status`
* `tolerance`
* `notes`

Esta tabla será la base de:

* los CSV por etapa
* los informes Markdown
* el resumen maestro final

---

# 8. Etapas del plan final

---

# ETAPA 1 — Estadísticos robustos y extracción de datos

## Objetivo

Validar que la extracción de datos aguas abajo de Algoritmo A y los estadísticos robustos básicos estén correctamente implementados.

## Datos fuente

* `data/summary_n13.csv`

## Validaciones a realizar

### Extracción de datos

Replicar la lógica efectiva de la app para:

* filtrar por contaminante y nivel
* excluir `participant_id == "ref"`
* agrupar por participante
* calcular:

  * `mean(mean_value)`
  * `mean(sd_value)`

### Métricas a validar

* serie `xi`
* mediana
* MAD
* MADe
* Q1
* Q3
* IQR
* nIQR

## Fuentes de comparación

* `app.R`
* R independiente
* Python independiente

## Entregables

* `validation/stage_01_robust_stats.csv`
* `validation/stage_01_robust_stats_report.md`
* `validation/stage_01_robust_stats.R`
* `validation/stage_01_robust_stats.py`

## Criterio de aceptación

La etapa pasa si:

* todas las métricas coinciden dentro de tolerancia
* no hay discrepancias estructurales en la extracción de participantes

## Tolerancia sugerida

* `1e-9`

---

# ETAPA 2 — Homogeneidad

## Objetivo

Validar el cálculo de homogeneidad y sus criterios de evaluación.

## Datos fuente

* `data/homogeneity_n13.csv`

## Validaciones a realizar

### Transformación de datos

* pivoteo correcto por réplica
* consistencia de muestras y réplicas

### Métricas a validar

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
* evaluación final

## Fuentes de comparación

* `app.R`
* R independiente
* Python independiente

## Entregables

* `validation/stage_02_homogeneity.csv`
* `validation/stage_02_homogeneity_report.md`
* `validation/stage_02_homogeneity.R`
* `validation/stage_02_homogeneity.py`

## Criterio de aceptación

La etapa pasa si:

* todos los intermedios principales coinciden
* la evaluación final coincide
* no hay discrepancias fuera de tolerancia

## Tolerancia sugerida

* `1e-9`

---

# ETAPA 3 — Estabilidad

## Objetivo

Validar el cálculo de estabilidad y el tratamiento de su incertidumbre.

## Datos fuente

* `data/stability_n13.csv`
* resultados de homogeneidad

## Validaciones a realizar

* media general de estabilidad
* `d_max`
* criterio simple
* criterio expandido
* `u_stab`
* evaluación final

## Caso crítico a documentar

Debe quedar explícitamente registrada la discrepancia entre:

* la lógica efectiva de `app.R`
* la función pura en `pt_homogeneity.R`

En particular, la validación debe seguir **la lógica efectiva de la app**, aunque no coincida con la función teórica pura.

## Fuentes de comparación

* `app.R`
* R independiente
* Python independiente

## Entregables

* `validation/stage_03_stability.csv`
* `validation/stage_03_stability_report.md`
* `validation/stage_03_stability.R`
* `validation/stage_03_stability.py`

## Criterio de aceptación

La etapa pasa si:

* `d_max`, criterio y evaluación coinciden
* `u_stab` coincide con la lógica efectiva de la app
* la discrepancia queda documentada

## Tolerancia sugerida

* `1e-9`

---

# ETAPA 4 — Cadena de incertidumbre

## Objetivo

Validar la propagación completa de incertidumbres downstream.

## Datos fuente

* resultados de etapas 1–3
* `data/summary_n13.csv`

## Métodos a validar

Se validarán por separado los métodos downstream:

1. **Referencia**
2. **Consenso MADe**
3. **Consenso nIQR**
4. **Algoritmo A**

## Métricas a validar

* `x_pt`
* `sigma_pt`
* `u_xpt`
* `u_hom`
* `u_stab`
* `u_xpt_def`
* `U_xpt`

## Fuentes de comparación

* `app.R`
* R independiente
* Python independiente

## Entregables

* `validation/stage_04_uncertainty_chain.csv`
* `validation/stage_04_uncertainty_chain_report.md`
* `validation/stage_04_uncertainty_chain.R`
* `validation/stage_04_uncertainty_chain.py`

## Criterio de aceptación

La etapa pasa si:

* cada método coincide por separado
* la cadena de incertidumbre completa coincide
* no hay divergencias silenciosas por redondeo o fórmulas implícitas

## Tolerancia sugerida

* `1e-9`

---

# ETAPA 5 — Puntajes de desempeño

## Objetivo

Validar el cálculo final de los puntajes y sus evaluaciones.

## Métricas a validar

* `z`
* `z'`
* `zeta`
* `En`

## Evaluaciones cualitativas a validar

* `Satisfactorio`
* `Cuestionable`
* `No satisfactorio`

## Fuentes de comparación

* `app.R`
* R independiente
* Python independiente

## Entregables

* `validation/stage_05_scores.csv`
* `validation/stage_05_scores_report.md`
* `validation/stage_05_scores.R`
* `validation/stage_05_scores.py`

## Criterio de aceptación

La etapa pasa si:

* todos los scores coinciden dentro de tolerancia
* todas las etiquetas cualitativas coinciden exactamente

## Tolerancia sugerida

* `1e-9`
* igualdad exacta para etiquetas

---

# 9. Informes por etapa

Uno de los faltantes más importantes en A1 y A2 era la ausencia de **informes legibles**.

Por eso, cada etapa debe generar un informe Markdown automático:

## Formato sugerido

Ejemplo:

* `validation/stage_01_robust_stats_report.md`
* `validation/stage_02_homogeneity_report.md`
* etc.

## Contenido mínimo del informe

Cada informe debe incluir:

1. **Objetivo de la etapa**
2. **Datos usados**
3. **Combos procesados**
4. **Métricas evaluadas**
5. **Resumen PASS/FAIL**
6. **Discrepancias detectadas**
7. **Casos borde**
8. **Observaciones**
9. **Conclusión de etapa**

Esto permite revisar la validación **sin abrir Excel**.

---

# 10. Guía de uso obligatoria

Otro faltante importante de A1 y A2 fue la ausencia de una **guía de uso**.

Por eso, este plan exige una guía mínima a dos niveles:

---

## 10.1. Guía global del sistema de validación

Archivo requerido:

* `validation/USAGE.md`

Debe incluir:

### Requisitos

* versión de R
* paquetes necesarios
* versión de Python
* dependencias requeridas

### Cómo ejecutar

* comando para correr validación completa
* comando para correr por etapa
* comando para correr por combo

### Outputs esperados

* qué CSV se genera
* qué reportes se generan
* qué logs se generan
* qué significa PASS/FAIL

### Qué hacer si falla

* cómo localizar el combo
* cómo revisar la métrica
* cómo distinguir:

  * error real
  * redondeo
  * caso borde
  * discrepancia conocida

---

## 10.2. Sección `## Uso` al inicio de cada script

Cada script debe incluir al inicio:

* propósito
* inputs esperados
* output generado
* ejemplo de ejecución
* notas importantes

Esto hace que cualquier persona nueva pueda usar la validación sin depender de memoria oral del proyecto.

---

# 11. Archivos de salida recomendados

## Estructura recomendada

```text
validation/
  plan_validacion_final.md
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
    stage_01_robust_stats.csv
    stage_02_homogeneity.csv
    stage_03_stability.csv
    stage_04_uncertainty_chain.csv
    stage_05_scores.csv

    validation_summary_master.csv
    validation_fail_log.csv

    stage_01_robust_stats_report.md
    stage_02_homogeneity_report.md
    stage_03_stability_report.md
    stage_04_uncertainty_chain_report.md
    stage_05_scores_report.md

    combo_excels/
      A2_CO_0_umol.xlsx
      A2_CO_4_umol.xlsx
      ...
```

---

# 12. Excel: criterio final de uso

Excel no será el núcleo de la validación.
Su rol será únicamente:

* **trazabilidad humana**
* revisión puntual
* evidencia visual por combo

## Regla adoptada

Si se generan Excels, se hará:

* **1 Excel por combo**
* **1 sola hoja por combo**
* con la tabla canónica de comparación

## Contenido mínimo del Excel por combo

Columnas sugeridas:

* `stage`
* `metric`
* `participant_id`
* `app_value`
* `r_value`
* `python_value`
* `diff_app_r`
* `diff_app_python`
* `diff_r_python`
* `status`
* `notes`

Con esto se evita el problema de:

* archivos grandes
* muchas hojas
* navegación difícil

---

# 13. Reglas de comparación

## Tolerancias recomendadas

### Comparaciones numéricas

* `1e-12` para replicaciones exactas muy simples
* `1e-9` para cadenas de cálculo y agregados

### Comparaciones textuales

* igualdad exacta para:

  * `Satisfactorio`
  * `Cuestionable`
  * `No satisfactorio`

## Estado

Cada métrica debe marcarse como:

* `PASS`
* `FAIL`
* `EDGE_CASE`
* `KNOWN_DISCREPANCY`

Esto es importante porque no todo desajuste significa error de implementación.

---

# 14. Criterio de aceptación global

La validación completa se considerará satisfactoria si cumple todo lo siguiente:

1. Se resuelven correctamente las 15 combinaciones objetivo.
2. Cada una de las 5 etapas puede ejecutarse por separado.
3. Cada etapa genera:

   * script
   * CSV
   * informe
4. Existe guía de uso global.
5. Existe resumen maestro de resultados.
6. Se mantiene validación cruzada con:

   * app.R
   * R independiente
   * Python independiente
7. No existen `FAIL` no explicados.
8. Todos los casos borde y discrepancias conocidas quedan documentados.
