# Plan: Validación de Cálculos del Aplicativo PT

**Timestamp:** 260512_2109 (original) | 260513_0030 (O3-first + TODO-zero)
**Slug:** validar-calculos-app-etapas  
**Estado:** Fases 0–5 ejecutadas (requieren revisión) · Fases 6–8 pendientes (O3 × 3 niveles) · Fase 9 futuro (15 combos)

---

## Objetivo

Validar de forma independiente **cada etapa de cálculo** del aplicativo `app.R` mediante tres mecanismos complementarios:

1. **Scripts de R** — reproducen los cálculos fuera de Shiny, usando directamente las funciones de `ptcalc/`.
2. **Scripts de Python** — reimplementación desde cero usando NumPy/SciPy, sin depender del código R.
3. **Hojas de cálculo** — fórmulas explícitas paso a paso, auditables celda por celda.

La validación cruzada entre los tres mecanismos garantiza que los resultados del aplicativo son correctos y reproducibles.

---

## Alcance: validación primaria = O3 en 3 niveles

### Prioridad inmediata: O3 × 3 niveles

La validación primaria se ejecuta sobre **O3 en tres niveles**, ordenados por valor numérico:

| # | Contaminante | Nivel | Valor numérico | Combo ID |
|---|---|---|---|---|
| 1 | O3 | `0-nmol/mol` | 0 | `O3_0` |
| 2 | O3 | `80-nmol/mol` | 80 | `O3_80` |
| 3 | O3 | `180-nmol/mol` | 180 | `O3_180` |

**Razón:** O3 es el contaminante más relevante para el aplicativo PT. Con 3 niveles se cubren los rangos bajo, medio y alto, verificando que los cálculos son correctos a lo largo de todo el rango.

**Todas las fases pendientes (6–8) se ejecutan primero con O3 en 3 niveles.** Una vez completadas y verificadas, se extienden a los demás contaminantes (Fase 9).

### Futuro: 5 contaminantes × 3 niveles = 15 combos (Fase 9)

Los 15 combos ya fueron ejecutados en las Fases 0–5 previas, pero requieren revisión. La extensión a 15 combos en las fases nuevas (Algoritmo A detallado, Excel, informe formal) se hace solo después de que O3 × 3 niveles pase completamente.

| # | Contaminante | Niveles |
|---|---|---|
| 1 | CO | 3 niveles |
| 2 | SO2 | 3 niveles |
| 3 | NO2 | 3 niveles |
| 4 | NO | 3 niveles |
| 5 | O3 | 3 niveles (ya validado) |

---

## Etapas de cálculo a validar

El aplicativo procesa datos en **5 etapas secuenciales**. Se documenta la correspondencia con las 6 etapas de `plan_claude.md`.

### Correspondencia de etapas

| # Codex | Nombre Codex | # Claude | Nombre Claude |
|---------|-------------|---------|---------------|
| 1 | Estadísticos Robustos | 1 | Estadísticos Robustos de Dispersión |
| 2 | Homogeneidad (ANOVA) | 2 | Evaluación de Homogeneidad |
| 3 | Estabilidad | 3 | Evaluación de Estabilidad |
| 4 | Cadena de Incertidumbre | 4+5 | Algoritmo A + Valor Consenso |
| 5 | Puntajes de Desempeño | 6 | Puntajes de Desempeño |

> **Nota:** `plan_claude.md` separa Algoritmo A (etapa 4) y Valor Consenso (etapa 5) como etapas distintas. La implementación actual (Codex) los unifica en una sola etapa 04 "uncertainty chain" que cubre los 4 métodos (Referencia, Consenso MADe, Consenso nIQR, Algoritmo A). La validación detallada del Algoritmo A se cubre en la Fase 6 de este plan.

---

### Etapa 1: Estadísticos Robustos de Dispersión

**Fuente en código:** `ptcalc/R/pt_robust_stats.R` → `calculate_niqr()`, `calculate_mad_e()`  
**Scripts:** `stage_01_robust_stats.R`, `stage_01_robust_stats.py`  
**Estado:** ⚠️ Ejecutado — requiere revisión

**Datos de entrada:** Columna `sample_1` del dataset de homogeneidad filtrado por contaminante+nivel.

| Estadístico | Fórmula ISO 13528 | Referencia |
|---|---|---|
| Mediana (x_pt) | `median(sample_1)` | Sección 9.2 |
| MAD | `median(|x_i - median(x)|)` | Sección 9.4 |
| MADe (σ_pt) | `1.483 × MAD` | Sección 9.4 |
| nIQR | `0.7413 × (Q3 - Q1)` usando `type=7` | Sección 9.4 |

