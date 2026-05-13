# Inventario Fase 1 - Excel con formulas validacion O3

## Alcance confirmado

- Analito: `o3`.
- Esquema: `n_lab = 13`.
- Niveles: `0-nmol/mol`, `80-nmol/mol`, `180-nmol/mol`.
- Snapshot esperado:
  `validation_1/validation/excel/validacion_o3/valores_validacion_o3.csv`.
- Generador actual del snapshot:
  `validation_1/validation/excel/validacion_o3/generar_valores_validacion_o3.R`.
- Generador actual de libros hardcodeados:
  `validation_1/validation/excel/validacion_o3/script_excel_validacion_o3.R`.
- Decision corregida tras revision de fase: el snapshot fue regenerado para
  incluir `Expertos (4)` y para que `Referencia (1)` use
  `sigma_pt = 0.020*x_pt + 1.0`, igual que `app.R`.

## Mapeo snapshot a hojas formula

| Seccion snapshot | Hoja formula primaria | Hojas fuente/calculo | Llaves de comparacion |
|---|---|---|---|
| `resultado_homogeneidad` | `resultado_homogeneidad` | `datos_homogeneidad`, `calc_homogeneidad`, `validacion_snapshot` | `combo_id`, `section`, `tabla`, `parametro` |
| `resultado_estabilidad` | `resultado_estabilidad` | `datos_estabilidad`, `calc_estabilidad`, `calc_homogeneidad`, `validacion_snapshot` | `combo_id`, `section`, `tabla`, `parametro` |
| `valor_asignado` | `valor_asignado` | `datos_participantes`, `datos_referencia`, `calc_homogeneidad`, `calc_estabilidad`, `algoritmo_A_iteraciones`, `validacion_snapshot` | `combo_id`, `section`, `method_key` |
| `algoritmo_A` | `algoritmo_A` | `datos_participantes`, `algoritmo_A_iteraciones`, `validacion_snapshot` | `combo_id`, `section`, `bloque`, `parametro` |
| `puntajes_EA` | `puntajes_EA` | `datos_participantes`, `valor_asignado`, `validacion_snapshot` | `combo_id`, `section`, `method`, `participant_id` |
| `informe_global` | `informe_global` | `valor_asignado`, `puntajes_EA`, `validacion_snapshot` | `combo_id`, `section`, `tabla`, `bloque`, `method`, `score` |
| No existe aun en snapshot | `heatmap_datos_globales` | `puntajes_EA` de los tres niveles | `method`, `score_tipo`, `participant_id`, `level` |
| No existe aun en snapshot | `heatmap_global_[metodo]` | `heatmap_datos_globales` | `method`, `score_tipo`, `participant_id`, `level` |

## Columnas relevantes del snapshot

| Grupo | Columnas |
|---|---|
| Identificacion | `combo_id`, `pollutant`, `n_lab`, `level`, `section` |
| Tablas visibles | `tabla`, `bloque`, `parametro`, `app_value` |
| Valor asignado | `method_key`, `method`, `x_pt`, `sigma_pt`, `u_xpt`, `u_hom`, `u_stab`, `u_xpt_def`, `U_xpt`, `n_participants` |
| Puntajes | `participant_id`, `result`, `u_xi`, `z_score`, `z_score_eval`, `z_prime_score`, `z_prime_score_eval`, `zeta_score`, `zeta_score_eval`, `En_score`, `En_score_eval` |
| Conteos globales | `score`, `N/A`, `Satisfactorio`, `Cuestionable`, `No satisfactorio` |

## Funciones R a traducir a Excel

| Area | Funcion / bloque R | Traduccion Excel requerida |
|---|---|---|
| Datos base | `wide_data()` en `generar_valores_validacion_o3.R` | Filtro por `pollutant` y `level`; columnas `sample_1`, `sample_2`; orden por `sample_id`. |
| Participantes | `participant_data()` | Excluir `ref`; `AVERAGE` de `mean_value` y `sd_value` por participante; `u_i` desde `pt_data_n13.csv`; `u_i_check = sd_value/SQRT(3)`. |
| Homogeneidad | `calculate_homogeneity_stats()` | `AVERAGE`, `MEDIAN`, `VAR.S`, `SUMSQ`, `SQRT`, `IF(ss_sq<0,0,...)`, MADe con `sample_2` contra `x_pt`. |
| Criterio homogeneidad | `calculate_homogeneity_criterion()` y `calculate_homogeneity_criterion_expanded()` | `0.3*sigma_pt`; tabla F1/F2 con `g` limitado a 7-20. |
| Estabilidad | `calculate_stability_stats()` | Mismo patron ANOVA; `diff_hom_stab = ABS(mean_stab - mean_hom)`. |
| Criterio estabilidad | `calculate_stability_criterion*()` | `0.3*sigma_pt`; expandido con incertidumbres de medias. |
| MADe consenso | `calculate_mad_e()` | `1.483*MEDIAN(ABS(xi-MEDIAN(xi)))`. |
| nIQR consenso | `calculate_niqr()` | `0.7413*(QUARTILE.INC(xi,3)-QUARTILE.INC(xi,1))`, validado para O3. |
| Algoritmo A | `run_algorithm_a()` | Inicializacion por mediana/MADe, reemplazo por `STDEV.S` si MADe inicial es cero, 50 iteraciones, winsorizacion, `1.134*STDEV.S`, criterio de 3 cifras significativas y guardia `1E-10`. |
| Sigma expertos | `calculate_expert_sigma_pt()` en `app.R` | Para O3, `sigma_pt = 0.020*x_pt + 1.0`; aplicar a `Referencia (1)` y `Expertos (4)`. |
| Puntajes | `compute_combo_scores()` | z, z', zeta, En; denominadores cero devuelven `N/A`; evaluaciones textuales identicas a `evaluate_*_vec()`. |
| Resumen global | `global_summary_app()` / conteos de `app.R` | `COUNTIFS` por metodo, score y categoria. |

