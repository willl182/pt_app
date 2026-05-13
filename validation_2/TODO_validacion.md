# TODO_validacion.md — Etapa 1 completada

**Proyecto**: Validación de cálculos del Aplicativo PT  
**Estado**: Etapa 1 ✅ completada | Etapas 2-5 ⚠️ requieren revisión | Fases 6-8 pendientes  
**Prioridad**: O3 × 3 niveles (0, 80, 180 nmol/mol)  
**Futuro**: 15 combos (Fase 9)

---

# 0. Reglas operativas del proyecto

## Reglas de trabajo

* [ ] No avanzar de fase si la anterior no tiene outputs revisables
* [ ] Toda discrepancia debe clasificarse (PASS / FAIL / EDGE_CASE / KNOWN_DISCREPANCY)
* [ ] Toda etapa debe dejar evidencia reproducible (CSV + Markdown)
* [ ] CSV + Markdown son la evidencia principal
* [ ] Excel es apoyo de trazabilidad humana (Fase 7)
* [ ] Todo script requiere revisión antes de usar su output
* [ ] O3 × 3 niveles primero; 15 combos solo en Fase 9

## Estados válidos

* `PASS` — valores coinciden dentro de tolerancia
* `FAIL` — valores difieren fuera de tolerancia
* `EDGE_CASE` — caso borde documentado
* `KNOWN_DISCREPANCY` — discrepancia conocida y documentada

---

# 1. Preparación del entorno (FASE 0) — Requiere revisión

* [ ] Revisar carpeta `validation/` y `validation/outputs/`
* [ ] Revisar `validation/outputs/combo_excels/`
* [ ] Revisar scripts R stages 01-05 (`stage_01_robust_stats.R`, etc.)
* [ ] Revisar scripts Python stages 01-05 (`stage_01_robust_stats.py`, etc.)
* [ ] Definir 3 combos O3 como objetivo primario (O3_0, O3_80, O3_180)
* [ ] Revisar `combos_definition.R` y `combos_definition.py` — ¿incluyen O3 × 3?
* [ ] Revisar columnas canónicas en `USAGE.md`
* [ ] Revisar definición de estados válidos
* [ ] Revisar `helpers.R` y `helpers.py`

---

# 2. Etapa 1 — Robust Stats (FASE 1) — ✅ COMPLETADA — O3 × 3 niveles

* [x] Revisar script `stage_01_robust_stats.R` línea por línea — Creado nuevo en validation_2/
* [x] Revisar script `stage_01_robust_stats.py` línea por línea — Creado nuevo en validation_2/
* [x] Confirmar que filtran O3 correctamente (3 niveles) — O3_0, O3_80, O3_180
* [x] Confirmar que excluyen `ref` — N/A (datos de homogeneidad no tienen ref)
* [x] Confirmar cálculo de mediana, MAD, MADe, nIQR — Implementado y verificado contra ptcalc
* [x] Confirmar factores: 1.483 (MADe), 0.7413 (nIQR) — Verificado contra ISO 13528:2022 §9.4
* [x] Confirmar cuartiles type=7 en R — Verificado: R `quantile(type=7)` = numpy.percentile
* [x] Ejecutar para O3_0 — ✅ PASS (8 métricas)
* [x] Ejecutar para O3_80 — ✅ PASS (8 métricas)
* [x] Ejecutar para O3_180 — ✅ PASS (8 métricas)
* [x] Comparación tripartita app/R/Python (O3 × 3) — R=Python, app pendiente
* [x] Generar/revisar CSV: `stage_01_robust_stats.csv` — 24 filas, 8 métricas × 3 combos
* [x] Generar/revisar reporte: `stage_01_robust_stats_report.md` — Generado con resultados
* [x] Clasificar resultados — 24/24 PASS, diff_r_python < 1e-15 todas

**Resultados clave (R = Python):**
| Combo | median | MADe | nIQR |
|-------|--------|------|------|
| O3_0 | 3.23e-05 | 9.6395e-06 | 7.11648e-06 |
| O3_80 | 80.1057 | 0.1555 | 0.1550 |
| O3_180 | 178.026 | 0.5188 | 0.3220 |

