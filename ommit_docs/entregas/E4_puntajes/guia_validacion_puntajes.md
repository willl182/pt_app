# Guía de Implementación y Pruebas: `validar_puntajes.R`

**Fecha:** 2026-01-03  
**Ubicación:** `entregas/E4_puntajes/validar_puntajes.R`

---

## 1. Objetivo del Script

Este script valida las funciones de cálculo de puntajes de desempeño:
- **z-score** — Puntaje estándar
- **z'-score** — Con incertidumbre del valor asignado
- **zeta-score** — Con incertidumbre del participante
- **En-score** — Con incertidumbres expandidas

---

## 2. Prerrequisitos

### 2.1. Software Requerido
- **R** versión 4.0.0 o superior
- Paquete `dplyr` (para función `case_when`)

### 2.2. Verificar Dependencias

```r
if (!require("dplyr")) install.packages("dplyr")
```

---

## 3. Cómo Ejecutar el Script

### Método A: Desde Visual Studio Code

1. Abra `entregas/E4_puntajes/validar_puntajes.R` en VS Code.
2. Con la extensión R instalada:
   - Presione `Ctrl+Shift+P` → `R: Run Source`
   - O use `Ctrl+Enter` para ejecutar línea por línea

### Método B: Desde la Terminal de VS Code

```bash
cd /home/w182/w421/pt_app
Rscript entregas/E4_puntajes/validar_puntajes.R
```

### Método C: Desde Consola R Interactiva

```r
setwd("/home/w182/w421/pt_app")
source("entregas/E4_puntajes/validar_puntajes.R")
```

---

## 4. Escenarios de Prueba

El script ejecuta tres escenarios con diferentes niveles de desvío:

| Escenario | xi | Desvío de xpt | Resultado Esperado |
|-----------|-----|---------------|-------------------|
| 1. Satisfactorio | 10.1 | 0.1 | z ≈ 0.5 (Satisfactorio) |
| 2. Cuestionable | 10.45 | 0.45 | z ≈ 2.25 (Cuestionable) |
| 3. Insatisfactorio | 10.8 | 0.8 | z = 4.0 (Insatisfactorio) |

---

## 5. Interpretación de Resultados

### 5.1. Salida Esperada (Éxito)

```
============================================
  Validación de Puntajes de Desempeño
============================================

--- Escenario 1: Resultado Satisfactorio ---

Entradas:
  xi = 10.1 | xpt = 10 | σpt = 0.2
  ui = 0.08 | uxpt = 0.05 | k = 2

Resultados:
  z     = 0.5 → Satisfactorio
  z'    = 0.4851 → Satisfactorio
  zeta  = 1.0541 → Satisfactorio
  En    = 0.5270 → Satisfactorio

--- Escenario 2: Resultado Cuestionable ---

Entradas:
  xi = 10.45 (mayor desvío)

Resultados:
  z     = 2.25 → Cuestionable
  z'    = 2.1827 → Cuestionable
  zeta  = 4.7434 → Insatisfactorio
  En    = 2.3717 → Insatisfactorio

--- Escenario 3: Resultado Insatisfactorio ---

Entradas:
  xi = 10.8 (desvío severo)

Resultados:
  z     = 4 → Insatisfactorio
  z'    = 3.8804 → Insatisfactorio
  zeta  = 8.4327 → Insatisfactorio
  En    = 4.2163 → Insatisfactorio

--- Verificación Manual de Fórmulas ---

z = ( 10.1 - 10 ) / 0.2 = 0.5
z' = ( 10.1 - 10 ) / √( 0.04 + 0.0025 ) = 0.4851
ζ = ( 10.1 - 10 ) / √( 0.0064 + 0.0025 ) = 1.0541
En = ( 10.1 - 10 ) / √( 0.0256 + 0.01 ) = 0.527

--- Verificación de Criterio para z' ---

uxpt = 0.05
0.3 × σpt = 0.06
Resultado: uxpt ≤ 0.3σpt → z estándar es adecuado

============================================
  Resumen de Validación
============================================

✓ z-score calcula correctamente para todos los escenarios.
✓ z'-score incorpora incertidumbre del valor asignado.
✓ zeta-score incorpora incertidumbre del participante.
✓ En-score usa incertidumbres expandidas (k=2).
✓ Criterios de evaluación aplicados correctamente.

Validación completada exitosamente.
```

### 5.2. Puntos Clave de Verificación

| Aspecto | Verificación |
|---------|--------------|
| z-score | (xi - xpt) / σpt = valor calculado |
| Escenario Satisfactorio | \|z\| ≤ 2 |
| Escenario Cuestionable | 2 < \|z\| < 3 |
| Escenario Insatisfactorio | \|z\| ≥ 3 |
| En ≤ 1 | Satisfactorio |
| En > 1 | Insatisfactorio |

---

## 6. Pruebas Adicionales Sugeridas

### 6.1. Prueba con Datos del Aplicativo

```r
# Simular datos de un participante real
library(vroom)
summary_data <- vroom("data/summary_n7.csv", show_col_types = FALSE)

# Filtrar un participante específico
lab_result <- summary_data %>%
  filter(participant_id == "lab_1", pollutant == "SO2", level == "level_1")

# Calcular puntajes
scores <- calculate_scores(
  xi = lab_result$mean_value,
  xpt = 100,        # Valor asignado conocido
  sigma_pt = 5,     # Sigma_pt conocido
  ui = lab_result$sd_value,
  uxpt = 1,
  k = 2
)

print(scores)
```

### 6.2. Prueba Límite (Exactamente en el Umbral)

```r
# z exactamente en 2.0
xi_limit <- 10.0 + (2.0 * 0.2)  # = 10.4
scores_limit <- calculate_scores(xi_limit, 10.0, 0.2, 0.08, 0.05, 2)
cat("z en umbral:", scores_limit$z, "→", evaluate_z(scores_limit$z), "\n")
# Debe dar "Satisfactorio" (≤ 2)
```

---

## 7. Relación entre Puntajes

### 7.1. Observaciones Importantes

- **z' siempre < z** (en valor absoluto) porque el denominador es mayor.
- **zeta puede ser > z** si la incertidumbre del participante es pequeña.
- **En = zeta / k** cuando k es el mismo para ambas incertidumbres.

### 7.2. Cuándo Divergen las Evaluaciones

En el Escenario 2, observe:
- z = 2.25 → Cuestionable
- zeta = 4.74 → Insatisfactorio

Esto indica que el participante reportó una incertidumbre muy pequeña para su resultado. La evaluación zeta penaliza más severamente esta situación.

---

## 8. Solución de Problemas

| Problema | Causa | Solución |
|----------|-------|----------|
| `Error: could not find function "case_when"` | dplyr no cargado | Agregar `library(dplyr)` |
| Valores `NA` en zeta/En | `ui = NULL` | Proporcionar incertidumbre del participante |
| z' igual a z | `uxpt = 0` | Verificar incertidumbre del valor asignado |
| Evaluaciones siempre "Satisfactorio" | sigma_pt muy grande | Revisar datos de entrada |

---

## 9. Próximos Pasos

Después de validar los puntajes, puede:
1. Ejecutar el script de validación de homogeneidad/estabilidad
2. Probar la generación del informe con `rmarkdown::render()`
3. Verificar las visualizaciones en el aplicativo Shiny
