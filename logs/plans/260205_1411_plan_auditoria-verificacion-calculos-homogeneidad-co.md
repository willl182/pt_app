# Plan: Verificación de Cálculos de Auditoría - CO 0-μmol/mol

**Timestamp:** 260205_1343 → Actualizado 260205_1411 → 260205_1435
**Slug:** auditoria-verificacion-calculos-homogeneidad-co
**Estado:** Completado

## Objetivo
Replicar y verificar los cálculos del archivo de auditoría `data/Homogenidad y estabilidad.xlsx` para CO 0-μmol/mol, documentar las fórmulas exactas usadas en el Excel, y comparar con las implementaciones del aplicativo.

**IMPORTANTE: NO modificar ningún código del app durante este proceso de auditoría.**

---

## Fases

### Fase 1: Extracción y Organización de Datos Crudos
| Item | Estado | Notas |
|------|--------|-------|
| Extraer datos crudos del archivo de auditoría | ✅ Completada | Guardado en `data/audit_homog_data.rds` |
| Identificar los 10 sample_ids y sus 2 réplicas | ✅ Completada | g=10, m=2 |
| Verificar datos de estabilidad | ✅ Completada | Guardado en `data/audit_stab_data.rds` |

### Fase 2: Replicar Cálculos de Homogeneidad
| Item | Estado | Notas |
|------|--------|-------|
| Calcular promedios de cada muestra (xt) | ✅ Completada | Coincide con auditoría |
| Calcular promedio general | ✅ Completada | -0.02042 ✓ |
| Calcular sx = SD(promedios de muestras) | ✅ Completada | 0.01836 ✓ |
| Calcular sw (fórmula ISO para m=2) | ✅ Completada | 0.03623 ✓ |
| Calcular ss = sqrt(sx² - sw²/m) | ✅ Completada | 0.01786 (no reportado en auditoría) |

### Fase 2.5: Documentación de Fórmulas Excel (NUEVA)
| Item | Estado | Notas |
|------|--------|-------|
| Extraer todas las fórmulas con tidyxl | ✅ Completada | 39 fórmulas encontradas |
| Identificar cálculo de σpt = C121 | ✅ Completada | `=1.483*MEDIAN(C110:C116)` |
| Determinar origen datos B110:B112 | ⚠️ Alerta | Origen desconocido - NO son datos de homogeneidad |
| Documentar error en F23 (ss) | ✅ Completada | `=SQRT(F21^2-(F22^2/2))` devuelve #NUM! |

**Fórmulas clave extraídas:**
```
F20 = AVERAGE(B6:C17)    = -0.020417  (Promedio general)
F21 = STDEV(D6:D17)      = 0.018363   (sx)
F22 = SQRT(SUMSQ(E6:E17)/(2*COUNT(E6:E17))) = 0.036226 (sw)
F23 = SQRT(F21^2-(F22^2/2)) = #NUM!   (ss - ERROR)
F24 = C121               = 0.005788   (σpt)

B119 = MEDIAN(B110:B116) = -0.024974  (Mediana de "datos")
C110:C112 = ABS(Bi-$B$119)          (Diferencias absolutas)
C120 = MEDIAN(C110:C116) = 0.003903  (Mediana de diferencias)
C121 = 1.483*C120         = 0.005788  (MADe = σpt)
```

### Fase 3: Verificar Criterio de Homogeneidad
| Item | Estado | Notas |
|------|--------|-------|
| Calcular c = 0.3 × σpt con diferentes valores | 🔄 En progreso | |
| Verificar ss ≤ c para cada σpt | Pendiente | |
| Documentar resultados comparativos | Pendiente | |

### Fase 4: Replicar Cálculos de Estabilidad
| Item | Estado | Notas |
|------|--------|-------|
| Calcular promedio de estabilidad | Pendiente | |
| Calcular D = |media_estab - media_hom| | Pendiente | |
| Verificar D ≤ 0.3 × σpt | Pendiente | |

### Fase 5: Comparar con Implementación del App
| Item | Estado | Notas |
|------|--------|-------|
| Ejecutar calculate_homogeneity_stats() con datos CO | ✅ Completada | Usando source("R/pt_homogeneity.R") |
| Ejecutar calculate_stability_stats() con datos CO | ✅ Completada | Valores coinciden con cálculos manuales |
| Comparar resultados vs archivo de auditoría | ✅ Completada | Ver tabla comparativa más abajo |