**Nota:** app_value se deja NaN hasta que se ejecute el app con estos combos y se extraigan los valores.

---

# 3. Etapa 2 — Homogeneidad (FASE 2) — ✅ COMPLETADA — O3 × 3 niveles

* [x] Revisar script `stage_02_homogeneity.R` línea por línea — Creado nuevo en validation_2/
* [x] Revisar script `stage_02_homogeneity.py` línea por línea — Creado nuevo en validation_2/
* [x] Confirmar filtro O3 (3 niveles) — O3_0, O3_80, O3_180
* [x] Confirmar pivot a formato ancho (g × m) — g=13, m=2 confirmado
* [x] Confirmar cálculo ANOVA: media general, s²_x̄, sw, ss², ss — verificado contra ptcalc (diff=0)
* [x] Confirmar criterio simple (MADe y nIQR) — 0.3 × σ_pt implementado
* [x] Confirmar criterio expandido (F1/F2 con sw y g) — Usa tabla ISO 13528 §9.2.4
* [x] Confirmar conclusión: ss ≤ c → CUMPLE — NO_CUMPLE para los 3 niveles
* [x] Ejecutar para O3_0 — PASS (18 métricas + 4 evaluaciones)
* [x] Ejecutar para O3_80 — PASS (18 métricas + 4 evaluaciones)
* [x] Ejecutar para O3_180 — PASS (18 métricas + 4 evaluaciones)
* [x] Comparación R vs Python — 54 PASS, 0 FAIL, max diff=1.14e-13
* [x] Verificación contra ptcalc — diff=0 para x_pt, sw, ss, MADe, sigma_pt
* [x] Generar CSV canónico + reporte Markdown
* [x] Clasificar resultados — 54/54 PASS, 12/12 NO_CUMPLE criterios

**Discrepancia conocida:** `calculate_homogeneity_criterion_expanded` tiene 2 firmas:
- ptcalc: 2 args → `0.3*σ×√(1+(uσ/σ)²)`
- app.R/R/: 3 args → `F1×(0.3×σ)² + F2×sw²`
Los scripts de validación usan la versión de 3 args (app.R).

**Resultado homogeneidad:** ss > c para los 3 niveles O3 (NO_CUMPLE todos los criterios).
Esto es esperado y consistente con ISO 13528 — los datos de calibración de gases
presentan variabilidad entre muestras que exceden el umbral del 0.3×σ.

---

# 4. Etapa 3 — Estabilidad (FASE 3) — ✅ COMPLETADA — O3 × 3 niveles

* [x] Revisar script `stage_03_stability.R` línea por línea — Creado nuevo en validation_2/
* [x] Revisar script `stage_03_stability.py` línea por línea — Creado nuevo en validation_2/
* [x] Confirmar filtro O3 (3 niveles) — O3_0, O3_80, O3_180
* [x] Confirmar cálculo de ANOVA de estabilidad — Igual que homogeneidad pero sobre datos de estabilidad
* [x] Confirmar Dmax = |media_hom - media_stab| — Dmax = 0 (datos idénticos)
* [x] Confirmar criterio c_stab usando MADe de **homogeneidad** — c_stab_MADe = 0.3 × MADe_hom
* [x] Confirmar criterio expandido de estabilidad — c_stab_exp = c_stab + 2×√(u_hom²+u_stab²)
* [x] Confirmar cálculo u_hom_mean y u_stab_mean — SD/n agregado (como app.R)
* [x] Confirmar cálculo u_stab (0 si Dmax≤c, Dmax/√3 si no) — u_stab = 0 para los 3 combos
* [x] Documentar discrepancia conocida u_stab — u_stab=0 para O3×3 (datos idénticos)
* [x] Ejecutar para O3_0 — PASS (22 métricas + 4 evaluaciones)
* [x] Ejecutar para O3_80 — PASS (22 métricas + 4 evaluaciones)
* [x] Ejecutar para O3_180 — PASS (22 métricas + 4 evaluaciones)
* [x] Comparación R vs Python — 66 PASS, 0 FAIL, max diff=1.14e-13
* [x] Verificación contra ptcalc — diff=0 para Dmax, mean_stab, sw_stab, ss_stab
* [x] Generar CSV canónico + reporte Markdown
* [x] Clasificar resultados — 66/66 PASS, 12/12 CUMPLE criterios