**Validaciones:**
- [ ] Verificar que la mediana se calcula sobre `sample_1` (no sobre todas las réplicas)
- [ ] Verificar factor 1.483 para MADe
- [ ] Verificar factor 0.7413 para nIQR
- [ ] Verificar que los cuartiles usan `type=7` (default de R)

---

### Etapa 2: Homogeneidad (ANOVA)

**Fuente en código:** `ptcalc/R/pt_homogeneity.R` → `calculate_homogeneity_stats()`  
**Código de orquestación:** `app.R` → `compute_homogeneity_metrics()` (L541–L805)  
**Scripts:** `stage_02_homogeneity.R`, `stage_02_homogeneity.py`  
**Estado:** ⚠️ Ejecutado — requiere revisión

**Datos de entrada:** Matriz g×m (4 items × 2 réplicas).

| Cálculo | Fórmula | Referencia |
|---|---|---|
| Media de cada ítem | `x̄_i = (sample_1_i + sample_2_i) / 2` | — |
| Media general | `x̄ = mean(todas las celdas)` | — |
| Varianza de medias | `s²_x̄ = var(x̄_1, ..., x̄_g)` (denominador g-1) | Sección 9.2 |
| sw (within-sample SD) | Para m=2: `sqrt(Σ(sample_1_i - sample_2_i)² / (2·g))` | Sección 9.2 |
| ss² (between-sample var) | `|s²_x̄ - sw²/m|` | Sección 9.2 |
| ss (between-sample SD) | `sqrt(ss²)` | Sección 9.2 |
| σ_pt (homogeneidad) | `median(|sample_2_i - x_pt|)` | Sección 9.2 |
| MADe | `1.483 × σ_pt` | — |
| u_σ_pt | `1.25 × MADe / sqrt(g)` | — |
| nIQR | `0.7413 × IQR(sample_1)` | — |
| c (criterio MADe) | `0.3 × MADe` | Sección 9.2.3 |
| c_exp (criterio expandido MADe) | Función F1/F2 con `sw` y `g` | Sección 9.2.4 |
| c (criterio nIQR) | `0.3 × nIQR` | Sección 9.2.3 |
| c_exp (criterio expandido nIQR) | Misma fórmula con nIQR | Sección 9.2.4 |
| Conclusión | `ss ≤ c` → CUMPLE; `ss > c` → NO CUMPLE | — |

**Validaciones:**
- [ ] Verificar tabla ANOVA (gl, suma de cuadrados, media de cuadrados)
- [ ] Verificar ss vs criterio c para ambos métodos (MADe y nIQR)
- [ ] Verificar criterio expandido `c_exp`
- [ ] Verificar que `calculate_homogeneity_criterion_expanded` usa `sw` y `g` correctamente

---

### Etapa 3: Estabilidad

**Fuente en código:** `ptcalc/R/pt_homogeneity.R` → `calculate_stability_stats()`  
**Código de orquestación:** `app.R` → `compute_stability_metrics()` (L807–L1067)  
**Scripts:** `stage_03_stability.R`, `stage_03_stability.py`  
**Estado:** ⚠️ Ejecutado — requiere revisión

| Cálculo | Fórmula | Referencia |
|---|---|---|
| Media general (estabilidad) | `x̄_stab = mean(todas las celdas de estab)` | — |
| sw_stab, ss_stab | Misma ANOVA que homogeneidad pero sobre datos de estabilidad | Sección 9.3 |
| Dmax | `|x̄_hom - x̄_stab|` | Sección 9.3 |
| c_stab (criterio MADe) | `0.3 × MADe_hom` | Sección 9.3.3 |
| c_stab (criterio nIQR) | `0.3 × nIQR_hom` | Sección 9.3.3 |
| c_stab_exp | `c_stab + 2 × sqrt(u_hom_mean² + u_stab_mean²)` | Sección 9.3.4 |
| u_hom | `ss` (SD entre muestras de homogeneidad) | — |
| u_stab | `Dmax / sqrt(3)` | — |
| Conclusión | `Dmax ≤ c_stab` → CUMPLE | — |

**Validaciones:**
- [ ] Verificar ANOVA de estabilidad independientemente
- [ ] Verificar Dmax = |media_hom - media_stab|
- [ ] Verificar criterio c_stab usando MADe de **homogeneidad**
- [ ] Verificar criterio expandido de estabilidad
- [ ] Verificar cálculo de u_hom y u_stab

> **Discrepancia conocida (Etapa 3):** `u_stab` puede diferir entre la app y el cálculo independiente. Documentada como `KNOWN_DISCREPANCY`.

---

### Etapa 4: Cadena de Incertidumbre (4 métodos)

