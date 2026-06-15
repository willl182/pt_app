# Plan: Validación de Cálculos del Aplicativo PT — O3

**Timestamp:** 260512_2102  
**Slug:** validacion-calculos-pt-app  
**Estado:** Pendiente

---

## Objetivo

Validar **cada etapa de cálculo** del aplicativo `app.R` usando datos de **O3 en 3 niveles** (bajo, medio, alto) mediante:

1. **Scripts de R** — cálculos fuera de Shiny, usando funciones de `ptcalc/`.
2. **Scripts de Python** — reimplementación independiente con NumPy/SciPy.
3. **Hojas de cálculo** — fórmulas explícitas, una hoja por cálculo, sin pestañas.

El resultado es un **informe de validación completo** donde solo se pegan capturas del aplicativo.

---

## Datos de Validación

**Fuente:** `data/for_validation/`

| Archivo | Contenido |
|---|---|
| `homogeneity_n4.csv` | Datos de homogeneidad (4 muestras × 2 réplicas) |
| `stability_n4.csv` | Datos de estabilidad (misma estructura) |
| `summary_n4.csv` | Resultados de 3 participantes + referencia |

### Niveles seleccionados (O3, por valor numérico)

| Nivel | Concentración | Corrida | Tipo |
|---|---|---|---|
| `0-nmol/mol` | 0 | corrida_1 | Bajo |
| `80-nmol/mol` | 80 | corrida_5 | Medio |
| `180-nmol/mol` | 180 | corrida_3 | Alto |

### Datos de Homogeneidad

**O3 — `0-nmol/mol` (corrida_1):**

| Item | sample_1 | sample_2 |
|------|----------|----------|
| 1 | 2.9e-5 | 2.9e-5 |
| 2 | 3.87e-5 | 2.9e-5 |
| 3 | 3.87e-5 | 4.52e-5 |
| 4 | 3.23e-5 | 5.16e-5 |

**O3 — `80-nmol/mol` (corrida_5):**

| Item | sample_1 | sample_2 |
|------|----------|----------|
| 1 | 80.00558 | 79.99473 |
| 2 | 80.19802 | 80.09170 |
| 3 | 79.75692 | 80.33275 |
| 4 | 80.07617 | 80.10092 |

**O3 — `180-nmol/mol` (corrida_3):**

| Item | sample_1 | sample_2 |
|------|----------|----------|
| 1 | 177.63742 | 178.03560 |
| 2 | 178.75095 | 178.84106 |
| 3 | 178.86328 | 178.37407 |
| 4 | 178.04786 | 178.33320 |

---

## Etapas de Cálculo a Validar

6 etapas secuenciales × 3 niveles = 18 verificaciones.

### Etapa 1: Estadísticos Robustos

**Código:** `ptcalc/R/pt_robust_stats.R` → `calculate_niqr()`, `calculate_mad_e()`

| Estadístico | Fórmula | Ref ISO 13528 |
|---|---|---|
| Mediana (x_pt) | `median(sample_1)` | Sec 9.2 |
| MAD | `median(|x_i - median(x)|)` | Sec 9.4 |
| MADe (σ_pt) | `1.483 × MAD` | Sec 9.4 |
| nIQR | `0.7413 × (Q3 - Q1)`, cuartiles `type=7` | Sec 9.4 |

---

### Etapa 2: Homogeneidad (ANOVA)

**Código:** `ptcalc/R/pt_homogeneity.R` → `calculate_homogeneity_stats()`

| Cálculo | Fórmula |
|---|---|
| Media de cada ítem | `x̄_i = (sample_1_i + sample_2_i) / 2` |
| Media general | `x̄ = mean(todas las celdas)` |
| sw | `sqrt(Σ(sample_1_i - sample_2_i)² / (2·g))` |
| s²_x̄ | `var(x̄_1, ..., x̄_g)` (denominador g-1) |
| ss | `sqrt(|s²_x̄ - sw²/m|)` |
| c (criterio MADe) | `0.3 × MADe` |
| c (criterio nIQR) | `0.3 × nIQR` |
| c_exp | Criterio expandido (usa sw, g) |
| Conclusión | `ss ≤ c` → CUMPLE |

---

### Etapa 3: Estabilidad

**Código:** `ptcalc/R/pt_homogeneity.R` → `calculate_stability_stats()`

| Cálculo | Fórmula |
|---|---|
| Media general (estabilidad) | `x̄_stab = mean(celdas estabilidad)` |
| Dmax | `|x̄_hom - x̄_stab|` |
| c_stab (MADe) | `0.3 × MADe_hom` |
| c_stab (nIQR) | `0.3 × nIQR_hom` |
| u_hom | `ss` (DE entre muestras de homogeneidad) |
| u_stab | `Dmax / sqrt(3)` |
| Conclusión | `Dmax ≤ c_stab` → CUMPLE |