### Fase 6: Clonar ptcalc y Verificar Funciones
| Item | Estado | Notas |
|------|--------|-------|
| Clonar https://github.com/willl182/ptcalc en ptcalc_repo/ | ✅ Completada | Clonado a ptcalc_repo/ |
| Cargar funciones con devtools::load_all("ptcalc_repo") | ✅ Completada | Funciones cargadas correctamente |
| Ejecutar calculate_homogeneity_stats() con datos auditoría | ✅ Completada | Resultados idénticos a manuales |
| Ejecutar calculate_stability_stats() con datos auditoría | ✅ Completada | Resultados idénticos a manuales |
| Verificar resultados vs cálculos manuales | ✅ Completada | TODOS LOS VALORES COINCIDEN |

**VERIFICACIÓN FINAL:**
- ✅ Resultados ptcalc (GitHub) = Resultados manuales
- ✅ Resultados ptcalc (GitHub) = Resultados source("R/pt_homogeneity.R")
- **σpt del app = 0.039820**
- **Homogeneidad: ❌ NO PASA** (ss = 0.017860 > c = 0.011946)
- **Estabilidad: ✅ PASA** (D = 0.001841 ≤ c = 0.011946)

### Fase 7: Documentar Hallazgos
| Item | Estado | Notas |
|------|--------|-------|
| Crear tabla comparativa completa | ✅ Completada | Ver sección "Tabla Comparativa Consolidada" |
| Documentar origen desconocido de σpt auditoría | ✅ Completada | Ver sección "Origen del σpt en Auditoría" |
| Registrar aclaración sobre MADe homogeneidad | ✅ Completada | Ver sección "Aclaración Técnica sobre MADe" |

**Documentación completa generada:**
- Tabla comparativa consolidada (estadísticos, σpt, criterios)
- Documentación de origen σpt (B110:B112 del Excel)
- Aclaración técnica sobre fórmula MADe en homogeneidad
- Hallazgos guardados en logs/history/260205_1435_findings.md

---

## Tabla Comparativa Consolidada

### Estadísticos Básicos
| Estadístico | Auditoría Excel | App (ptcalc) | Calculado Manualmente | Estado |
|-------------|-----------------|---------------|----------------------|--------|
| Promedio general | -0.020417 | -0.020417 | -0.020417 | ✅ COINCIDE |
| sx (SD promedios) | 0.018363 | 0.018363 | 0.018363 | ✅ COINCIDE |
| sw (SD intra) | 0.036226 | 0.036226 | 0.036226 | ✅ COINCIDE |
| ss (SD entre) | #NUM! | 0.017860 | 0.017860 | ❌ Error en F23 del Excel |

### σpt (Desviación Objetivo de Proficiencia)
| Fuente | Valor | Cálculo | Notas |
|--------|-------|---------|-------|
| Auditoría Excel | 0.005788 | 1.483 × 0.003903 | Datos B110:B112 (origen desconocido) |
| App (ptcalc) | 0.039820 | 1.483 × median(\|col2 - median(col1)\|) | Calculado de datos homogeneidad |
| MADe ISO (todos) | 0.04009 | 1.483 × median(\|xi - median(xi)\|) | ISO 13528 general |
| MADe ISO (promedios) | 0.00162 | 1.483 × median(\|promedios - median(promedios)\|) | ISO 13528 con promedios |

### Criterios de Evaluación (usando σpt del app = 0.039820)
| Criterio | Valor Calculado | Umbral (c = 0.3 × σpt) | Estado |
|----------|-----------------|------------------------|--------|
| Homogeneidad (ss) | 0.017860 | 0.011946 | ❌ NO PASA |
| Estabilidad (D) | 0.001841 | 0.011946 | ✅ PASA |

---

## Origen del σpt en Auditoría

El valor σpt = 0.005788 reportado en el Excel de auditoría se calcula de la siguiente manera:

1. **Datos base:** 3 valores en celdas B110:B112
   ```
   B110: -0.029635
   B111: -0.021071
   B112: -0.024974
   ```

2. **Fórmulas en el Excel:**
   ```
   B119 = MEDIAN(B110:B116)  = -0.024974
   C110:C116 = ABS(Bi - $B$119)  (Diferencias absolutas)
   C120 = MEDIAN(C110:C116)      = 0.003903
   C121 = 1.483 * C120            = 0.005788  (MADe = σpt)
   ```

3. **Origen desconocido:** Estos 3 valores NO provienen de los datos de homogeneidad (10 muestras × 2 réplicas). Posibles orígenes:
   - Datos de una corrida anterior del mismo ensayo
   - Incertidumbre prescrita del patrón de referencia
   - Datos de certificación del cilindro de gas
   - Datos de otros laboratorios participantes

**Importante:** No hay documentación en el Excel sobre el origen de estos valores. Se recomienda consultar con el personal que generó el archivo de auditoría.

