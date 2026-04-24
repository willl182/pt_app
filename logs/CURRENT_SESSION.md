# Session State: pt_app

**Last Updated**: 2026-04-24 17:23

## Session Objective

Implementar corrección del cálculo de `uncertainty_std` del participante:
leer `u_i` directamente desde `uncertainty_n13.csv` en lugar de derivar `sd_value/sqrt(m)`.

## Current State

- [x] Revisado el bug: `sd_value / sqrt(2)` con m hardcodeado en app.R y scripts de validación
- [x] Creado `data/uncertainty_n13.csv` (372 filas: 12 participantes × 31 combos)
  - Columnas: `participant_id, pollutant, level, x_i, u_i`
  - `u_i` sintético = `mean(sd_value) * 1.5` (reemplazar con valores reales cuando estén disponibles)
- [x] `app.R`: nuevo reactive `uncertainty_df()` carga el CSV automáticamente desde `data/`
- [x] `app.R`: `compute_scores_metrics` (antigua L927) → join + `u_i` + fallback + alerta Fase 4
- [x] `app.R`: `compute_combo_scores` (antigua L2616) → mismo ajuste
- [x] `validation/stage_05_scores.py`: nueva `load_uncertainty()`; `load_participants()` recibe `u_map`
- [x] `validation/stage_05_scores.R`: merge con `uncertainty_n13.csv` reemplaza `sd/sqrt(2)`
- [x] Alerta de consistencia implementada: `>50% diferencia relativa` entre `u_i` y `sd/√3`
- [x] Commit `10d5b43` con todos los cambios
- [ ] Fase 5: correr suite de validación y confirmar PASS

## Critical Technical Context

**Arquitectura de incertidumbre (correcta):**
- `summary_n13.csv`: 3 filas por participante × combo → `sd_value` = SD intra-réplica (solo verificación)
- `uncertainty_n13.csv`: 1 fila por participante × combo → `u_i` = presupuesto propio del participante
- `u_i_check = sd_value/√3` → solo para chequeo de consistencia, nunca fluye a scores
- Homogeneidad y estabilidad son exclusivas del lado de referencia

**Join en app.R:**
- Se usa `dplyr::left_join(u_df |> dplyr::select(participant_id, u_i), by = "participant_id")`
- `u_df` tiene `participant_id, pollutant, level, u_i` pero se hace `select(participant_id, u_i)` antes
  del join para evitar columnas duplicadas (pollutant.x/pollutant.y)
- `participant_data` ya viene filtrado por `pollutant` y `level` en ambos contextos

**Alerta de consistencia (Fase 4):**
- Umbral: `abs(u_i - u_i_check) / u_i > 0.50`
- Tipo `"message"` (azul), duración 12s — nunca bloquea el cálculo

**Datos sintéticos:**
- Los `u_i` en `uncertainty_n13.csv` son `mean(sd_value) * 1.5`
- Cuando el laboratorio entregue presupuestos reales, solo reemplazar la columna `u_i`

## Next Steps

1. (Incertidumbre) Reemplazar `u_i` sintéticos por valores reales de los participantes.
2. (Incertidumbre) Correr `python3 validation/stage_05_scores.py` → confirmar PASS (Fase 5).
3. (Preprocessing) Retomar plan `260424_1624_plan_preprocesamiento-calaire.md`:
   - Crear estructura `R/preprocessing/` y `scripts/preprocesar_calaire.R`
   - Definir `data/metadata/niveles_calaire.csv` y `data/metadata/diseno_estabilidad_homogeneidad.csv`