**Fuente en código:** `app.R` → `observeEvent(input$consensus_run, ...)` (L6119–L6191), `run_algorithm_a()`  
**Scripts:** `stage_04_uncertainty_chain.R`, `stage_04_uncertainty_chain.py`  
**Estado:** ⚠️ Ejecutado — requiere revisión

**Métodos cubiertos:**

| Método | x_pt | σ_pt | u(x_pt) |
|---|---|---|---|
| 1 — Referencia | Valor de referencia CALAIRE | Valor de referencia | u de referencia |
| 2a — Consenso MADe | `median(x_i)` participantes | `1.483 × MAD` | `1.25 × σ_pt / sqrt(n)` |
| 2b — Consenso nIQR | `median(x_i)` participantes | `0.7413 × IQR(x_i)` | `1.25 × σ_pt / sqrt(n)` |
| 3 — Algoritmo A | `x*_final` (convergencia robusta) | `s*_final` | `1.25 × s* / sqrt(n)` |

**Métricas comunes a los 4 métodos:**

| Métrica | Fórmula |
|---|---|
| u_hom | `ss` (SD entre muestras de homogeneidad) |
| u_stab | `Dmax / sqrt(3)` |
| u_xpt_def | `sqrt(u_xpt² + u_hom² + u_stab²)` |
| U_xpt | `k × u_xpt_def` (k=2) |

**Validaciones:**
- [ ] Validar x_pt, σ_pt, u_xpt para Método referencia
- [ ] Validar x_pt, σ_pt, u_xpt para Método consenso MADe
- [ ] Validar x_pt, σ_pt, u_xpt para Método consenso nIQR
- [ ] Validar x_pt, σ_pt, u_xpt para Método Algoritmo A
- [ ] Validar u_hom, u_stab, u_xpt_def, U_xpt

---

### Etapa 5: Puntajes de Desempeño

**Fuente en código:** `ptcalc/R/pt_scores.R` y `app.R` → `compute_combo_scores()` (L2736–L2806)  
**Scripts:** `stage_05_scores.R`, `stage_05_scores.py`  
**Estado:** ⚠️ Ejecutado — requiere revisión

Se calculan 4 combinaciones de (x_pt, σ_pt): Referencia (1), Consenso MADe (2a), Consenso nIQR (2b), Algoritmo A (3).

| Puntaje | Fórmula | Criterio | Ref ISO |
|---|---|---|---|
| z | `(x - x_pt) / σ_pt` | \|z\|≤2: Satisfactorio; 2<\|z\|<3: Cuestionable; \|z\|≥3: No satisfactorio | 10.2 |
| z' | `(x - x_pt) / sqrt(σ_pt² + u_xpt_def²)` | Igual que z | 10.3 |
| ζ (zeta) | `(x - x_pt) / sqrt(u_i² + u_xpt_def²)` | Igual que z | 10.4 |
| En | `(x - x_pt) / sqrt(U_xi² + U_xpt²)` | \|En\|≤1: Satisfactorio; \|En\|>1: No satisfactorio | 10.5 |

Donde:
- `u_xpt_def = sqrt(u_xpt² + u_hom² + u_stab²)` — incertidumbre definicional
- `U_xi = k × u_i` — incertidumbre expandida del participante (k=2)
- `U_xpt = k × u_xpt_def` — incertidumbre expandida del valor asignado

**Validaciones:**
- [ ] Verificar u_xpt_def incluye u_hom y u_stab
- [ ] Verificar cada puntaje para cada participante × cada combinación
- [ ] Verificar clasificación de puntajes (Satisfactorio/Cuestionable/No satisfactorio)

> **Nota sobre u_i:** Los datos `pt_data_n13.csv` contienen `u_i` reportado por cada participante. Sin `u_i`, los puntajes zeta y En se marcan como NA.

---

## Algoritmo A: Detalle explícito (de `plan_claude.md`)

Aunque el Algoritmo A se valida como parte de la Etapa 4 (uncertainty chain), se documenta aquí su lógica interna como referencia.

**Fuente en código:** `ptcalc/R/pt_robust_stats.R` → `run_algorithm_a()`  
**Código de orquestación:** `app.R` → `observeEvent(input$algoA_run, ...)` (L1209–L1278)

**Datos de entrada:** Resultados medios por participante (excluido `ref`) de `summary_n4.csv`.  
Para cada combo (pollutant, n_lab, level): agregar `mean_value` por `participant_id`.

| Paso | Fórmula ISO 13528 Annex C | Referencia |
|---|---|---|
| Inicialización x* | `median(x_i)` | Paso 1 |
| Inicialización s* | `1.483 × median(\|x_i - median(x_i)\|)` | Paso 1 |
| δ (delta) | `1.5 × s*` | Paso 2 |
| Winsorización | `x*_i = clamp(x_i, x* - δ, x* + δ)` | Paso 3 |
| Actualización x* | `mean(x*_i)` | Paso 4 |
| Actualización s* | `1.134 × sd(x*_i)` donde sd usa denominador (p-1) | Paso 4 |
| Convergencia | Sin cambio en 3ra cifra significativa de x* y s* | NOTE 1 |