---

### Etapa 4: Algoritmo A (Valor Asignado Robusto)

**Código:** `ptcalc/R/pt_robust_stats.R` → `run_algorithm_a()`

| Paso | Fórmula |
|---|---|
| Inicialización x* | `median(x_i)` |
| Inicialización s* | `1.483 × median(|x_i - median(x_i)|)` |
| δ | `1.5 × s*` |
| Winsorización | `clamp(x_i, x* - δ, x* + δ)` |
| Actualización x* | `mean(x*_i)` |
| Actualización s* | `1.134 × sd(x*_i)` (denominador p-1) |
| Convergencia | Sin cambio en 3ra cifra significativa |

> **Nota:** Con n=3 participantes el Algoritmo funciona (mínimo 3), pero en `compute_scores_for_selection` la app requiere n≥12. Se valida llamando `run_algorithm_a()` directamente.

---

### Etapa 5: Valor Consenso

**Código:** `app.R` → `observeEvent(input$consensus_run, ...)`

| Cálculo | Fórmula |
|---|---|
| x_pt(2) | `median(resultados_participantes)` |
| MAD | `median(|x_i - x_pt(2)|)` |
| σ_pt_2a (MADe) | `1.483 × MAD` |
| σ_pt_2b (nIQR) | `0.7413 × IQR(x_i)` |
| u(x_pt) 2a | `1.25 × σ_pt_2a / sqrt(n)` |
| u(x_pt) 2b | `1.25 × σ_pt_2b / sqrt(n)` |

---

### Etapa 6: Puntajes de Desempeño

**Código:** `ptcalc/R/pt_scores.R` y `app.R` → `compute_combo_scores()`

4 combinaciones de (x_pt, σ_pt): Referencia (1), Consenso MADe (2a), Consenso nIQR (2b), Algoritmo A (3).

| Puntaje | Fórmula | Criterio |
|---|---|---|
| z | `(x - x_pt) / σ_pt` | \|z\|≤2 Sat; 2<\|z\|<3 Cuest; \|z\|≥3 No sat |
| z' | `(x - x_pt) / sqrt(σ_pt² + u_xpt_def²)` | Igual que z |
| zeta (ζ) | `(x - x_pt) / sqrt(u_i² + u_xpt_def²)` | Igual que z |
| En | `(x - x_pt) / sqrt(U_xi² + U_xpt²)` | \|En\|≤1 Sat; \|En\|>1 No sat |

Donde: `u_xpt_def = sqrt(u_xpt² + u_hom² + u_stab²)`

> **Nota:** Sin archivo `pt_data_n*.csv`, los puntajes zeta y En serán NA por falta de u_i.

---

## Fases de Ejecución

### Fase 1: Datos de Prueba

| Item | Estado | Notas |
|------|--------|-------|
| Filtrar homogeneity_n4.csv para O3 × 3 niveles | Pendiente | 3 archivos CSV |
| Filtrar stability_n4.csv para O3 × 3 niveles | Pendiente | 3 archivos CSV |
| Filtrar y agregar summary_n4.csv para O3 × 3 niveles | Pendiente | 3 archivos CSV |

### Fase 2: Scripts de R

| Item | Estado | Notas |
|------|--------|-------|
| `validation/R/01_robust_stats.R` | Pendiente | Etapa 1 |
| `validation/R/02_homogeneity.R` | Pendiente | Etapa 2 |
| `validation/R/03_stability.R` | Pendiente | Etapa 3 |
| `validation/R/04_algorithm_a.R` | Pendiente | Etapa 4 |
| `validation/R/05_consensus.R` | Pendiente | Etapa 5 |
| `validation/R/06_scores.R` | Pendiente | Etapa 6 |
| `validation/R/00_run_all.R` | Pendiente | Orquestador |

### Fase 3: Scripts de Python

| Item | Estado | Notas |
|------|--------|-------|
| `validation/python/01_robust_stats.py` | Pendiente | numpy, scipy |
| `validation/python/02_homogeneity.py` | Pendiente | |
| `validation/python/03_stability.py` | Pendiente | |
| `validation/python/04_algorithm_a.py` | Pendiente | |
| `validation/python/05_consensus.py` | Pendiente | |
| `validation/python/06_scores.py` | Pendiente | |
| `validation/python/00_run_all.py` | Pendiente | Orquestador |

**Dependencias:** `numpy`, `pandas`, `scipy`  
**Nota cuartiles:** R `type=7` ≈ Python `numpy.percentile` interpolación lineal.

### Fase 4: Hojas de Cálculo

