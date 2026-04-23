# Plan: Migración a 3 Cifras Significativas — Algoritmo A

**Created**: 2026-04-20 15:08
**Updated**: 2026-04-20 15:08
**Status**: approved
**Slug**: cifras-significativas

## Objetivo

Reemplazar la tolerancia absoluta `1e-06` del Algoritmo A por el criterio ISO 13528:2022 correcto: convergencia cuando no hay cambio en la 3ª cifra significativa de x* y s*. Además, homologar el formato de salida numérica del app a 3 cifras significativas magnitud-dependientes.

## Fases

### Fase 1: Criterio de convergencia

| # | Archivo | Acción | Notas |
|---|---------|--------|-------|
| 1.1 | `R/pt_robust_stats.R:259` | Reemplazar `delta_x < tol && delta_s < tol` | por `signif(x_new,3)==signif(x_star,3) && signif(s_new,3)==signif(s_star,3)` |
| 1.2 | `R/pt_robust_stats.R:86` | Actualizar `@details` | "changes < tolerance" → "no change in 3rd significant figure" |
| 1.3 | `R/pt_robust_stats.R:96` | Actualizar `@param tol` | Aclarar que `tol` es guardia numérica, no criterio primario |
| 1.4 | `ptcalc/R/pt_robust_stats.R` | Sincronizar mismo cambio | Si es copia del principal |

### Fase 2: Formato de salida numérica

| # | Archivo | Acción | Notas |
|---|---------|--------|-------|
| 2.1 | `app.R:206–211` | Reescribir `format_num()` | Implementar lógica por magnitud: <10→%.2f, <100→%.1f, <1000→%.0f |
| 2.2 | `app.R:~1810` | Evaluar `round(.x, 5)` | Cambiar a `signif(.x, 3)` solo si es display, no si alimenta cálculos |
| 2.3 | `app.R:~1951` | Mismo que 2.2 | Idem |

### Fase 3: Validación post-cambio

| # | Tarea | Criterio de aceptación |
|---|-------|------------------------|
| 3.1 | Casos ISO Annex C | x* y s* idénticos al estándar |
| 3.2 | Test magnitudes extremas | CO ~0.02, SO₂ ~60, analito ~500 |
| 3.3 | Test display `format_num()` | Verificar los 3 rangos con ejemplos concretos |
| 3.4 | Suite completa de validación | 6,660 PASS mantenidos |

## Log de Ejecución

- [ ] Fase 1.1 — convergencia implementada
- [ ] Fase 1.2–1.3 — docstring actualizado
- [ ] Fase 1.4 — ptcalc sincronizado
- [ ] Fase 2.1 — format_num() reescrita
- [ ] Fase 2.2–2.3 — rounding intermedio revisado
- [ ] Fase 3 — validación completa