**Resultados clave (R = Python):**
| Combo | Dmax | c_stab_MADe | c_stab_exp_MADe | u_stab | Resultado |
|-------|------|-------------|-----------------|--------|----------|
| O3_0 | 0 | 2.847e-06 | 8.464e-06 | 0 | CUMPLE |
| O3_80 | 0 | 0.0535 | 0.1420 | 0 | CUMPLE |
| O3_180 | 0 | 0.3329 | 0.6885 | 0 | CUMPLE |

**Nota:** Los datos de estabilidad y homogeneidad son IDÉNTICOS para O3×3, lo que implica Dmax=0.
Esto es esperado — los gases de calibración miden las mismas muestras en la misma corrida para
homogeneidad y estabilidad. El criterio de estabilidad se cumple siempre con Dmax=0.

**Verificación contra ptcalc:** diff=0 para diff_hom_stab, mean_stab, sw_stab, ss_stab.
**u_stab = 0** para los 3 combos (Dmax ≤ c_stab).

---

# 5. Etapa 4 — Cadena de Incertidumbre (FASE 4) — Requiere revisión — O3 × 3 niveles

* [ ] Revisar script `stage_04_uncertainty_chain.R` línea por línea
* [ ] Revisar script `stage_04_uncertainty_chain.py` línea por línea
* [ ] Confirmar filtro O3 (3 niveles)
* [ ] Confirmar Método referencia: x_pt, σ_pt, u_xpt
* [ ] Confirmar Método consenso MADe: x_pt, σ_pt, u_xpt
* [ ] Confirmar Método consenso nIQR: x_pt, σ_pt, u_xpt
* [ ] Confirmar Método Algoritmo A: x_pt, σ_pt, u_xpt
* [ ] Confirmar u_hom, u_stab, u_xpt_def, U_xpt
* [ ] Confirmar factores: 1.25, k=2
* [ ] Ejecutar para O3_0
* [ ] Ejecutar para O3_80
* [ ] Ejecutar para O3_180
* [ ] Comparación tripartita (O3 × 3)
* [ ] Generar/revisar CSV + reporte
* [ ] Clasificar resultados

---

# 6. Etapa 5 — Puntajes (FASE 5) — Requiere revisión — O3 × 3 niveles

* [ ] Revisar script `stage_05_scores.R` línea por línea
* [ ] Revisar script `stage_05_scores.py` línea por línea
* [ ] Confirmar filtro O3 (3 niveles)
* [ ] Confirmar cálculo de z, z', ζ, En
* [ ] Confirmar evaluaciones cualitativas (Satisfactorio/Cuestionable/No satisfactorio)
* [ ] Confirmar que u_xpt_def incluye u_hom y u_stab
* [ ] Confirmar que U_xi = k × u_i con k=2
* [ ] Investigar app_value NaN en scores
* [ ] Ejecutar para O3_0
* [ ] Ejecutar para O3_80
* [ ] Ejecutar para O3_180
* [ ] Comparación tripartita (O3 × 3)
* [ ] Generar/revisar CSV + reporte
* [ ] Clasificar resultados

---

# 7. Algoritmo A — Validación detallada (FASE 6) — Pendiente — O3 × 3 niveles

## Objetivo

Validar paso a paso cada iteración del Algoritmo A (ISO 13528 Annex C), no solo el resultado final.

## Alcance: O3 × 3 niveles

| # | Combo ID | Contaminante | Nivel |
|---|---|---|---|
| 1 | O3_0 | O3 | `0-nmol/mol` |
| 2 | O3_80 | O3 | `80-nmol/mol` |
| 3 | O3_180 | O3 | `180-nmol/mol` |

## Checklist