**Factores clave:**
- Factor de winsorización: **1.5**
- Factor de corrección de sesgo: **1.134** (relacionado con 1/√(2/π) ≈ 0.7979, corregido por 1.134 ≈ 1/0.8844)
- Factor de MADe: **1.483** (= 1/0.6745)

**Validación detallada pendiente (Fase 6):**
- [ ] Verificar valores iniciales (mediana, MADe)
- [ ] Verificar cada iteración: δ, límites, winsorización, x*, s*
- [ ] Verificar número de iteraciones hasta convergencia
- [ ] Verificar criterio de convergencia (3ra cifra significativa)

> **Advertencia:** Con n=3 participantes (dataset n4), el Algoritmo A ejecuta pero la recomendación ISO es n≥12. Documentar esta limitación.

---

## Fases de Ejecución

### Fase 0: Preparación del entorno ⚠️ Requiere revisión

| Item | Estado | Notas |
|------|--------|-------|
| Crear `validation/` y `validation/outputs/` | [ ] revisar | Existe |
| Crear `validation/outputs/combo_excels/` | [ ] revisar | Existe |
| Scripts base R stages 01-05 | [ ] revisar | Revisar cada script |
| Scripts base Python stages 01-05 | [ ] revisar | Revisar cada script |
| Definir 3 combos O3 como objetivo primario | [ ] pendiente | O3_0, O3_80, O3_180 |
| Definir columnas canónicas | [ ] revisar | Documentado en `USAGE.md` |
| Definir estados válidos | [ ] revisar | PASS / FAIL / EDGE_CASE / KNOWN_DISCREPANCY |
| Crear `USAGE.md` | [ ] revisar | Existe |

---

### Fase 1: Estadísticos Robustos — O3 × 3 niveles ⚠️ Requiere revisión

| Item | Estado | Notas |
|------|--------|-------|
| Revisar `stage_01_robust_stats.R` | [ ] | Verificar lógica, filtros, columnas |
| Revisar `stage_01_robust_stats.py` | [ ] | Verificar lógica, filtros, columnas |
| Ejecutar para O3_0 | [ ] | |
| Ejecutar para O3_80 | [ ] | |
| Ejecutar para O3_180 | [ ] | |
| Comparación tripartita app/R/Python (O3 × 3) | [ ] | |
| Generar CSV de etapa | [ ] | `stage_01_robust_stats.csv` |
| Generar reporte Markdown | [ ] | `stage_01_robust_stats_report.md` |

---

### Fase 2: Homogeneidad — O3 × 3 niveles ⚠️ Requiere revisión

| Item | Estado | Notas |
|------|--------|-------|
| Revisar `stage_02_homogeneity.R` | [ ] | Verificar ANOVA, criterios, conclusiones |
| Revisar `stage_02_homogeneity.py` | [ ] | Verificar ANOVA, criterios, conclusiones |
| Ejecutar para O3_0 | [ ] | |
| Ejecutar para O3_80 | [ ] | |
| Ejecutar para O3_180 | [ ] | |
| Comparación tripartita (O3 × 3) | [ ] | |
| Generar CSV + reporte | [ ] | |

---

### Fase 3: Estabilidad — O3 × 3 niveles ⚠️ Requiere revisión

| Item | Estado | Notas |
|------|--------|-------|
| Revisar `stage_03_stability.R` | [ ] | Verificar Dmax, criterios, u_stab |
| Revisar `stage_03_stability.py` | [ ] | Verificar Dmax, criterios, u_stab |
| Ejecutar para O3_0 | [ ] | |
| Ejecutar para O3_80 | [ ] | |
| Ejecutar para O3_180 | [ ] | |
| Comparación tripartita (O3 × 3) | [ ] | |
| Generar CSV + reporte | [ ] | |
| Documentar discrepancia conocida u_stab | [ ] | |

---

### Fase 4: Cadena de Incertidumbre — O3 × 3 niveles ⚠️ Requiere revisión

| Item | Estado | Notas |
|------|--------|-------|
| Revisar `stage_04_uncertainty_chain.R` | [ ] | Verificar 4 métodos, u_hom, u_stab |
| Revisar `stage_04_uncertainty_chain.py` | [ ] | Verificar 4 métodos, u_hom, u_stab |
| Ejecutar para O3_0 | [ ] | |
| Ejecutar para O3_80 | [ ] | |
| Ejecutar para O3_180 | [ ] | |
| Comparación tripartita (O3 × 3) | [ ] | |
| Generar CSV + reporte | [ ] | |

