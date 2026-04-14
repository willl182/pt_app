# Plan: Fase 5 — Scores de Desempeño

**Timestamp:** 260331_1902
**Slug:** fase-5-scores
**Estado:** Pendiente

---

## Objetivo

Validar el cálculo de scores de desempeño por participante (z, z', zeta, En) con comparación bipartita (R independiente vs Python) para los 15 combos objetivo y 4 métodos de cálculo.

---

## Contexto

### Fuente de datos

- `data/summary_n13.csv` — resultados crudos por participante (mean_value, sd_value, replicate, sample_group)
- `validation/outputs/stage_02_homogeneity_r.csv` — contiene m=2, ss (u_hom), g, n_part
- `validation/outputs/stage_03_stability_r.csv` — contiene diff_hom_stab para derivar u_stab
- `validation/outputs/stage_04_uncertainty_chain.csv` — contiene x_pt, sigma_pt, u_xpt, u_xpt_def, U_xpt por combo/método

### Preprocesamiento de datos de participantes

La app agrega los datos de `summary_n13.csv` por participante/combo:

```r
subset_data %>%
  filter(participant_id != "ref") %>%
  group_by(participant_id) %>%
  summarise(
    result = mean(mean_value, na.rm = TRUE),
    sd_value = mean(sd_value, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    uncertainty_std = sd_value / sqrt(m)  # m=2 de hom_res$m
  )
```

**Clave:** `uncertainty_std = sd_value / sqrt(2)` (m=2 en todos los combos)

### Fórmulas (app.R: 2328–2395)

| Score | Fórmula | Línea app.R |
|-------|---------|-------------|
| `z_score` | `(result - x_pt) / sigma_pt` | 2349 |
| `z_prime_score` | `(result - x_pt) / sqrt(sigma_pt² + u_xpt_def²)` | 2351–2352 |
| `zeta_score` | `(result - x_pt) / sqrt(uncertainty_std² + u_xpt_def²)` | 2356–2357 |
| `En_score` | `(result - x_pt) / sqrt((k·uncertainty_std)² + (k·u_xpt_def)²)` | 2358–2361 |

**Evaluaciones:**
- z, z', zeta: `|score| ≤ 2` → Satisfactorio; `2 < |score| < 3` → Cuestionable; `|score| ≥ 3` → No satisfactorio; no finito → N/A
- En: `|En| ≤ 1` → Satisfactorio; `|En| > 1` → No satisfactorio; no finito → N/A
- k = 2

### Métodos (4 por combo — heredados de Fase 4)

| Label | Método | x_pt fuente | sigma_pt fuente |
|-------|--------|-------------|-----------------|
| Referencia | Referencia (1) | x_pt de hom_res | sigma_pt de hom_res |
| Consenso MADe | Consenso MADe (2a) | Mediana | MADe normalizado (sigma_pt_2a) |
| Consenso nIQR | Consenso nIQR (2b) | Mediana | nIQR (sigma_pt_2b) |
| Algoritmo A | Algoritmo A (3) | Algo A assigned | Algo A robust_sd |

Todos los valores de x_pt, sigma_pt, u_xpt, u_xpt_def por combo/método están disponibles en `stage_04_uncertainty_chain.csv`.

### Dimensiones de la validación

| Dimensión | Cantidad |
|-----------|----------|
| Combos | 15 |
| Métodos | 4 |
| Participantes por combo | 13 |
| Métricas numéricas por participante/método | 4 (z, z', zeta, En) |
| Métricas categoriales por participante/método | 4 (eval de cada score) |
| **Total comparaciones** | **15 × 4 × 13 × 8 = 6,240** |

---

## Fases

### Fase 5.1: Lectura y preparación de datos

| Item | Estado | Notas |
|------|--------|-------|
| Cargar summary_n13.csv y agregar por participante/combo | Pendiente | mean(mean_value), mean(sd_value) |
| Calcular uncertainty_std = sd_value / sqrt(2) | Pendiente | m=2 de homogeneidad |
| Cargar stage_04_uncertainty_chain.csv para x_pt, sigma_pt, u_xpt, u_xpt_def por combo/método | Pendiente | Filtrar métricas relevantes |
| Verificar 15 combos objetivo presentes | Pendiente | Mismos combo_ids que Fase 4 |

### Fase 5.2: Cálculo independiente en R (`stage_05_scores.R`)

| Item | Estado | Notas |
|------|--------|-------|
| Loop sobre 15 combos × 4 métodos | Pendiente | |
| Para cada combo/método: obtener x_pt, sigma_pt, u_xpt_def | Pendiente | Leer stage_04 CSV |
| Para cada participante: calcular z_score | Pendiente | (result - x_pt) / sigma_pt |
| Para cada participante: calcular z_prime_score | Pendiente | den = sqrt(sigma_pt² + u_xpt_def²) |
| Para cada participante: calcular zeta_score | Pendiente | den = sqrt(uncertainty_std² + u_xpt_def²) |
| Para cada participante: calcular En_score | Pendiente | den = sqrt((k*u_std)² + (k*u_xpt_def)²) |
| Aplicar evaluaciones (z/z'/zeta: 3 categorías; En: 2 categorías) | Pendiente | |
| Generar `stage_05_scores_r.csv` (intermedio) | Pendiente | Tabla larga: combo/método/participante/métrica/valor |

### Fase 5.3: Cálculo independiente en Python (`stage_05_scores.py`)

| Item | Estado | Notas |
|------|--------|-------|
| Replicar toda la lógica de R | Pendiente | Mismas fórmulas, misma agregación |
| Cargar stage_05_scores_r.csv para comparación | Pendiente | |
| Validar scores numéricos con tolerancia 1e-9 | Pendiente | |
| Validar evaluaciones categoriales con coincidencia exacta | Pendiente | |
| Generar `stage_05_scores.csv` (tabla canónica) | Pendiente | |
| Generar `stage_05_scores_report.md` | Pendiente | Resumen PASS/FAIL |

### Fase 5.4: Comparación y outputs

| Item | Estado | Notas |
|------|--------|-------|
| 6,240 comparaciones R vs Python | Pendiente | |
| Tolerancia: 1e-9 para numéricos, exact para categoriales | Pendiente | |
| Clasificar PASS/FAIL | Pendiente | |
| Identificar EDGE_CASE (e.g. zeta/En con uncertainty_std = 0 o NA) | Pendiente | |
| Generar CSV canónico con columnas estándar | Pendiente | |
| Generar reporte Markdown | Pendiente | |

---

## Estructura del CSV de salida

```
combo_id, pollutant, level, stage, section (método), participant_id,
metric, app_value (nan), r_value, python_value,
diff_app_r (nan), diff_app_python (nan), diff_r_python,
status, tolerance, notes
```

**Métricas por fila (8 por participante/método):**
- `z_score`, `z_score_eval`
- `z_prime_score`, `z_prime_score_eval`
- `zeta_score`, `zeta_score_eval`
- `En_score`, `En_score_eval`

Para métricas numéricas: `tolerance = 1e-9`
Para evaluaciones categoriales: `tolerance = exact`

---

## Riesgos y consideraciones

| Riesgo | Mitigación |
|--------|------------|
| uncertainty_std = 0 o NA para algún participante | zeta/En devuelven NA → eval "N/A", PASS si ambos coinciden |
| sigma_pt inválido para Algoritmo A en algún combo | z, z', zeta, En = NA → "N/A", documentar |
| Participante "ref" en datos | Filtrar `participant_id != "ref"` antes de calcular |
| Diferencias flotantes en evaluaciones por umbral exacto |abs(z) exactamente 2.0 o 3.0: verificar consistencia R/Python |
| Lectura de stage_04 CSV: múltiples filas por combo/método/métrica | Pivotear wide antes de usar |

---

## Criterio de cierre

La Fase 5 está cerrada cuando:
1. Los 15 combos × 4 métodos × 13 participantes se procesan correctamente
2. Los 4 scores numéricos coinciden R vs Python dentro de 1e-9
3. Las 4 evaluaciones categoriales coinciden R vs Python exactamente
4. Existe CSV de salida con tabla canónica (6,240 filas)
5. Existe reporte Markdown con resumen PASS/FAIL

---

## Log de Ejecución

- [260331 19:02] Plan creado — scores de desempeño