## Heat maps

- Flujo prioritario: `global_heatmap_*`, generado por
  `render_global_score_heatmap()`.
- Metodos: `ref`, `consensus_ma`, `consensus_niqr`, `algo`, `expert`.
- Scores: `z`, `z_prime`, `zeta`, `En`.
- Orden de participantes: alfabetico por `participant_id`.
- Orden de niveles: por valor numerico extraido de `level`.
- Etiqueta visible: `sprintf("%.2f", score_value)`; en Excel usar
  `TEXT(score_value,"0.00")` cuando el valor sea numerico.
- Paleta `global_heatmap_*`:
  `Satisfactorio = #00B050`, `Cuestionable = #FFEB3B`,
  `No satisfactorio = #D32F2F`, `N/A = #BDBDBD`.
- Caso especial `En`: `app.R` define `Cuestionable = #D32F2F` aunque
  `evaluate_en_score_vec()` no produce esa categoria. Si se implementa color,
  la formula debe usar la paleta especifica de `score_heatmap_palettes$en`.
- `report_heatmaps()` queda fuera del alcance obligatorio de esta familia de
  libros. Usa otra ruta de datos y etiqueta `Insatisfactorio`, por lo que solo
  se documentara como diferencia de flujo salvo que se decida cubrir el reporte
  Word en una fase posterior.

## Tolerancias

| Tipo de dato | Tolerancia |
|---|---:|
| Calculos internos sin formato visible | `1e-8` |
| Valores visibles del snapshot a 4 decimales | `5e-4` |
| Heat maps con etiquetas a 2 decimales | `5e-3` |
| Conteos, textos y categorias | Igualdad exacta |
| Errores de formula | Cero ocurrencias de `#REF!`, `#DIV/0!`, `#VALUE!`, `#N/A`, `#NAME?` |

## Cuantiles

Para los datos O3 de homogeneidad con `replicate == 1`, la formula de Excel
`QUARTILE.INC` coincide con `stats::quantile(type = 7)`:

| Nivel | n | Q1 | Q3 | Max delta |
|---|---:|---:|---:|---:|
| `0-nmol/mol` | 10 | 0 | 0 | 0 |
| `80-nmol/mol` | 10 | 79.51575 | 80.386 | 0 |
| `180-nmol/mol` | 10 | 176.4295 | 180.404 | 0 |

Comando usado:

```sh
Rscript -e 'levels <- c("0-nmol/mol","80-nmol/mol","180-nmol/mol"); df <- read.csv("data/homogeneity - homogeneity.csv", stringsAsFactors=FALSE); for (lvl in levels) { x <- df[df$pollutant == "o3" & df$level == lvl & df$replicate == 1, "value"]; q <- as.numeric(quantile(x, c(.25,.75), type=7, names=FALSE)); n <- length(sort(x)); xs <- sort(x); excel_quart_inc <- function(p) { r <- 1 + (n - 1) * p; j <- floor(r); g <- r - j; if (j >= n) xs[n] else xs[j] + g * (xs[j+1] - xs[j]) }; qe <- c(excel_quart_inc(.25), excel_quart_inc(.75)); cat(lvl, "n=", n, "R_Q1=", format(q[1], digits=16), "Excel_Q1=", format(qe[1], digits=16), "R_Q3=", format(q[2], digits=16), "Excel_Q3=", format(qe[2], digits=16), "max_delta=", max(abs(q-qe)), "\n") }'
```

## Decisiones para Fase 2

- Crear el generador en
  `validation_1/validation/excel/validacion_o3/script_excel_formulas_validacion_o3.R`.
- Mantener los libros hardcodeados actuales como artefactos separados.
- Escribir formulas con `openxlsx::writeFormula()` y verificar resultados tras
  recalculo externo.
- Construir primero helpers de datos y comparacion contra snapshot antes de
  implementar formulas complejas como Algoritmo A.