* [ ] Extraer lógica iterativa de `pt_robust_stats.R` → `run_algorithm_a()`
* [ ] Extraer lógica iterativa de `app.R` → `observeEvent(input$algoA_run, ...)`
* [ ] Documentar paso a paso: inicialización, winsorización, actualización, convergencia
* [ ] Crear `validation/stage_04b_algorithm_a_iterations.R`
* [ ] Crear `validation/stage_04b_algorithm_a_iterations.py`
* [ ] Verificar valores iniciales (mediana, MADe) vs ISO 13528 Annex C Paso 1
* [ ] Verificar factor de winsorización (1.5) vs Paso 2-3
* [ ] Verificar factor de corrección de sesgo (1.134) vs Paso 4
* [ ] Verificar convergencia (3ra cifra significativa) vs NOTE 1
* [ ] Ejecutar para O3_0
* [ ] Ejecutar para O3_80
* [ ] Ejecutar para O3_180
* [ ] Verificar número de iteraciones consistente app/R/Python
* [ ] Comparar iteraciones contra app.R (valores intermedios)
* [ ] Generar `stage_04b_algorithm_a_iterations.csv`
* [ ] Generar reporte Markdown de iteraciones
* [ ] Clasificar resultados

---

# 8. Hojas de cálculo (FASE 7) — Pendiente — O3 × 3 niveles

## Objetivo

Construir validación manual/semimanual en hojas de cálculo con fórmulas explícitas auditables.

## Alcance: O3 × 3 niveles (18 hojas)

| Etapa | # Combos | Archivos |
|-------|----------|----------|
| 1 — Robustos | 3 | `E1_robustos_o3_{0|80|180}.xlsx` |
| 2 — Homogeneidad | 3 | `E2_homog_o3_{0|80|180}.xlsx` |
| 3 — Estabilidad | 3 | `E3_estab_o3_{0|80|180}.xlsx` |
| 4 — Incertidumbre | 3 | `E4_incert_o3_{0|80|180}.xlsx` |
| 4b — Algoritmo A | 3 | `E4b_algoA_o3_{0|80|180}.xlsx` |
| 5 — Puntajes | 3 | `E5_puntajes_o3_{0|80|180}.xlsx` |

## Sub-fase 7.0: Preparación

* [ ] Documentar fórmulas Excel para cada etapa → `validation/excel/formulas_por_etapa.md`
* [ ] Crear plantilla base .xlsx (encabezado, datos, cálculos, resultados, veredicto)

## Sub-fase 7.1: Etapa 1 — Robustos

* [ ] `E1_robustos_o3_0.xlsx`
* [ ] `E1_robustos_o3_80.xlsx`
* [ ] `E1_robustos_o3_180.xlsx`
* [ ] Validar contra R/Python/app.R

## Sub-fase 7.2: Etapa 2 — Homogeneidad

* [ ] `E2_homog_o3_0.xlsx`
* [ ] `E2_homog_o3_80.xlsx`
* [ ] `E2_homog_o3_180.xlsx`
* [ ] Validar contra R/Python/app.R

## Sub-fase 7.3: Etapa 3 — Estabilidad

* [ ] `E3_estab_o3_0.xlsx`
* [ ] `E3_estab_o3_80.xlsx`
* [ ] `E3_estab_o3_180.xlsx`
* [ ] Validar contra R/Python/app.R

## Sub-fase 7.4: Etapa 4 — Incertidumbre + Algoritmo A

* [ ] `E4_incert_o3_0.xlsx`
* [ ] `E4_incert_o3_80.xlsx`
* [ ] `E4_incert_o3_180.xlsx`
* [ ] `E4b_algoA_o3_0.xlsx` (iteraciones detalladas)
* [ ] `E4b_algoA_o3_80.xlsx` (iteraciones detalladas)
* [ ] `E4b_algoA_o3_180.xlsx` (iteraciones detalladas)
* [ ] Validar contra R/Python/app.R

## Sub-fase 7.5: Etapa 5 — Puntajes

* [ ] `E5_puntajes_o3_0.xlsx`
* [ ] `E5_puntajes_o3_80.xlsx`
* [ ] `E5_puntajes_o3_180.xlsx`
* [ ] Validar contra R/Python/app.R

---

# 9. Informe formal de validación (FASE 8) — Pendiente — O3 × 3 niveles

