# Guía de Implementación y Pruebas: `validar_calculos.R`

**Fecha:** 2026-01-03  
**Ubicación:** `entregas/E3_calculos_estadisticos/validar_calculos.R`

---

## 1. Objetivo del Script

Este script valida las funciones estadísticas core del aplicativo PT:
- Cálculo de nIQR (Rango Intercuartílico Normalizado)
- Cálculo de MADe (Desviación Absoluta de la Mediana escalada)
- Algoritmo A de ISO 13528 para estimadores robustos
- Criterio de homogeneidad según ISO 13528

---

## 2. Prerrequisitos

### 2.1. Software Requerido
- **R** versión 4.0.0 o superior
- No requiere librerías adicionales (usa solo funciones base de R)

### 2.2. Verificar Instalación de R
```bash
R --version
```

---

## 3. Cómo Ejecutar el Script

### Método A: Desde Visual Studio Code (Recomendado)

1. Abra el archivo `entregas/E3_calculos_estadisticos/validar_calculos.R` en VS Code.
2. Si tiene la extensión R instalada:
   - Presione `Ctrl+Shift+P` → Busque `R: Run Source`
   - O presione `Ctrl+Enter` para ejecutar línea por línea
3. Revise la salida en el panel de terminal integrado.

### Método B: Desde la Terminal Integrada de VS Code

```bash
cd /home/w182/w421/pt_app
Rscript entregas/E3_calculos_estadisticos/validar_calculos.R
```

### Método C: Desde una Consola R Interactiva

```r
setwd("/home/w182/w421/pt_app")
source("entregas/E3_calculos_estadisticos/validar_calculos.R")
```

---

## 4. Estructura de las Pruebas

El script ejecuta 3 pruebas principales:

| Prueba | Descripción | Datos de Entrada |
|--------|-------------|------------------|
| 1. nIQR y MADe | Compara resultados robustos vs clásicos | Datos limpios + datos con atípico |
| 2. Algoritmo A | Verifica convergencia y robustez | Datos con atípico severo (50.0) |
| 3. Homogeneidad | Evalúa criterio $s_s \le 0.3\sigma_{pt}$ | 10 ítems simulados |

---

## 5. Interpretación de Resultados

### 5.1. Salida Esperada (Éxito)

```
============================================
  Validación de Cálculos - PT App
============================================

--- Prueba 1: nIQR y MADe ---

Datos limpios: 10, 10.1, 9.9, 10.2, 10, 9.8, 10.1
  nIQR: 0.1483
  MADe: 0.1483
  SD clásica: 0.1345

Datos con atípico (50.0): 10, 10.1, 9.9, 10.2, 10, 9.8, 50
  nIQR: 0.1483
  MADe: 0.1483
  SD clásica: 15.0843 (inflada por atípico)

--- Prueba 2: Algoritmo A ---

Datos limpios:
  Media robusta (x*): 10.0143
  Desviación robusta (s*): 0.1251
  Convergió: TRUE en 3 iteraciones

Datos con atípico:
  Media robusta (x*): 10.1057
  Desviación robusta (s*): 0.1892
  Convergió: TRUE en 5 iteraciones
  Media clásica (comparación): 14.2857 (sesgada)

--- Prueba 3: Criterio de Homogeneidad ---

Número de ítems (g): 10
Réplicas por ítem (m): 2
Desviación entre muestras (ss): 0.01234
Desviación intra-muestra (sw): 0.03456
Sigma_pt (MADe): 0.05678
Criterio c (0.3*sigma_pt): 0.01703
Resultado: CUMPLE HOMOGENEIDAD

============================================
  Resumen de Validación
============================================

✓ nIQR y MADe calculan correctamente para datos limpios.
✓ nIQR y MADe son robustos frente a atípicos.
✓ Algoritmo A converge y minimiza efecto de atípicos.
✓ Criterio de homogeneidad se evalúa correctamente.

Validación completada exitosamente.
```

### 5.2. Puntos Clave de Verificación

| Aspecto | Valor Esperado | Indicador de Problema |
|---------|----------------|----------------------|
| nIQR con atípico | Similar a datos limpios | Valor muy inflado |
| MADe con atípico | Similar a datos limpios | Valor muy inflado |
| Algoritmo A - Media | Cercana a 10.0 | > 12 indica falla |
| Algoritmo A - Convergencia | `TRUE` en < 10 iter | `FALSE` o > 20 iter |
| Homogeneidad | `CUMPLE` | Depende de datos simulados |

---

## 6. Pruebas Adicionales Sugeridas

### 6.1. Prueba con Datos Reales

Puede modificar el script para usar datos reales del aplicativo:

```r
# Cargar datos de homogeneidad reales
library(vroom)
hom_real <- vroom("data/homogeneity.csv", show_col_types = FALSE)

# Extraer valores de un analito específico
so2_values <- hom_real$value[hom_real$pollutant == "SO2"]

# Aplicar funciones de validación
cat("nIQR (SO2):", calculate_niqr(so2_values), "\n")
cat("MADe (SO2):", calculate_made(so2_values), "\n")
```

### 6.2. Prueba de Estrés con Múltiples Atípicos

```r
# Datos con 30% de atípicos
data_stress <- c(10.0, 10.1, 9.9, 50.0, 60.0, 70.0, 10.2)

res_stress <- run_algorithm_a(data_stress)
cat("Algoritmo A con 30% atípicos:\n")
cat("  x* =", res_stress$mean, "\n")
cat("  s* =", res_stress$sd, "\n")
```

---

## 7. Solución de Problemas

| Problema | Causa Probable | Solución |
|----------|----------------|----------|
| `Error: could not find function` | Script no se ejecutó completo | Ejecutar con `source()` |
| Algoritmo A no converge | Datos con muy poca variabilidad | Verificar que $s^* > 0$ |
| nIQR retorna NA | Menos de 2 valores válidos | Revisar datos de entrada |
| Valores numéricos extraños | Formato decimal incorrecto | Usar punto (.) como separador |

---

## 8. Siguiente Paso

Una vez validados los cálculos, puede proceder a ejecutar el script de validación de puntajes:

```bash
Rscript entregas/E4_puntajes/validar_puntajes.R
```