---

### Fase 5: Puntajes de Desempeño — O3 × 3 niveles ⚠️ Requiere revisión

| Item | Estado | Notas |
|------|--------|-------|
| Revisar `stage_05_scores.R` | [ ] | Verificar z, z', ζ, En, evaluaciones |
| Revisar `stage_05_scores.py` | [ ] | Verificar z, z', ζ, En, evaluaciones |
| Ejecutar para O3_0 | [ ] | |
| Ejecutar para O3_80 | [ ] | |
| Ejecutar para O3_180 | [ ] | |
| Comparación tripartita (O3 × 3) | [ ] | |
| Generar CSV + reporte | [ ] | |

---

### Fase 6: Validación Detallada del Algoritmo A — O3 × 3 niveles ⏳ PENDIENTE

**Origen:** `plan_claude.md` (Etapa 4: Algoritmo A). En la implementación actual, el Algoritmo A se valida a nivel de resultado final (x*_final, s*_final), pero **no se validan las iteraciones intermedias**.

**Objetivo:** Validar paso a paso cada iteración del Algoritmo A, no solo el resultado final.

**Alcance primario:** O3 en 3 niveles (O3_0, O3_80, O3_180).

**Combos objetivo:**

| # | Combo ID | Contaminante | Nivel |
|---|---|---|---|
| 1 | O3_0 | O3 | `0-nmol/mol` |
| 2 | O3_80 | O3 | `80-nmol/mol` |
| 3 | O3_180 | O3 | `180-nmol/mol` |

| Item | Estado | Notas |
|------|--------|-------|
| Extraer lógica iterativa de `app.R` y `pt_robust_stats.R` | [ ] | Documentar paso a paso |
| Implementar script R que registre cada iteración | [ ] | x*, s*, δ, límites, winsorización |
| Implementar script Python que registre cada iteración | [ ] | Misma trazabilidad |
| Verificar valores iniciales (mediana, MADe) | [ ] | Contra ISO 13528 Annex C Paso 1 |
| Verificar factor de winsorización (1.5) | [ ] | Contra ISO 13528 Annex C Paso 2-3 |
| Verificar factor de corrección de sesgo (1.134) | [ ] | Contra ISO 13528 Annex C Paso 4 |
| Verificar convergencia (3ra cifra significativa) | [ ] | Contra ISO 13528 Annex C NOTE 1 |
| Verificar número de iteraciones | [ ] | Debe ser consistente app/R/Python |
| Comparar iteraciones contra app.R | [ ] | Incluyendo valores intermedios |
| Ejecutar para O3_0 | [ ] | |
| Ejecutar para O3_80 | [ ] | |
| Ejecutar para O3_180 | [ ] | |
| Generar CSV con iteraciones detalladas | [ ] | `stage_04b_algorithm_a_iterations.csv` |
| Generar reporte Markdown de iteraciones | [ ] | |

**Nota sobre datos:** Con n=3 participantes (dataset n4), el Algoritmo A converge en muy pocas iteraciones. Considerar usar `summary_n13.csv` para validación con más participantes.

---

### Fase 7: Validación con Hojas de Cálculo — O3 × 3 niveles ⏳ PENDIENTE

**Origen:** `plan_claude.md` Fase 4-5. La implementación actual no incluye hojas de cálculo.

**Objetivo:** Construir una validación manual/semimanual en hojas de cálculo con fórmulas explícitas, auditables celda por celda.

**Alcance primario:** O3 en 3 niveles. **18 hojas** = 3 niveles × 6 sub-etapas.

#### Sub-fase 7.0: Preparación

| Item | Estado | Notas |
|------|--------|-------|
| Documentar fórmulas Excel para cada etapa | [ ] | `validation/excel/formulas_por_etapa.md` |
| Crear plantilla base .xlsx | [ ] | Encabezado, datos, cálculos, resultados, veredicto |

**Estructura de cada hoja:**

```
Fila 1-3:   ENCABEZADO — Etapa, contaminante, nivel, fecha
Fila 5:     --- DATOS DE ENTRADA ---
Fila 6-N:   Datos crudos del combo (copiados del CSV filtrado)
Fila N+2:   --- CÁLCULOS ---
Fila N+3-M: Cada celda con fórmula explícita referenciando celdas de datos
            (NO valores hardcodeados, solo =MEDIAN(), =ABS(), etc.)
Fila M+2:   --- RESULTADOS ---
Fila M+3:   Valor calculado en esta hoja
Fila M+4:   Valor del aplicativo (ingresado manualmente tras ejecutar app)
Fila M+5:   Diferencia relativa = |(hoja - app)| / |app|
Fila M+6:   VEREDICTO: PASA si coinciden en 3 cifras significativas
```