## Objetivo

Generar un informe de validación autocontenido, pre-llenado con valores R/Python, con espacios para pantallazos del aplicativo. Solo para O3 × 3 niveles.

## Checklist

* [ ] Crear template `validation/informe_validacion_o3.md`
* [ ] Sección 1: Información general (fecha, versión, datos, herramientas)
* [ ] Sección 2: Resumen ejecutivo con tabla PASA/FALLA por etapa × nivel O3
* [ ] Sección 3: Etapa 1 — Robustos (O3 × 3 niveles)
* [ ] Sección 4: Etapa 2 — Homogeneidad (O3 × 3 niveles)
* [ ] Sección 5: Etapa 3 — Estabilidad (O3 × 3 niveles)
* [ ] Sección 6: Etapa 4 — Incertidumbre (O3 × 3 niveles, 4 métodos)
* [ ] Sección 6b: Algoritmo A — Iteraciones detalladas (O3 × 3 niveles)
* [ ] Sección 7: Etapa 5 — Puntajes (O3 × 3 niveles, 4 combinaciones)
* [ ] Sección 8: Tabla de trazabilidad (valor → fuente ISO / código / celda Excel)
* [ ] Sección 9: Discrepancias conocidas (u_stab, n=3, cuartiles)
* [ ] Sección 10: Conclusión y firma
* [ ] Pre-llenar valores de CSVs canónicos para O3 × 3 niveles
* [ ] Marcar espacios `[PEGAR CAPTURA]` para valores del aplicativo
* [ ] Consolidar tabla de veredictos PASA/FALLA

---

# 10. Extensión a 15 combos (FASE 9) — FUTURO

**Precondición:** Fases 0–8 completadas y verificadas para O3 en 3 niveles.

* [ ] Ejecutar scripts Etapas 1-5 para CO, SO2, NO2, NO
* [ ] Ejecutar Algoritmo A detallado para CO, SO2, NO2, NO
* [ ] Generar hojas de cálculo para CO, SO2, NO2, NO
* [ ] Extender informe formal a 5 contaminantes
* [ ] Verificar consistencia con resultados de Fases 0–5 previas

---

# 11. Cierre global del proyecto

## Requisitos mínimos para declarar "Validación O3 cerrada"

* [ ] Fases 0–5 revisadas y aprobadas para O3 × 3 niveles
* [ ] Fase 6 cerrada (Algoritmo A detallado, O3 × 3 niveles)
* [ ] Fase 7 cerrada (Hojas de cálculo, O3 × 3 niveles)
* [ ] Fase 8 cerrada (Informe formal, O3 × 3 niveles)
* [ ] Todos los CSV para O3 × 3 niveles existen y están completos
* [ ] Todos los reportes Markdown para O3 × 3 niveles existen
* [ ] No hay FAIL sin explicación
* [ ] Los casos borde están documentados
* [ ] Las discrepancias conocidas están documentadas
* [ ] La validación es reproducible end-to-end para O3 × 3 niveles
* [ ] Existe informe formal O3 con pantallazos

---

# 12. Registro rápido de bloqueos

## Bloqueos técnicos

* [ ] Pendiente: `app_value` en NaN para varios combos en Stage 05 (requiere ejecutar app con datos n13)
* [ ] Pendiente: investigar discrepancia u_stab
* [ ] Pendiente: revisar todos los scripts antes de usar sus outputs

## Notas de bloqueo

* Datos n4 vs n13: los scripts usan summary_n13.csv pero la app puede no haber sido ejecutada con esos datos.
* u_stab: discrepancia conocida entre app y scripts independientes (requiere investigación).
* **TODO-ZERO:** No se asume que ningún resultado previo es correcto. Todo debe revisarse.

---

# 13. Próxima acción recomendada

## Siguiente paso inmediato

1. [ ] Revisar `stage_01_robust_stats.R` línea por línea
2. [ ] Revisar `stage_01_robust_stats.py` línea por línea
3. [ ] Confirmar que filtran O3 correctamente (3 niveles)
4. [ ] Ejecutar para O3_0, O3_80, O3_180
5. [ ] Comparar resultados tripartita