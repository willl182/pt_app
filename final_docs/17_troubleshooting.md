# Guía de resolución de problemas

Este documento resume errores comunes, problemas de formato de datos, rendimiento y compatibilidad de navegador.

---

## Diagnóstico rápido

```r
R.version.string

required_packages <- c("shiny", "bslib", "dplyr", "ggplot2", "rmarkdown")
sapply(required_packages, packageVersion)

# Verificar que ptcalc esté instalado
library(ptcalc)
```

---

## Errores comunes

| Error | Contexto | Causa | Solución |
|---|---|---|---|
| `disconnected from the server` | Caída general | Memoria insuficiente o error de datos | Revisar consola R. Reducir tamaño de archivos o aumentar `R_MAX_VSIZE`. |
| `must contain the columns 'value', 'pollutant', 'level'` | Carga de datos | Encabezados incorrectos | Verificar nombres exactos (minúsculas). |
| `No hay suficientes ítems...` | Homogeneidad | Menos de 2 ítems/grupos | Asegurar ≥2 ítems por contaminante/nivel. |
| `replacement has length zero` | Cálculos | Vector vacío o `NULL` | Revisar `NA` y filtros sin datos. |
| `there is no package called 'ptcalc'` | Inicio | Paquete no instalado | `devtools::install("ptcalc")`. |
| `Error in algorithm_A(x): Not enough data` | Algoritmo A | <3 participantes | Añadir participantes o usar MADe/nIQR. |
| `argument is not numeric or logical` | Puntajes | Valores no numéricos | Convertir columnas a numérico y limpiar texto. |
| `object 'input$...' not found` | Reactivos | ID inexistente | Revisar IDs en UI y server. |

---

## Problemas de formato de datos

### Separador decimal

| Incorrecto | Correcto |
|---|---|
| `0,0523` | `0.0523` |
| `12,5` | `12.5` |

**Solución:** exportar con `dec = "."` o reemplazar comas por puntos.

### Codificación

**Síntoma:** caracteres especiales corruptos o errores de multibyte.

**Solución:** guardar CSV como UTF-8.

```r
read.csv("file.csv", fileEncoding = "UTF-8")
```

### Valores faltantes

Usar `NA` explícito. Evitar `"N/A"`, `"-999"` o celdas vacías.

```r
df <- df %>%
  mutate(across(everything(), ~na_if(., ""))) %>%
  mutate(across(everything(), ~na_if(., "N/A")))
```

### Columnas requeridas

| Archivo | Columnas |
|---|---|
| `homogeneity.csv` | `value`, `pollutant`, `level` |
| `stability.csv` | `value`, `pollutant`, `level` |
| `summary_n*.csv` | `participant_id`, `pollutant`, `level`, `mean_value`, `sd_value` |

---

## Rendimiento

- **Archivos grandes (>100MB):** la carga puede ser lenta. Considere pre-agregar datos.
- **Gráficas lentas:** `plotly` con >10k puntos puede ser pesado.

---

## Compatibilidad de navegador

- **Recomendado:** Chrome, Firefox, Edge (Chromium).
- **Problemas conocidos:** Safari antiguo puede fallar en layout.
- **Descargas bloqueadas:** permitir pop-ups para reportes.