#### Sub-fase 7.1–7.5: Hojas por etapa — O3 × 3 niveles

| Etapa | # Combos O3 | Nomenclatura |
|-------|-------------|--------------|
| 1 — Robustos | 3 | `E1_robustos_o3_{0|80|180}.xlsx` |
| 2 — Homogeneidad | 3 | `E2_homog_o3_{0|80|180}.xlsx` |
| 3 — Estabilidad | 3 | `E3_estab_o3_{0|80|180}.xlsx` |
| 4 — Incertidumbre | 3 | `E4_incert_o3_{0|80|180}.xlsx` |
| 4b — Algoritmo A (iteraciones) | 3 | `E4b_algoA_o3_{0|80|180}.xlsx` |
| 5 — Puntajes | 3 | `E5_puntajes_o3_{0|80|180}.xlsx` |

| Item | Estado | Notas |
|------|--------|-------|
| Hojas Etapa 1 — Robustos (O3 × 3) | [ ] | |
| Hojas Etapa 2 — Homogeneidad (O3 × 3) | [ ] | |
| Hojas Etapa 3 — Estabilidad (O3 × 3) | [ ] | |
| Hojas Etapa 4 — Incertidumbre (O3 × 3) | [ ] | |
| Hojas Etapa 4b — Algoritmo A (O3 × 3) | [ ] | |
| Hojas Etapa 5 — Puntajes (O3 × 3) | [ ] | |
| Validar hojas contra R/Python/app.R | [ ] | |

---

### Fase 8: Informe Formal de Validación — O3 × 3 niveles ⏳ PENDIENTE

**Origen:** `plan_claude.md` estructura de informe detallado.

**Objetivo:** Generar un informe de validación autocontenido, pre-llenado con valores calculados por R y Python, donde solo resta pegar capturas de pantalla del aplicativo.

**Alcance primario:** O3 en 3 niveles.

#### Estructura del Informe

```markdown
# Informe de Validación — Aplicativo PT
## O3: Niveles 0, 80, 180 nmol/mol

### 1. Información General
- Fecha de validación
- Versión del aplicativo
- Archivos de datos usados
- Herramientas: R x.x.x, Python x.x.x, LibreOffice/Excel

### 2. Resumen Ejecutivo
- Tabla resumen PASA/FALLA por etapa × nivel de O3
- Conclusión general

### 3. Etapa 1 — Estadísticos Robustos
#### 3.1 O3 nivel 0-nmol/mol
#### 3.2 O3 nivel 80-nmol/mol
#### 3.3 O3 nivel 180-nmol/mol
- Tabla: Mediana, MAD, MADe, nIQR (R | Python | App)
- [PEGAR CAPTURA: pestaña de robustos del app para O3 nivel X]
- Veredicto: ✅ / ❌

### 4. Etapa 2 — Homogeneidad
#### 4.1 O3 nivel 0-nmol/mol
#### 4.2 O3 nivel 80-nmol/mol
#### 4.3 O3 nivel 180-nmol/mol
- Tabla: g, m, x̄, sw, ss, MADe, nIQR, c, c_exp (R | Python | App)
- Conclusión: CUMPLE/NO CUMPLE
- [PEGAR CAPTURA: conclusión de homogeneidad del app]
- [PEGAR CAPTURA: tabla ANOVA del app]
- Veredicto: ✅ / ❌

### 5. Etapa 3 — Estabilidad
#### 5.1 O3 nivel 0-nmol/mol
#### 5.2 O3 nivel 80-nmol/mol
#### 5.3 O3 nivel 180-nmol/mol
- Tabla: media_hom, media_stab, Dmax, c_stab, conclusión (R | Python | App)
- [PEGAR CAPTURA: conclusión de estabilidad del app]
- Veredicto: ✅ / ❌

### 6. Etapa 4 — Cadena de Incertidumbre
#### 6.1 O3 nivel 0-nmol/mol
#### 6.2 O3 nivel 80-nmol/mol
#### 6.3 O3 nivel 180-nmol/mol
- Tabla: x_pt, σ_pt, u_xpt, u_hom, u_stab, u_xpt_def (R | Python | App)
- Sub-sección Algoritmo A: iteraciones detalladas
- [PEGAR CAPTURA: resumen del método]
- Veredicto: ✅ / ❌

### 7. Etapa 5 — Puntajes de Desempeño
#### 7.1 O3 nivel 0-nmol/mol
#### 7.2 O3 nivel 80-nmol/mol
#### 7.3 O3 nivel 180-nmol/mol
- Tabla: z, z', ζ, En por participante (R | Python | App)
- [PEGAR CAPTURA: tabla de puntajes del app]
- [PEGAR CAPTURA: evaluación de puntajes]
- Veredicto: ✅ / ❌

### 8. Tabla de Trazabilidad
- Para cada valor: fuente (fórmula ISO, función del código, celda Excel)

### 9. Discrepancias Conocidas
- u_stab: [documentar]
- n=3 participantes para Algoritmo A: [documentar limitación]
- Cuartiles type=7 vs interpolación lineal (R vs Python): [verificar]

### 10. Conclusión
- Resumen final
- Firma / Responsable
```

