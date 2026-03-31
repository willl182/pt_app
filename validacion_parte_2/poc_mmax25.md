# POC MMAX25: Validación Post-Algoritmo A

**Fecha**: 2026-03-30
**Estado**: draft
**Autor**: mmx25 (POC - Proof of Concept)

## Resumen Ejecutivo

Este documento establece el plan de implementación para validar todos los cálculos posteriores al Algoritmo A (winsorización iterativa) en la aplicación PT. Se implementarán los planes A1 y A2 de forma unificada, generando una validación tripartita: **app.R** vs **script R independiente** vs **Excel de validación**.

## Objetivos

1. Validar la cadena completa de cálculos downstream del Algoritmo A
2. Comparar 3 fuentes: app.R, código R independiente, Excel
3. Cubrir 15 combinaciones (niveles 1, 3, 5 de cada contaminante)
4. Generar documentación de validación reproducible

## Combinaciones Objetivo

Fijadas según plan A2:

| Contaminante | Nivel 1 | Nivel 3 | Nivel 5 |
|---|---|---|---|
| CO | `0-μmol/mol` | `4-μmol/mol` | `8-μmol/mol` |
| NO | `0-nmol/mol` | `81-nmol/mol` | `121-nmol/mol` |
| NO2 | `0-nmol/mol` | `60-nmol/mol` | `120-nmol/mol` |
| O3 | `0-nmol/mol` | `80-nmol/mol` | `180-nmol/mol` |
| SO2 | `0-nmol/mol` | `60-nmol/mol` | `100-nmol/mol` |

## Métricas a Validar

### Sección 1: Estadísticos Robustos
- Mediana, MAD, MADe, Q1, Q3, IQR, nIQR
- Referencia: `R/pt_robust_stats.R`

### Sección 2: Homogeneidad
- σ_pt (MADe_hom), u(σ_pt), c criterio, c expandido
- Evaluación: ss ≤ c
- Referencia: `R/pt_homogeneity.R`

### Sección 3: Estabilidad
- d_max, c criterio, u_stab
- Evaluación: d_max ≤ c
- Referencia: `R/pt_homogeneity.R`

### Sección 4: Incertidumbres
| Parámetro | Método Referencia | Método MADe | Método nIQR | Método Algoritmo A |
|---|---|---|---|---|
| x_pt | mean(ref) | median | median | algo_res$assigned_value |
| σ_pt | MADe_hom | 1.483×MAD | nIQR | algo_res$robust_sd |
| u_xpt | 1.25×MADe/√g | 1.25×σ_pt/√n | 1.25×σ_pt/√n | 1.25×s*/√n |
| u_hom | ss | ss | ss | ss |
| u_stab | d_max/√3 | d_max/√3 | d_max/√3 | d_max/√3 |
| u_xpt_def | √(u_xpt²+u_hom²+u_stab²) | ... | ... | ... |
| U_xpt | k×u_xpt_def | ... | ... | ... |

### Sección 5: Puntajes de Desempeño
- z = (x - x_pt) / σ_pt
- z' = (x - x_pt) / √(σ_pt² + u_xpt_def²)
- ζ = (x - x_pt) / √(u_x² + u_xpt_def²)
- En = (x - x_pt) / √(U_xi² + U_xpt²)

Evaluaciones:
- z, z', ζ: |score| ≤ 2 → "Satisfactorio", 2 < |score| < 3 → "Cuestionable", |score| ≥ 3 → "No satisfactorio"
- En: |En| ≤ 1 → "Satisfactorio", |En| > 1 → "No satisfactorio"

## Arquitectura de Implementación

### Estructura de Archivos

```
validation/
├── generate_post_algoA_validation.R      # Script R principal
├── generate_post_algoA_validation.py    # Script Python (verificación cruzada)
├── A2_CO_0_umol.xlsx                     # 15 archivos de validación
├── A2_CO_4_umol.xlsx
├── ...
└── A2_SO2_100_nmol.xlsx
```

### Columnas de Comparación (por cada métrica)

| Columna | Descripción |
|---------|-------------|
| app_value | Valor extraído de app.R |
| r_value | Valor calculado con script R independiente |
| excel_value | Valor en hoja Excel |
| diff_app_r | app_value - r_value |
| diff_app_excel | app_value - excel_value |
| diff_r_excel | r_value - excel_value |
| status | PASS/FAIL según tolerancia |

### Tolerancias

- `1e-12` para R vs Excel (fórmula exacta)
- `1e-9` para agregados o cadenas con redondeo acumulado
- Equality exacta para etiquetas de evaluación

## Plan de Implementación (Orden de Ejecución)

### Fase 1: Extracción de Datos desde app.R
1. Crear script que replique lógica de `compute_scores_for_selection()` en app.R
2. Extraer: x_pt, σ_pt, u_xpt, u_hom, u_stab, u_xpt_def, U_xpt
3. Extraer: z, z', ζ, En por participante
4. Extraer: evaluaciones cualitativas

### Fase 2: Script R Independiente
1. Implementar funciones puras para cada métrica
2. Usar los mismos datos de entrada
3. Calcular valores independientes
4. Generar tabla de comparación

### Fase 3: Generación Excel
1. Por cada combinación (15 archivos):
   - Hoja 00_input: datos fuente
   - Hoja 01_algorithm_a_feed: serie agregada
   - Hoja 02_uncertainty_chain: incertidumbres
   - Hoja 03_scores: puntajes
   - Hoja 04_global_checks: agregados downstream
   - Hoja 05_comparison: comparación trifuente

### Fase 4: Verificación Python (Opcional)
1. Reimplementar fórmulas en Python
2. Comparar contra R independiente
3. Documentar discrepancias

## Criterios de Aceptación

La implementación será exitosa si:

1. ✅ Las 15 combinaciones se resuelven sin ambigüedad desde summary_n13.csv
2. ✅ La lógica de app.R se reproduce exactamente para la cadena downstream
3. ✅ Se generan 15 workbooks válidos (uno por combinación)
4. ✅ Cada workbook contiene las 6 hojas especificadas
5. ✅ Coinciden: x_pt, σ_pt, u_xpt, u_hom, u_stab, u_xpt_def, U_xpt
6. ✅ Coinciden: z, z', ζ, En por participante
7. ✅ Coinciden las evaluaciones cualitativas
8. ✅ El resumen maestro no reporta FAIL

## Casos Especiales a Documentar

- **Nivel 0**: Los niveles `0-*` pueden producir σ_pt ≈ 0, generando NA en puntajes
- **Discrepancia u_stab**: app.R calcula u_stab = d_max/√3 incondicionalmente, mientras que `calculate_u_stab()` en pt_homogeneity.R retorna 0 si el criterio se cumple. Se usará comportamiento de app.R.

## Referencias

- ISO 13528:2022 - Statistical methods for proficiency testing
- ISO 17043:2024 - Requirements for proficiency testing
- `plan_a2.md` - Plan original
- `logs/plans/260330_1118_plan_a1_validacion_post_algoA.md` - Plan detallado A1
- `val_a/VAL_mmx25/validate_algorithm_a_crosscheck.R` - Script de referencia
