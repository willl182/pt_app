# Plan: Ajuste flujos participante/referencia — corrección uncertainty_std

**Created**: 2026-04-24 16:46
**Updated**: 2026-04-25 09:34
**Status**: Completo
**Slug**: ajuste-incertidumbre-participante

## Objetivo

Corregir el cálculo de `uncertainty_std` del participante: actualmente se deriva incorrectamente como `sd_value / sqrt(2)` con `m=2` hardcodeado. El participante debe reportar `u_i` directamente, ya que la app no puede conocer su presupuesto de incertidumbre interno.

## Arquitectura correcta

**Laboratorio de referencia (PT provider):**
- 2 mediciones propias → homogeneidad + estabilidad → `u_xpt_def = √(u_xpt² + u_hom² + u_stab²)`
- Define `x_pt` y `sigma_pt`

**Participantes:**
- 3 mediciones → reportan `x_i` y `u_i` (presupuesto propio, no recalculable por la app)

**Scores (cruzan ambos lados):**
- `z  = (x_i - x_pt) / sigma_pt`
- `zeta = (x_i - x_pt) / √(u_i² + u_xpt_def²)`
- `En = (x_i - x_pt) / √((k·u_i)² + U_xpt²)`

## Fases

### Fase 1: Formato CSV de entrada

| # | Archivo | Acción | Notas |
|---|---------|--------|-------|
| 1.1 | `data/pt_data_n13.csv` | Crear archivo nuevo | Formato: `participant_id, pollutant, level, x_i, u_i` |

`summary_n13.csv` no se toca y no contiene `u_i`. El nuevo archivo `pt_data_n13.csv` tiene una fila por participante por combo. La columna `sd_value` en `summary_n13.csv` queda solo para verificación interna. El `sd(mean_values)/√3` se calcula internamente como chequeo de consistencia contra `u_i`.

### Fase 2: app.R

| # | Archivo | Acción | Notas |
|---|---------|--------|-------|
| 2.1 | `app.R:927` | Reemplazar `sd_value / sqrt(m)` → leer `u_i` directo | Primera ocurrencia |
| 2.2 | `app.R:2616` | Mismo ajuste | Segunda ocurrencia |
| 2.3 | `app.R:206-207` | `mean(sd_value)` queda solo para verificación interna | No fluye a scores |
| 2.4 | `app.R:4791` | `calculate_method_scores_df` — tercera ocurrencia detectada en auditoría | Join `pt_data_df()` + `uncertainty_std` en `zeta_score` y `En_score` |

### Fase 3: stage_05_scores.py

| # | Archivo | Acción | Notas |
|---|---------|--------|-------|
| 3.1 | `validation/stage_05_scores.py:154` | Eliminar `mean_sd / math.sqrt(2)` | |
| 3.2 | `validation/stage_05_scores.py:125` | Leer `u_i` del CSV directamente | |
| 3.3 | `validation/stage_05_scores.py` | Renombrar variable interna a `u_i` | Claridad |

### Fase 4: Verificación de consistencia (alerta, no error)

| # | Archivo | Acción | Notas |
|---|---------|--------|-------|
| 4.1 | `app.R` / `stage_05_scores.py` | Calcular `sd(3 mean_values)/√3` | Solo comparación |
| 4.2 | Ambos | Emitir advertencia si difiere significativamente de `u_i` | Umbral a definir |

### Fase 5: Datos de validación

| # | Archivo | Acción | Notas |
|---|---------|--------|-------|
| 5.1 | `data/pt_data_n13.csv` | Crear/actualizar datos `u_i` con valores de test | `summary_n13.csv` no trae `u_i` |
| 5.2 | `validation/outputs/stage_05_*` | Regenerar con nueva lógica | |
| 5.3 | Suite de validación | Correr y confirmar PASS | |

## Log de Ejecución

- [x] Fase 1: formato CSV definido y creado (`data/pt_data_n13.csv`, 372 filas)
- [x] Fase 2: app.R ajustado (reactive `pt_data_df()` + join en 3 puntos: L927, L2616, L4791; sin fallback a `sd_value` para zeta/En)
- [x] Fase 3: `stage_05_scores.py` y `stage_05_scores.R` ajustados (u_i desde CSV)
- [x] Fase 4: verificación de consistencia implementada en app.R y en ambos scripts de validación (alerta >50% diferencia relativa)
- [x] Fase 5: validación corrida y PASS confirmado — 5760 PASS (Python), 720 filas (R)

Commit base: `10d5b43` — 2026-04-24

Ajuste posterior — 2026-04-25:
- `u_i` es obligatorio para calcular `zeta` y `En`; si falta, esos scores quedan no calculables.
- Fuente renombrada a `data/pt_data_n13.csv`; `summary_n13.csv` no trae `u_i`.
- Reporte usa `u_i` para la incertidumbre del participante y `u_xpt` para la incertidumbre del valor asignado.
- Commit pendiente.
