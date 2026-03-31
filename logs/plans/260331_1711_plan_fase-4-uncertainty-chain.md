# Plan: Fase 4 — Cadena de Incertidumbre

**Timestamp:** 260331_1711
**Slug:** fase-4-uncertainty-chain
**Estado:** En progreso

---

## Objetivo

Validar la cadena completa de propagación de incertidumbres, con comparación tripartita (app.R vs R independiente vs Python) para los 15 combos objetivo y 4 métodos de cálculo.

---

## Contexto

### Fuente de datos

- `data/summary_n13.csv` — datos de participantes
- Resultados de Etapas 1-3 en `validation/outputs/`:
  - `stage_01_robust_stats.csv` — estadísticos robustos (MADe, nIQR, Algoritmo A)
  - `stage_02_homogeneity.csv` — ss (u_hom), sw, criterios
  - `stage_03_stability.csv` — Dmax, u_stab, criterios expandidos

### Dependencias de etapas anteriores

La cadena de incertidumbre necesita datos de las 3 etapas anteriores:
- **Etapa 1:** x_pt, sigma_pt, n_part por método
- **Etapa 2:** u_hom = ss (desviación estándar entre-muestras de homogeneidad)
- **Etapa 3:** u_stab = Dmax / sqrt(3) (incertidumbre por estabilidad)

Se leen de los CSVs intermedios de cada etapa.

### Lógica efectiva en app.R

| Función | Archivo | Línea | Descripción |
|---------|---------|-------|-------------|
| `compute_combo_scores()` | `app.R` | 2328-2395 | Calcula cadena completa por combo |
| Cálculo u_xpt_def | `app.R` | 772, 2329 | sqrt(u_xpt^2 + u_hom^2 + u_stab^2) |
| Cálculo U_xpt | `app.R` | 796, 2359 | k * u_xpt_def |

### Fórmulas (ISO 13528:2022)

| Métrica | Fórmula | Fuente app.R |
|---------|---------|--------------|
| `x_pt` | Valor asignado por método | Etapa 1 |
| `sigma_pt` | DE para puntajes por método | Etapa 1 |
| `n_part` | Número de participantes | Etapa 1 |
| `u_xpt` | `1.25 * sigma_pt / sqrt(n_part)` | Líneas 472, 601 |
| `u_hom` | `ss` (DE entre-muestras homogeneidad) | Etapa 2 |
| `u_stab` | `Dmax / sqrt(3)` | Etapa 3, línea 1676 |
| `u_xpt_def` | `sqrt(u_xpt^2 + u_hom^2 + u_stab^2)` | Líneas 772, 2329 |
| `U_xpt` | `k * u_xpt_def` (k=2) | Líneas 796, 2359 |

### Métodos validados (4 por combo)

| # | Método | x_pt | sigma_pt | Fuente |
|---|--------|------|----------|--------|
| 1 | Referencia | x_pt_ref | sigma_pt_ref | app.R: lógica específica |
| 2 | Consenso MADe | Mediana | sigma_pt_2a (MADe normalizado) | Etapa 1 |
| 3 | Consenso nIQR | Mediana | sigma_pt_2b (nIQR) | Etapa 1 |
| 4 | Algoritmo A | Algo A assigned | Algo A robust_sd | Etapa 1 |

### Métricas a validar (7 por combo por método)

| # | Métrica | Descripción |
|---|---------|-------------|
| 1 | x_pt | Valor asignado |
| 2 | sigma_pt | DE para puntajes |
| 3 | u_xpt | Incertidumbre estándar de x_pt |
| 4 | u_hom | Incertidumbre por homogeneidad |
| 5 | u_stab | Incertidumbre por estabilidad |
| 6 | u_xpt_def | Incertidumbre combinada |
| 7 | U_xpt | Incertidumbre expandida (k=2) |

**Total:** 15 combos × 4 métodos × 7 métricas = **420 comparaciones**

### Diferencia crítica: cálculo de u_stab

En `app.R:1676`:
```r
u_stab <- d_max / sqrt(3)
```

Donde `d_max` es la diferencia absoluta entre las medias de homogeneidad y estabilidad (diff_hom_stab de Etapa 3).

**Nota:** Si diff_hom_stab = 0 (como en este dataset), entonces u_stab = 0 para todos los combos.

### Flujo en app.R

1. Cargar datos de participantes de `summary_n13.csv`
2. Para cada combo, obtener resultados de Etapas 1-3
3. Para cada método (referencia, consenso MADe, consenso nIQR, Algoritmo A):
   - Obtener x_pt y sigma_pt del método
   - Obtener n_part del combo
   - Calcular u_xpt = 1.25 * sigma_pt / sqrt(n_part)
   - Obtener u_hom = ss de Etapa 2
   - Obtener u_stab = Dmax / sqrt(3) de Etapa 3
   - Calcular u_xpt_def = sqrt(u_xpt^2 + u_hom^2 + u_stab^2)
   - Calcular U_xpt = k * u_xpt_def (k=2)