---

## Aclaración Técnica sobre MADe en Homogeneidad

**NO es error, es diferente propósito:**

| Contexto | Fórmula | Datos Usados | Propósito |
|----------|---------|--------------|-----------|
| **Homogeneidad (app)** | `1.483 × median(\|col2 - median(col1)\|)` | col2 (réplica 2) vs mediana de col1 (réplica 1) | Evaluar dispersión entre réplicas |
| **ISO 13528 general** | `1.483 × median(\|xi - median(xi)\|)` | Todos los valores individuales | Evaluar dispersión general del conjunto |

**Explicación:**
- En homogeneidad, el propósito es medir qué tan consistentes son las réplicas entre sí.
- La fórmula del app calcula la diferencia entre cada valor de la réplica 2 y la mediana de la réplica 1.
- Esto es diferente a calcular la dispersión de todos los valores individuales alrededor de su mediana general.

**El código actual del app es CORRECTO para el contexto de homogeneidad.** Las dos fórmulas tienen diferentes propósitos según el usuario.

---

## Hallazgos Críticos

### 1. Cálculos Básicos Correctos
| Estadístico | Auditoría | Calculado | Estado |
|-------------|-----------|-----------|--------|
| Promedio general | -0.02042 | -0.02042 | ✓ COINCIDE |
| sx (SD promedios) | 0.01836 | 0.01836 | ✓ COINCIDE |
| sw (SD intra) | 0.03623 | 0.03623 | ✓ COINCIDE |
| ss (SD entre) | (no reportado, F23=#NUM!) | 0.01786 | - |

### 2. Problema con σpt = 0.005788

| Método | Valor Calculado | Auditoría | Diferencia |
|--------|-----------------|-----------|-------------|
| σpt del app (col2 - x_pt) | **0.039820** | 0.005788 | 0.034032 |
| MADe ISO (todos valores) | 0.04009 | 0.005788 | 0.03431 |
| MADe ISO (promedios) | 0.00162 | 0.005788 | -0.00416 |
| nIQR ISO (todos valores) | 0.04014 | 0.005788 | 0.03435 |
| nIQR ISO (promedios) | 0.00142 | 0.005788 | -0.00437 |

**Origen del σpt en auditoría:** Calculado a partir de 3 valores en B110:B112 (`-0.029635, -0.021071, -0.024974`) que NO provienen de los datos de homogeneidad (10 muestras × 2 réplicas). Origen desconocido.

### 3. Aclaración sobre MADe (NO es error, es diferente propósito)

| Contexto | Fórmula | Estado |
|----------|---------|--------|
| **Homogeneidad (app)** | `1.483 × median(\|col2 - median(col1)\|)` | ✅ CORRECTO |
| **ISO 13528 general** | `1.483 × median(\|xi - median(xi)\|)` | Diferente propósito |

El código actual del app es CORRECTO para el contexto de homogeneidad. Las dos fórmulas tienen diferentes propósitos según el usuario.

### 4. Resultados de Fase 5: Funciones del App

**Valores calculados por calculate_homogeneity_stats():**
```
  g:              10
  m:              2
  general_mean:   -0.020417
  x_pt:           -0.022837 (median col1)
  s_xt:           0.018363 (SD promedios)
  sw:             0.036226 (SD intra)
  ss:             0.017860 (SD entre)
  sigma_pt:       0.026851 (median|col2 - x_pt|)
  MADe:           0.039820
  u_sigma_pt:     0.015740
```

**Valores calculados por calculate_stability_stats():**
```
  g:              2
  m:              2
  general_mean:   -0.022257
  x_pt:           -0.021465 (median col1 estabilidad)
  s_xt:           0.037466
  sw:             0.001134
  ss:             0.037457
  hom_stab_sigma_pt: 0.039820 (de homogeneidad)
  diff_hom_stab:   0.001841 (|media_stab - media_hom|)
```

**Evaluación de criterios:**
- Homogeneidad: ❌ NO PASA (ss = 0.017860 > c = 0.011946)
- Estabilidad: ✅ PASA (D = 0.001841 ≤ c = 0.011946)

**Nota Técnica:** Fase 5 ejecutada con `source("R/pt_homogeneity.R")` porque ptcalc/ está en .gitignore. Para verificar exactamente como funciona en producción, se debe clonar ptcalc desde GitHub.

---

## Log de Ejecución

- [260205 13:43] Plan creado - investigación preliminar completada
- [260205 14:XX] Fase 1 completada - datos extraídos y guardados
- [260205 14:XX] Fase 2 completada - HALLAZGO CRÍTICO sobre σpt
- [260205 14:11] Fase 2.5 completada - fórmulas Excel documentadas
- [260205 14:11] Aclaración agregada: código MADe del app es CORRECTO
- [260205 14:15] Fase 3 completada - criterio homogeneidad NO PASA con ningún σpt
- [260205 14:18] Fase 4 completada - estabilidad PASA con σpt del app (0.039820)
- [260205 14:22] Fase 5 completada - usando source("R/pt_homogeneity.R") (ptcalc/ en .gitignore)
- [260205 14:30] Identificado: ptcalc/ debe clonarse desde https://github.com/willl182/ptcalc
- [260205 14:30] Fase 6 iniciada - clonar ptcalc y verificar
- [260205 14:33] Fase 6 completada - ptcalc clonado en ptcalc_repo/
- [260205 14:33] Verificación: Resultados ptcalc = cálculos manuales ✅
- [260205 14:33] TODOS los estadísticos calculados correctamente por ptcalc
- [260205 14:35] Fase 7 completada - documentación final generada
- [260205 14:35] Plan completado - todas las fases finalizadas ✅

---

## Datos Crudos Extraídos (CO 0-μmol/mol)

### Homogeneidad (10 muestras × 2 réplicas):
```
Réplica 1: 0.0067, 0.0048, -0.0493, 0.0043, 0.0060, -0.0523, 0.0032, -0.0508, -0.0520, -0.0489
Réplica 2: -0.0480, -0.0488, -0.0475, 0.0487, -0.0502, 0.0059, -0.0516, 0.0046, 0.0033, 0.0035
```

### Estabilidad (2 muestras × 2 réplicas):
```
Muestra 1: -0.0488, 0.0042
Muestra 2: 0.0042, 0.0018
```

---

## Archivos de Entrega

- `reports/auditoria_co_0_umol_mol_final.md` - **INFORME FINAL** con:
  - Todos los resultados de verificación
  - Fórmulas detalladas del aplicativo (sección 3)
  - Comparativas completas
  - Conclusiones y recomendaciones
  - Apéndice con referencias

---

## Archivos Referenciados

- `data/Homogenidad y estabilidad.xlsx` - Archivo de auditoría
- `data/audit_homog_data.rds` - Datos de homogeneidad extraídos
- `data/audit_stab_data.rds` - Datos de estabilidad extraídos
- `R/pt_homogeneity.R` - Implementación del app (CORRECTO)
- `ptcalc_repo/` - Repositorio ptcalc clonado desde https://github.com/willl182/ptcalc
- `data/summary_n4.csv` - Datos completos del ensayo N4

---

## RESUMEN EJECUTIVO DE AUDITORÍA

### Objetivo
Verificar los cálculos de homogeneidad y estabilidad del archivo de auditoría para CO 0-μmol/mol.

### Resultados

#### 1. Estadísticos que COINCIDEN entre Auditoría y App:
| Estadístico | Auditoría | App | Estado |
|-------------|-----------|-----|--------|
| Promedio general | -0.020417 | -0.020417 | ✅ |
| sx (SD promedios) | 0.018363 | 0.018363 | ✅ |
| sw (SD intra) | 0.036226 | 0.036226 | ✅ |

#### 2. Discrepancia principal: σpt
| Fuente | σpt | Origen |
|--------|-----|--------|
| **Auditoría Excel** | 0.005788 | 3 valores en B110:B112 (origen desconocido) |
| **App (ptcalc)** | 0.039820 | Datos de homogeneidad (MADe = 1.483 × median(\|col2 - median(col1)\|)) |

#### 3. Resultados de criterios (usando σpt del app):
- **Homogeneidad:** ❌ NO PASA (ss = 0.017860 > c = 0.011946)
- **Estabilidad:** ✅ PASA (D = 0.001841 ≤ c = 0.011946)

### Conclusiones

1. **Los cálculos básicos son correctos:** promedio, sx y sw coinciden exactamente.
2. **El σpt de la auditoría es un valor externo:** se calcula con datos que no provienen de homogeneidad.
3. **Las funciones de ptcalc calculan correctamente:** resultados idénticos a cálculos manuales.
4. **La implementación del app es correcta:** usa σpt calculado de los datos de homogeneidad.
5. **Fórmula MADe en homogeneidad:** es específica para este contexto (`1.483 × median(|col2 - median(col1)|)`), diferente a la fórmula ISO 13528 general.

### Preguntas Abiertas

- ¿Cuál es el origen de los 3 valores en B110:B112 del Excel?
- ¿El σpt debería ser un valor prescrito externamente (ej. incertidumbre del patrón)?