**Estrategia:** Una hoja base por etapa. Se copia por cada nivel. Sin pestañas — un archivo `.xlsx` = una sola hoja con flujo vertical.

| Item | Estado | Notas |
|------|--------|-------|
| `formulas_por_etapa.md` | Pendiente | Inventario de fórmulas Excel |
| `plantilla_base.xlsx` | Pendiente | Estructura estándar |
| `E1_robustos_o3_0.xlsx` | Pendiente | |
| `E1_robustos_o3_80.xlsx` | Pendiente | |
| `E1_robustos_o3_180.xlsx` | Pendiente | |
| `E2_homog_o3_0.xlsx` | Pendiente | |
| `E2_homog_o3_80.xlsx` | Pendiente | |
| `E2_homog_o3_180.xlsx` | Pendiente | |
| `E3_estab_o3_0.xlsx` | Pendiente | |
| `E3_estab_o3_80.xlsx` | Pendiente | |
| `E3_estab_o3_180.xlsx` | Pendiente | |
| `E4_algoA_o3_0.xlsx` | Pendiente | |
| `E4_algoA_o3_80.xlsx` | Pendiente | |
| `E4_algoA_o3_180.xlsx` | Pendiente | |
| `E5_consenso_o3_0.xlsx` | Pendiente | |
| `E5_consenso_o3_80.xlsx` | Pendiente | |
| `E5_consenso_o3_180.xlsx` | Pendiente | |
| `E6_puntajes_o3_0.xlsx` | Pendiente | |
| `E6_puntajes_o3_80.xlsx` | Pendiente | |
| `E6_puntajes_o3_180.xlsx` | Pendiente | |

**Total: 18 hojas** (6 etapas × 3 niveles) + plantilla + doc fórmulas.

**Estructura de cada hoja (flujo vertical, sin pestañas):**

```
Fila 1-3:   ENCABEZADO — Etapa, contaminante, nivel, fecha
Fila 5:     --- DATOS DE ENTRADA ---
Fila 6-N:   Datos crudos (del CSV filtrado)
Fila N+2:   --- CÁLCULOS ---
Fila N+3-M: Fórmulas explícitas referenciando celdas de datos
            (NO valores hardcodeados, solo =MEDIAN(), =ABS(), etc.)
Fila M+2:   --- RESULTADOS ---
Fila M+3:   Valor calculado en esta hoja
Fila M+4:   Valor del aplicativo (se llena manualmente)
Fila M+5:   Diferencia
Fila M+6:   VEREDICTO: PASA si coinciden en 3 cifras significativas
```

### Fase 5: Informe de Validación

| Item | Estado | Notas |
|------|--------|-------|
| `validation/informe_validacion_o3.md` | Pendiente | Pre-llenado con R/Python/Excel. Solo faltan capturas. |

El informe se entrega con **todos los valores ya calculados**. El usuario solo:
1. Ejecuta el app con los datos de O3
2. Pega capturas de pantalla en los espacios marcados `[PEGAR CAPTURA: ...]`
3. Llena la columna "App" si algún valor no se ve en la captura

**Estructura del informe:**

```
# Informe de Validación — Aplicativo PT
## O3: Niveles 0, 80, 180 nmol/mol

1. Información General
   - Fecha, versión, archivos, herramientas

2. Resumen Ejecutivo
   - Tabla PASA/FALLA por etapa × nivel (18 celdas)

3. Etapa 1 — Estadísticos Robustos
   3.1 O3 nivel 0
       - Tabla con valores: R | Python | Excel | App
       - [PEGAR CAPTURA: robustos del app]
       - Veredicto
   3.2 O3 nivel 80 (misma estructura)
   3.3 O3 nivel 180 (misma estructura)

4. Etapa 2 — Homogeneidad
   4.1 O3 nivel 0
       - Tabla ANOVA: R | Python | Excel | App
       - Conclusión CUMPLE/NO CUMPLE
       - [PEGAR CAPTURA: conclusión homogeneidad]
       - [PEGAR CAPTURA: tabla ANOVA]
       - [PEGAR CAPTURA: estadísticas MADe]
       - [PEGAR CAPTURA: estadísticas nIQR]
       - Veredicto
   4.2, 4.3 (misma estructura)

5. Etapa 3 — Estabilidad
   5.1–5.3 (misma estructura: tabla, capturas, veredicto)

6. Etapa 4 — Algoritmo A
   6.1–6.3 (misma estructura)

7. Etapa 5 — Valor Consenso
   7.1–7.3 (misma estructura)

8. Etapa 6 — Puntajes
   8.1–8.3 (misma estructura)

9. Trazabilidad
   - Cada valor → fórmula ISO + función R + celda Excel

10. Conclusión y firma
```

### Fase 6: Consolidación