4. Comparar valores app vs R vs Python

---

## Fases

### Fase 4.1: Lectura de datos de etapas anteriores

| Item | Estado | Notas |
|------|--------|-------|
| Cargar resultados Etapa 1 (robust stats) | Pendiente | Leer stage_01_robust_stats.csv |
| Cargar resultados Etapa 2 (homogeneidad) | Pendiente | Leer stage_02_homogeneity.csv |
| Cargar resultados Etapa 3 (estabilidad) | Pendiente | Leer stage_03_stability.csv |
| Cargar datos de participantes | Pendiente | Leer summary_n13.csv |
| Validar estructura de datos | Pendiente | Verificar columnas necesarias |

### Fase 4.2: Cálculo independiente en R

| Item | Estado | Notas |
|------|--------|-------|
| Implementar carga de datos por combo | Pendiente | Reusar helpers existentes |
| Calcular x_pt por método | Pendiente | 4 métodos |
| Calcular sigma_pt por método | Pendiente | 4 métodos |
| Calcular n_part por combo | Pendiente | Del CSV de participantes |
| Calcular u_xpt = 1.25 * sigma_pt / sqrt(n_part) | Pendiente | Fórmula app.R |
| Obtener u_hom de Etapa 2 | Pendiente | ss de homogeneidad |
| Obtener u_stab de Etapa 3 | Pendiente | Dmax / sqrt(3) |
| Calcular u_xpt_def = sqrt(u_xpt^2 + u_hom^2 + u_stab^2) | Pendiente | Fórmula app.R |
| Calcular U_xpt = k * u_xpt_def (k=2) | Pendiente | Fórmula app.R |
| Generar filas canónicas por combo/método | Pendiente | 7 métricas × 4 métodos |

### Fase 4.3: Cálculo independiente en Python

| Item | Estado | Notas |
|------|--------|-------|
| Implementar todas las fórmulas anteriores | Pendiente | Mismo orden, misma lógica |
| Cargar resultados de etapas anteriores (Python) | Pendiente | Leer CSVs intermedios |
| Validar contra resultados R | Pendiente | Tolerancia 1e-9 |

### Fase 4.4: Comparación tripartita

| Item | Estado | Notas |
|------|--------|-------|
| Generar filas canónicas por combo/método | Pendiente | 7 métricas × 4 métodos × 15 combos |
| Aplicar tolerancia 1e-9 | Pendiente | Para valores continuos |
| Clasificar PASS/FAIL | Pendiente | |
| Identificar EDGE_CASE | Pendiente | Combos con datos faltantes |

### Fase 4.5: Outputs

| Item | Estado | Notas |
|------|--------|-------|
| Generar `outputs/stage_04_uncertainty_chain.csv` | Pendiente | Tabla canónica |
| Generar `outputs/stage_04_uncertainty_chain_report.md` | Pendiente | Con resumen PASS/FAIL |

### Fase 4.6: Reporte de etapa

| Item | Estado | Notas |
|------|--------|-------|
| Incluir combos procesados | Pendiente | 15 combos |
| Incluir métodos evaluados | Pendiente | 4 métodos |
| Incluir métricas evaluadas | Pendiente | 7 métricas |
| Incluir conteo PASS/FAIL | Pendiente | Máximo 420 comparaciones |

---

## Riesgos y consideraciones

| Riesgo | Mitigación |
|--------|------------|
| Datos faltantes en etapas anteriores | Verificar existencia de CSVs antes de procesar |
| u_stab = 0 para todos (diff_hom_stab = 0) | Documentar comportamiento esperado |
| Diferencias en fórmula u_xpt (1.25 vs otro) | Usar 1.25 como en app.R |
| Métodos con sigma_pt NA (Algoritmo A) | Manejar NA explícitamente |
| Tolerancia muy estricta para diferencias numéricas | Usar 1e-9 como fases anteriores |

---

## Criterio de cierre

La Fase 4 está cerrada cuando:
1. Los 15 combos se procesan correctamente para los 4 métodos
2. Las 7 métricas se calculan correctamente en R y Python
3. Todas las métricas coinciden dentro de tolerancia (1e-9)
4. u_xpt_def se calcula correctamente como sqrt(u_xpt^2 + u_hom^2 + u_stab^2)
5. U_xpt = k * u_xpt_def se calcula correctamente
6. Existe CSV de salida con tabla canónica
7. Existe reporte Markdown con resumen PASS/FAIL

---

## Log de Ejecución

- [260331 17:11] Plan creado — cadena de incertidumbre