| Item | Estado | Notas |
|------|--------|-------|
| Crear template del informe | [ ] | `validation/informe_validacion_o3.md` |
| Pre-llenar valores de R y Python para O3 (3 niveles) | [ ] | Extraer de CSVs canónicos |
| Espacios para capturas del app | [ ] | Marcadores `[PEGAR CAPTURA]` |
| Tabla de veredictos PASA/FALLA (O3 × 3 niveles) | [ ] | Una tabla por etapa |
| Tabla de trazabilidad | [ ] | Cada valor → fuente ISO |
| Tabla de discrepancias | [ ] | KNOWN_DISCREPANCY documentadas |
| Firma del responsable | [ ] | |

---

### Fase 9: Extensión a 5 Contaminantes + 15 Combos 🔮 FUTURO

**Precondición:** Fases 0–8 completadas y verificadas para O3 en 3 niveles.

**Objetivo:** Extender la validación a los 4 contaminantes restantes (CO, SO2, NO2, NO) y a los 15 combos completos.

| Item | Estado | Notas |
|------|--------|-------|
| Revisar scripts existentes para CO, SO2, NO2, NO | [ ] | Fases 0–5 usaban 15 combos |
| Ejecutar Algoritmo A detallado para CO, SO2, NO2, NO | [ ] | Extensión Fase 6 |
| Generar hojas de cálculo para CO, SO2, NO2, NO | [ ] | Extensión Fase 7 |
| Extender informe formal a 5 contaminantes | [ ] | Extensión Fase 8 |
| Verificar consistencia 15 combos | [ ] | Comparar con resultados previos |

> **Nota:** Las Fases 0–5 previas ejecutaron los 15 combos con scripts que requieren revisión. Esta fase extiende las Fases 6–8 (Algoritmo A detallado, Excel, informe) a los contaminantes adicionales una vez que la metodología está validada con O3.

---

## Criterios de Aceptación

| Criterio | Tolerancia |
|---|---|
| Coincidencia entre R, Python y App | 3 cifras significativas (coherente con ISO 13528 NOTE 1) |
| Coincidencia entre validación y app.R | 3 cifras significativas |
| Clasificación de puntajes (Satisfactorio/Cuestionable/No satisfactorio) | Coincidencia exacta |
| Convergencia del Algoritmo A | Misma iteración y mismos valores finales |
| Conclusiones de homogeneidad/estabilidad | Coincidencia exacta (CUMPLE/NO CUMPLE) |
| Evaluaciones de z, z', ζ, En | Coincidencia exacta de categoría |

---

## Riesgos y Consideraciones

1. **Cuartiles type=7 vs interpolación lineal:** R (`quantile` type=7) y Python (`numpy.percentile`) pueden dar cuartiles ligeramente diferentes. → Verificar en Etapa 1.
2. **Precisión floating-point:** Usar `signif(x, 10)` para comparaciones, no igualdad exacta. → Aplicado en tolerancia `1e-9` de CSVs.
3. **n=3 participantes (dataset n4):** El Algoritmo A funciona pero la recomendación ISO es n≥12. → Documentar esta limitación; usar `summary_n13.csv` para validar con más participantes.
4. **Datos de incertidumbre (u_i):** Sin `pt_data_n*.csv` apropiado, los puntajes zeta y En requerirán u_i simulado o se marcarán como NA. → Resuelto parcialmente con `pt_data_n13.csv`.
5. **Referencia CALAIRE:** No hay `referencia_ronda.csv` en `for_validation/`. Se usará el valor `ref` directamente de los datos. → Etapa 4 Método referencia usa datos disponibles.
6. **Excel y valores muy pequeños:** CO nivel 0 tiene valores del orden de 10⁻². Verificar que Excel no pierda precisión. → Pendiente Fase 7.
7. **Discrepancia conocida u_stab:** La app puede calcular `u_stab` de manera diferente al script independiente. → Documentada como `KNOWN_DISCREPANCY`.
8. **app_value NaN en Stage 05:** Varios `app_value` son `nan` en Stage 05, lo que significa que la app no fue ejecutada con esos combos o se extrajo de una fuente diferente (n13 vs n4). → Requiere investigación.