| Item | Estado | Notas |
|------|--------|-------|
| Tabla comparativa R vs Python vs Excel | Pendiente | 6 etapas × 3 niveles |
| Verificación de coincidencia (3 cifras sig.) | Pendiente | Automática en scripts |
| Informe finalizado | Pendiente | Después de pegar capturas |

---

## Estructura de Archivos

```
pt_app/
└── validation/
    ├── README.md
    ├── informe_validacion_o3.md        # ENTREGABLE PRINCIPAL
    ├── data/                           # Datos filtrados (O3 × 3 niveles)
    │   ├── o3_0_hom.csv
    │   ├── o3_0_stab.csv
    │   ├── o3_0_summary.csv
    │   ├── o3_80_hom.csv
    │   ├── o3_80_stab.csv
    │   ├── o3_80_summary.csv
    │   ├── o3_180_hom.csv
    │   ├── o3_180_stab.csv
    │   └── o3_180_summary.csv
    ├── R/                              # Scripts R
    │   ├── 00_run_all.R
    │   ├── 01_robust_stats.R
    │   ├── 02_homogeneity.R
    │   ├── 03_stability.R
    │   ├── 04_algorithm_a.R
    │   ├── 05_consensus.R
    │   └── 06_scores.R
    ├── python/                         # Scripts Python
    │   ├── 00_run_all.py
    │   ├── 01_robust_stats.py
    │   ├── 02_homogeneity.py
    │   ├── 03_stability.py
    │   ├── 04_algorithm_a.py
    │   ├── 05_consensus.py
    │   └── 06_scores.py
    ├── excel/                          # Hojas (1 hoja por archivo)
    │   ├── formulas_por_etapa.md
    │   ├── plantilla_base.xlsx
    │   ├── E1_robustos_o3_0.xlsx
    │   ├── E1_robustos_o3_80.xlsx
    │   ├── E1_robustos_o3_180.xlsx
    │   ├── E2_homog_o3_0.xlsx
    │   ├── E2_homog_o3_80.xlsx
    │   ├── E2_homog_o3_180.xlsx
    │   ├── E3_estab_o3_0.xlsx
    │   ├── E3_estab_o3_80.xlsx
    │   ├── E3_estab_o3_180.xlsx
    │   ├── E4_algoA_o3_0.xlsx
    │   ├── E4_algoA_o3_80.xlsx
    │   ├── E4_algoA_o3_180.xlsx
    │   ├── E5_consenso_o3_0.xlsx
    │   ├── E5_consenso_o3_80.xlsx
    │   ├── E5_consenso_o3_180.xlsx
    │   ├── E6_puntajes_o3_0.xlsx
    │   ├── E6_puntajes_o3_80.xlsx
    │   └── E6_puntajes_o3_180.xlsx
    └── results/
        └── comparison_table.csv
```

---

## Criterios de Aceptación

| Criterio | Tolerancia |
|---|---|
| Coincidencia R vs Python vs Excel | 3 cifras significativas (ISO 13528 NOTE 1) |
| Coincidencia validación vs app.R | 3 cifras significativas |
| Clasificación de puntajes | Coincidencia exacta |
| Convergencia Algoritmo A | Mismos valores finales |
| Conclusiones homogeneidad/estabilidad | Coincidencia exacta (CUMPLE/NO CUMPLE) |

---

## Riesgos

1. **Cuartiles type=7:** R y Python pueden diferir levemente. Documentar.
2. **n=3 participantes:** Algoritmo A funciona pero ISO recomienda n≥12.
3. **u_i faltante:** Sin `pt_data_n*.csv` → zeta y En serán NA.
4. **O3 nivel 0:** Valores del orden 10⁻⁵, verificar que Excel no pierda precisión.

---

## Log de Ejecución

- [260512 21:02] Plan creado
- [260512 22:08] Reestructurado: O3 es el plan principal, no un paso previo

---

## Apéndice A: Validación Completa (5 contaminantes) — TRABAJO FUTURO

Cuando se complete la validación de O3, extender a los 5 contaminantes con la siguiente selección de niveles:

| # | Contaminante | Nivel | Datos en hom/stab |
|---|---|---|---|
| 1 | CO | `0-μmol/mol` | corrida_1 |
| 2 | SO2 | `20-nmol/mol` | corrida_5 |
| 3 | NO2 | `30-nmol/mol` | corrida_3 |
| 4 | NO | `180-nmol/mol` | corrida_4 |
| 5 | O3 | `80-nmol/mol` | corrida_5 |

Los scripts de R y Python ya estarán parametrizados para recibir cualquier contaminante/nivel. Solo se necesita:
- Generar los CSVs filtrados adicionales
- Copiar las plantillas Excel para los nuevos combos
- Expandir el informe de validación
