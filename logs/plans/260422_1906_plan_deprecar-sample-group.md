# Plan: Deprecar columna `sample_group`

**Created**: 2026-04-22 19:06
**Updated**: 2026-04-22 19:39
**Status**: completed
**Slug**: deprecar-sample-group

## Objetivo

Eliminar `sample_group` del contrato de entrada de la app y del paquete `ptcalc`.
La columna ya es ignorada funcionalmente (el `pt_prep_data()` reactive la descarta
en el `group_by`/`summarise`, y `ptcalc/` nunca la referencia), pero sigue
apareciendo en datos de prueba, documentación y un script de entrega.

## Diagnóstico

- `app.R` `pt_prep_data()` (líneas 160-203): agrega por `group_by(participant_id,
  pollutant, level, run, n_lab)` → `sample_group` ya se descarta silenciosamente.
- Validación de columnas obligatorias (línea 181): NO incluye `sample_group`.
- `ptcalc/R/*.R`: ninguna referencia a `sample_group`.
- Sobrevive en:
  - `data/summary_n{4,7,10,13}.csv` (columna en CSV de prueba)
  - `deliv/04_puntajes/R/calcula_puntajes.R:155` (se propaga al output)
  - `deliv/04_puntajes/tests/test_04_puntajes.R:211` (columna esperada en test)
  - Documentación (`es/01a_formatos_datos.md`, `es/MANUAL_COMPLETO_PT_APP.md`,
    `es/00_inicio_rapido.md`, `es/01_carga_datos.md`)
  - Scripts de demo (`scripts/demo_valores_consenso.R`,
    `scripts/demo_calculo_scores.R`, `scripts/build_homogeneity_stability_from_summary.R`)

## Fases

### Fase 1: `app.R` — advertencia de deprecación

| # | Archivo | Acción | Notas |
|---|---------|--------|-------|
| 1.1 | `app.R` | Insertar bloque de advertencia en `pt_prep_data()` tras `validate(need(...))` ~línea 184 | `showNotification()` tipo `"warning"` si `"sample_group" %in% names(raw_data)` |

Código a insertar:
```r
if ("sample_group" %in% names(raw_data)) {
  showNotification(
    "La columna 'sample_group' está presente pero ha sido deprecada y será ignorada. El formato actual no la requiere.",
    type = "warning", duration = 8
  )
}
```

### Fase 2: `ptcalc/` — bump de versión y NEWS

| # | Archivo | Acción | Notas |
|---|---------|--------|-------|
| 2.1 | `ptcalc/DESCRIPTION` | `Version: 0.1.0` → `0.1.1` | |
| 2.2 | `ptcalc/NEWS.md` | Crear con entrada de deprecación | Ver contenido abajo |

`ptcalc/NEWS.md` contenido:
```markdown
# ptcalc 0.1.1

- `sample_group` removida del contrato de entrada de datos. La columna nunca fue
  utilizada por las funciones del paquete; si estaba presente en los datos de
  entrada, era ignorada silenciosamente. Los flujos de datos que la incluyan
  deben omitirla.
```

### Fase 3: `deliv/` — eliminar propagación

| # | Archivo | Acción | Notas |
|---|---------|--------|-------|
| 3.1 | `deliv/04_puntajes/R/calcula_puntajes.R` | Eliminar línea 155: `sample_group = datos_participante$sample_group,` | |
| 3.2 | `deliv/04_puntajes/tests/test_04_puntajes.R` | Eliminar `"sample_group"` del vector `columnas_esperadas` (línea 211) | |

### Fase 4: CSV de prueba — limpiar columna

| # | Archivo | Acción | Notas |
|---|---------|--------|-------|
| 4.1 | `data/summary_n4.csv` | Remover columna `sample_group` | Usar R: `df[, !names(df) %in% "sample_group"]` |
| 4.2 | `data/summary_n7.csv` | Ídem | |
| 4.3 | `data/summary_n10.csv` | Ídem | |
| 4.4 | `data/summary_n13.csv` | Ídem | |

### Fase 5: Documentación

| # | Archivo | Acción | Notas |
|---|---------|--------|-------|
| 5.1 | `es/01a_formatos_datos.md` | Eliminar fila `sample_group` de tabla de columnas opcionales (~línea 73) y actualizar ejemplo CSV | |
| 5.2 | `es/MANUAL_COMPLETO_PT_APP.md` | Ídem (~línea 337) | |
| 5.3 | `es/00_inicio_rapido.md` | Actualizar ejemplo CSV (~línea 140) | |
| 5.4 | `es/01_carga_datos.md` | Actualizar ejemplo CSV (~línea 209) | |

### Fase 6: Smoke test

| # | Acción | Criterio de éxito |
|---|--------|-------------------|
| 6.1 | Cargar `data/summary_n4.csv` (ya sin `sample_group`) en la app | Sin errores de validación, cálculos correctos |
| 6.2 | Cargar un CSV con `sample_group` en la app | Aparece `showNotification` de advertencia, cálculos correctos |
| 6.3 | `devtools::test("ptcalc")` | Todos los tests PASS |

## Log de Ejecución

- [x] Fase 1 — `app.R` advertencia
- [x] Fase 2 — `ptcalc/` versión + NEWS
- [x] Fase 3 — `deliv/` eliminación
- [x] Fase 4 — CSV limpieza
- [x] Fase 5 — Documentación
- [x] Fase 6 — Smoke test
- [260422 19:09] Fase 1 implementada: advertencia `showNotification()` en `pt_prep_data()` cuando se detecta `sample_group`.
- [260422 19:09] Fase 2 implementada: `ptcalc` actualizado a `0.1.1` y `NEWS.md` con entrada de deprecación.
- [260422 19:38] Fase 3 implementada: eliminada la propagación de `sample_group` en `deliv/04_puntajes/R/calcula_puntajes.R` y ajustado test de columnas esperadas.
- [260422 19:39] Fase 4 implementada: eliminada columna `sample_group` de `data/summary_n4.csv`, `data/summary_n7.csv`, `data/summary_n10.csv` y `data/summary_n13.csv`.
- [260422 20:00] Fase 5 implementada: eliminada fila `sample_group` de tablas en `es/01a_formatos_datos.md` y `es/MANUAL_COMPLETO_PT_APP.md`; eliminada columna de ejemplos CSV en `es/00_inicio_rapido.md` y `es/01_carga_datos.md`.