---

## Estructura de Archivos (actualizada)

```
validation/
├── README.md                              # Descripción del proceso de validación
├── TODO_validacion.md                     # Checklist operativo por fase (TODO-zero)
├── USAGE.md                               # Instrucciones de uso
├── helpers.R / helpers.py                 # Funciones compartidas
├── combos_definition.R / combos_definition.py  # Definición de combos (O3-first)
├── stage_01_robust_stats.R/.py            # Etapa 1
├── stage_02_homogeneity.R/.py             # Etapa 2
├── stage_03_stability.R/.py               # Etapa 3
├── stage_04_uncertainty_chain.R/.py        # Etapa 4
├── stage_04b_algorithm_a_iterations.R/.py # Fase 6: Algoritmo A detallado
├── stage_05_scores.R/.py                  # Etapa 5
├── run_validation_all.R / .py              # Orquestadores
├── .venv/                                 # Entorno Python
├── outputs/
│   ├── stage_01_robust_stats.csv          # ⚠️ requiere revisión
│   ├── stage_02_homogeneity.csv           # ⚠️ requiere revisión
│   ├── stage_02_homogeneity_r.csv        # ⚠️
│   ├── stage_02_homogeneity_py.csv        # ⚠️
│   ├── stage_02_homogeneity_report.md     # ⚠️
│   ├── stage_03_stability.csv             # ⚠️
│   ├── stage_03_stability_r.csv           # ⚠️
│   ├── stage_03_stability_py.csv          # ⚠️
│   ├── stage_03_stability_report.md       # ⚠️
│   ├── stage_04_uncertainty_chain.csv     # ⚠️
│   ├── stage_04_uncertainty_chain_report.md # ⚠️
│   ├── stage_05_scores.csv               # ⚠️
│   ├── stage_05_scores_r.csv             # ⚠️
│   ├── stage_05_scores_py.csv            # ⚠️
│   ├── stage_05_scores_report.md          # ⚠️
│   ├── stage_04b_algorithm_a_iterations.csv  # ⏳ (Fase 6, O3 × 3 niveles)
│   ├── combo_excels/                      # ⏳ (Fase 7, O3 × 3 niveles primero)
│   └── informe_validacion_o3.md          # ⏳ (Fase 8, O3 × 3 niveles)
└── excel/                                 # ⏳ (Fase 7)
    ├── formulas_por_etapa.md
    ├── plantilla_base.xlsx
    └── E{1-5}_o3_{0|80|180}.xlsx         # Hojas O3 × etapa × nivel
```

---

## Log de Ejecución

- [260512 21:09] Plan original creado para validar los cálculos de `app.R` por etapa.
- [260512 21:09] Ajuste: validación primaria definida sobre `O3`.
- [260512 23:59] Plan completado con aportes de `plan_claude.md`: fórmulas ISO, Algoritmo A detallado, Excel, informe formal, criterios, riesgos.
- [260513 00:30] **Reestructuración O3-first + TODO-zero:**
  - O3 × 3 niveles (0, 80, 180 nmol/mol) = validación primaria para TODAS las fases.
  - 15 combos movidos a Fase 9 (futuro), ejecutable solo después de O3 validado.
  - TODO reseteado a cero: todos los scripts requieren revisión, nada se asume correcto.
  - Fases 0–5 cambiadas de ✅ a ⚠️ (ejecutado, requiere revisión).
  - Fases 6–8 anotadas con "O3 × 3 niveles" en el título.

---

## Observaciones de diseño

- **La validación primaria (Fases 0–8) se ejecuta primero sobre O3 en 3 niveles (0, 80, 180 nmol/mol).** La extensión a 5 contaminantes y 15 combos es Fase 9 (futuro).
- La validación prioriza etapas de cálculo, no la interfaz.
- El Algoritmo A es parte central de la validación. Fase 6 profundiza en sus iteraciones.
- La incertidumbre no se desplaza a un plan paralelo: se valida donde afecte la salida del algoritmo o de la etapa.
- La hoja de cálculo se construye después de extraer las fórmulas (Fase 7 después de Fase 6).
- Si aparecen diferencias entre R y Python, se debe revisar primero redondeo, filtros, NA y orden de agrupación antes de asumir un error del algoritmo.
- El informe final (Fase 8) se pre-llena con valores calculados por R y Python; solo las capturas del aplicativo se agregan manualmente.
- Los CSVs canónicos (`app_value`, `r_value`, `python_value`, `diff_app_r`, `diff_app_python`, `diff_r_python`, `status`, `tolerance`) son el formato estándar para toda comparación tripartita.
- **Todo script requiere revisión antes de usar su output.** No se asume que un resultado previo es correcto solo porque fue generado.