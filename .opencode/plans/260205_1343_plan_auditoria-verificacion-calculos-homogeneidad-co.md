# Plan: Verificación de Cálculos de Auditoría - CO 0-μmol/mol

**Timestamp:** 260205_1343  
**Slug:** auditoria-verificacion-calculos-homogeneidad-co  
**Estado:** En progreso

## Objetivo
Replicar y verificar los cálculos del archivo de auditoría `data/Homogenidad y estabilidad.xlsx` para CO 0-μmol/mol, identificar discrepancias con las fórmulas ISO 13528:2022, y comparar con las implementaciones del aplicativo.

## Hallazgos Preliminares

### Datos del Archivo de Auditoría (CO 0-μmol/mol):

| Estadístico | Valor Reportado | Notas |
|-------------|-----------------|-------|
| g (muestras) | 10 | |
| m (réplicas) | 2 | |
| Promedio general | -0.0204 | |
| sx (SD promedios) | 0.0184 | |
| sw (SD intra-muestras) | 0.0362 | |
| σpt | 0.00579 | **Sospechoso: muy pequeño vs variabilidad** |

### Problema Potencial Identificado en Código:

En `R/pt_homogeneity.R:89-96`:
```r
abs_diff_from_xpt <- abs(sample_data[, 2] - x_pt)  # Solo columna 2
sigma_pt <- stats::median(abs_diff_from_xpt, na.rm = TRUE)
MADe <- 1.483 * sigma_pt
```

**Problema:** Calcula diferencias de la 2da réplica vs mediana de 1ra réplica, NO el MADe correcto según ISO 13528.

**ISO 13528:2022 dice:** MADe = 1.483 × median(|xi - median(xi)|) sobre TODOS los valores o sobre promedios de muestras

---

## Fases

### Fase 1: Extracción y Organización de Datos Crudos
| Item | Estado | Notas |
|------|--------|-------|
| Extraer datos crudos del archivo de auditoría | Pendiente | |
| Identificar los 10 sample_ids y sus 2 réplicas | Pendiente | |
| Verificar datos de estabilidad | Pendiente | |

### Fase 2: Replicar Cálculos de Homogeneidad
| Item | Estado | Notas |
|------|--------|-------|
| Calcular promedios de cada muestra (xt) | Pendiente | |
| Calcular promedio general | Pendiente | Verificar vs -0.0204 |
| Calcular sx = SD(promedios de muestras) | Pendiente | Verificar vs 0.0184 |
| Calcular sw (fórmula ISO para m=2) | Pendiente | Verificar vs 0.0362 |
| Calcular ss = sqrt(sx² - sw²/m) | Pendiente | |
| Calcular MADe correcto | Pendiente | |
| Verificar σpt | Pendiente | Verificar vs 0.00579 |

### Fase 3: Verificar Criterio de Homogeneidad
| Item | Estado | Notas |
|------|--------|-------|
| Calcular c = 0.3 × σpt | Pendiente | |
| Verificar ss ≤ c | Pendiente | |

### Fase 4: Replicar Cálculos de Estabilidad
| Item | Estado | Notas |
|------|--------|-------|
| Calcular promedio de estabilidad | Pendiente | |
| Calcular D = |media_estab - media_hom| | Pendiente | |
| Verificar D ≤ 0.3 × σpt | Pendiente | |

### Fase 5: Comparar con Implementación del App
| Item | Estado | Notas |
|------|--------|-------|
| Ejecutar calculate_homogeneity_stats() con datos CO | Pendiente | |
| Comparar resultados vs archivo de auditoría | Pendiente | |

### Fase 6: Documentar Hallazgos y Correcciones
| Item | Estado | Notas |
|------|--------|-------|
| Crear tabla comparativa | Pendiente | |
| Proponer correcciones | Pendiente | |

---

## Log de Ejecución
- [260205 13:43] Plan creado - investigación preliminar completada
- [260205 14:XX] Fase 1 completada - datos extraídos y guardados en data/audit_homog_data.rds y data/audit_stab_data.rds
- [260205 14:XX] Fase 2 completada - HALLAZGO CRÍTICO:

### Resultados Fase 2:
| Estadístico | Auditoría | Calculado | Estado |
|-------------|-----------|-----------|--------|
| Promedio general | -0.02042 | -0.02042 | ✓ COINCIDE |
| sx (SD promedios) | 0.01836 | 0.01836 | ✓ COINCIDE |
| sw (SD intra) | 0.03623 | 0.03623 | ✓ COINCIDE |
| ss (SD entre) | (no reportado) | 0.01786 | - |
| σpt | 0.00579 | ??? | ⚠ PROBLEMA |

### Análisis σpt:
El valor σpt = 0.00579 NO coincide con ningún cálculo estándar ISO 13528:
- MADe (todos valores): 0.04009
- MADe (promedios): 0.00162
- nIQR (todos valores): 0.04014
- nIQR (promedios): 0.00142

**Origen probable:** Valor prescrito externamente (no calculado de los datos)
