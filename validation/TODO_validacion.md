# TODO_validacion.md

## Fase 0
- [x] Crear estructura de `validation/`
- [x] Crear `validation/outputs/`
- [x] Crear `validation/outputs/combo_excels/`
- [x] Crear scripts base R/Python
- [x] Definir combos objetivo (15)
- [x] Definir columnas canónicas
- [x] Definir estados válidos
- [x] Crear `USAGE.md`

## Fase 1 (cerrada)
- [x] Implementar extracción reproducible desde `data/summary_n13.csv`
- [x] Implementar robust stats en R
- [x] Implementar robust stats en Python
- [x] Comparación tripartita app/R/Python
- [x] Generar CSV de etapa
- [x] Generar reporte Markdown de etapa

## Fase 2 (cerrada)
- [x] Implementar homogeneidad en R (`validation/stage_02_homogeneity.R`)
- [x] Implementar homogeneidad en Python (`validation/stage_02_homogeneity.py`)
- [x] Comparación tripartita app/R/Python
- [x] Generar CSV de etapa
- [x] Generar reporte Markdown de etapa
- [x] Integrar Stage 02 en orquestadores R/Python

## Fase 3 (cerrada)
- [x] Implementar estabilidad en R (`validation/stage_03_stability.R`)
- [x] Implementar estabilidad en Python (`validation/stage_03_stability.py`)
- [x] Comparación tripartita app/R/Python
- [x] Generar CSV de etapa
- [x] Generar reporte Markdown de etapa
- [x] Integrar Stage 03 en orquestadores R/Python

## Fase 4 (cerrada)
- [x] Implementar cadena de incertidumbre en R (`validation/stage_04_uncertainty_chain.R`)
- [x] Implementar cadena de incertidumbre en Python (`validation/stage_04_uncertainty_chain.py`)
- [x] Comparación tripartita app/R/Python
- [x] Generar CSV de etapa
- [x] Generar reporte Markdown de etapa
- [x] Integrar Stage 04 en orquestadores R/Python

## Fase 5
- [x] Confirmar insumos de Stage 04 para scores (`stage_04_uncertainty_chain.csv`)
- [x] Definir contrato de métricas para `z`, `z_prime`, `zeta`, `en`
- [x] Implementar `validation/stage_05_scores.R`
- [x] Implementar `validation/stage_05_scores.py`
- [x] Integrar Stage 05 en orquestadores R/Python
- [x] Ejecutar Stage 05 standalone (R/Python)
- [x] Ejecutar pipeline completo Stages 01-05
- [x] Generar CSV + Markdown de etapa y cerrar documentación final
