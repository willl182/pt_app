# Plan: Exportación de puntajes finales PT en un solo CSV

**Fecha:** 2026-07-12
**Estado:** Implementado (helper en `R/export_final_scores.R`, handler `download_final_scores_csv` en app.R, tests en `tests/testthat/test-final-scores-export.R`). El helper retorna NULL también con 0 filas tras filtrar "ref", y `unidad` es NA si el level no contiene "-".

## Objetivo

Exportar los puntajes finales del ensayo de aptitud en un único CSV con las columnas:

```
participant_code, contaminante, run_code, level_label, unidad,
valor_asignado, u_xpt, sigma_pt, valor_participante, u_lab, U_lab,
z, z_prima, zeta, en, clasificacion
```

## Fuente de datos (ya existe, no se recalcula nada)

- `scores_results_cache` (app.R:3602) guarda resultados por combinación pollutant × n_lab × level tras pulsar "Calcular puntajes".
- `global_report_data()` (app.R:3606-3713) ya aplana todo en `$combos`: una fila por participante × combinación × método, con `result`, `x_pt`, `sigma_pt`, `u_xpt_def`, `uncertainty_std` (u_i), `U_xi`, `U_xpt`, `z_score`, `z_prime_score`, `zeta_score`, `En_score` y sus evaluaciones.
- Los puntajes por método se calculan en `compute_combo_scores` (app.R:3211-3286).

Solo hay que transmutar columnas y escribir el CSV.

## Pasos de implementación

### 1. Helper `build_final_scores_export_df()`

En el server de app.R, junto a `build_homogeneity_export_df`:

```r
build_final_scores_export_df <- function() {
  data <- global_report_data()
  if (!is.null(data$error) || nrow(data$combos) == 0) return(NULL)
  data$combos %>%
    filter(participant_id != "ref") %>%
    transmute(
      participant_code = participant_id,
      contaminante     = pollutant,
      run_code         = n_lab,                      # ver decisión abajo
      level_label      = level,
      unidad           = sub("^[^-]*-", "", level),  # "0-μmol/mol" -> "μmol/mol"
      metodo           = combination_label,          # 1, 2a, 2b, 3, 4
      valor_asignado   = x_pt,
      u_xpt            = u_xpt_def,
      sigma_pt         = sigma_pt,
      valor_participante = result,
      u_lab            = uncertainty_std,            # u_i reportada
      U_lab            = U_xi,                       # u_exp o k*u_i
      z                = z_score,
      z_prima          = z_prime_score,
      zeta             = zeta_score,
      en               = En_score,
      clasificacion    = z_score_eval
    )
}
```

### 2. UI

`downloadButton("download_final_scores_csv", "Exportar puntajes finales (CSV)")` en la pestaña de Informe global (cerca de app.R:2102).

### 3. downloadHandler

Patrón idéntico a `download_scores_csv` (app.R:4798):

- Nombre de archivo: `Puntajes_Finales_PT_<fecha>.csv`
- `write.csv(..., row.names = FALSE, fileEncoding = "UTF-8", na = "")`
- Si `build_final_scores_export_df()` retorna NULL: CSV con mensaje "Ejecute 'Calcular puntajes' primero".
- Sin líneas `#` de encabezado — CSV plano, una sola tabla, parseable directo.

### 4. Test

testthat sobre el helper (extraído o vía snapshot de columnas):

- Verifica 16+1 columnas.
- Sin fila "ref".
- `unidad` extraída correctamente del level.

## Decisiones tomadas (ajustables)

1. **`run_code` = `n_lab`.** Los puntajes se calculan agregando corridas (`compute_scores_for_selection` promedia sobre `run`, app.R:3340-3347); la columna `run` original ("corrida_1"...) no sobrevive al cálculo. `n_lab` es el identificador de ronda que la app usa en toda la UI. *Alternativa:* concatenar corridas fuente ("corrida_1;corrida_2") con join extra a `pt_prep_data()`.

2. **Columna extra `metodo`.** Hay 5 métodos de valor asignado (ref, MADe, nIQR, Algoritmo A, expertos) — sin esa columna, filas con mismo participante/nivel serían ambiguas. Si se requieren estrictamente las 16 columnas, se filtra a un método (ref por defecto) y se elimina `metodo`.

3. **`u_xpt` = `u_xpt_def`** (incluye u_hom y u_stab) — es la que realmente entra en z', zeta, En. *Alternativa:* `u_xpt` base.

4. **`clasificacion` = evaluación del puntaje z** (Satisfactorio/Cuestionable/No satisfactorio). La clasificación combinada `classification_z_en` nunca se calcula en el código (solo `ensure_classification_columns` rellena NA). *Alternativa:* regla combinada z+En.

## Alcance

Solo app.R (~40 líneas) + test. Sin cambios en R/pt_scores.R ni en datos.
