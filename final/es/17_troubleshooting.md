# 17. Guía de Solución de Problemas y Preguntas Frecuentes

| Propiedad | Valor |
|-----------|-------|
| **Tipo de Documento** | FAQ / Soluciones de Errores |
| **Archivo Principal** | `app.R` / `cloned_app.R` |
| **Docs Relacionados** | `01_carga_datos.md`, `15_architecture.md`, `02_ptcalc_package.md` |

Este documento proporciona soluciones a errores comunes, problemas y dificultades encontradas al usar la aplicación de Análisis de Datos de PT. Incluye la solución de problemas para la carga de datos, cálculos, optimización del rendimiento y compatibilidad del navegador.

---

## Diagnóstico Rápido

Antes de profundizar en errores específicos, ejecute estas comprobaciones en su consola de R:

```r
# 1. Comprobar la versión de R (requiere >= 4.2)
R.version.string

# 2. Comprobar los paquetes requeridos
required_packages <- c("shiny", "tidyverse", "vroom", "DT", "bslib", "plotly", "rmarkdown")
sapply(required_packages, function(pkg) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    packageVersion(pkg)
  } else {
    "No Instalado"
  }
})

# 3. Comprobar que el paquete ptcalc es cargable
library(ptcalc)
```

---

## Mensajes de Error Comunes

| Mensaje de Error | Contexto | Causa Raíz | Solución |
|------------------|----------|------------|----------|
| `disconnected from the server` | Caída general de la aplicación | Sesión de R sin memoria o error de sintaxis | Verifique la consola de R para el rastreo de la pila (stack trace). Aumente la memoria de R o reduzca el tamaño del archivo de entrada. |
| `must contain the columns 'value', 'pollutant', 'level'` | Carga de datos | El encabezado CSV no coincide con el formato esperado | Verifique que los nombres de las columnas coincidan exactamente (distingue mayúsculas y minúsculas: `value` ≠ `Value`). |
| `No hay suficientes ítems...` | Análisis de homogeneidad | Menos de 2 grupos en ANOVA | Asegúrese de que el CSV tenga al menos 2 grupos de `level` diferentes para el contaminante seleccionado. |
| `replacement has length zero` | Cálculo | La función devolvió `NULL` o un vector vacío | Compruebe valores `NA` en los datos de entrada o columnas faltantes. |
| `there is no package called 'ptcalc'` | Inicio de la aplicación | Paquete ptcalc no instalado | Ejecute `devtools::install("ptcalc")` desde el directorio raíz del proyecto. |
| `Error in algorithm_A(x) : Not enough data` | Cálculo del Algoritmo A | Menos de 3 participantes/valores | El Algoritmo A requiere ≥ 3 valores. Agregue más participantes o use MADe/nIQR. |
| `Algorithm A did not converge` | Cálculo iterativo | Valores atípicos extremos o datos erróneos | Elimine valores atípicos extremos o verifique errores de entrada de datos. |
| `argument is not numeric or logical` | Cálculo de puntajes | La columna de datos contiene valores no numéricos | Busque texto como "N/A" en lugar de `NA`. Convierta a numérico. |
| `sigma_pt is zero or negative` | Cálculo de puntajes | Sin variación en los datos | Verifique las entradas de la fórmula y asegúrese de que haya suficiente variación en los resultados de los participantes. |
| `object 'input$...' not found` | Evaluación reactiva | Errores tipográficos en el código o elemento de IU faltante | Verifique que el ID de entrada coincida con la definición de la IU. |
| `Error generating Word document` | Generación de informes | Problema de Pandoc/RMarkdown | Verifique la instalación de pandoc con `rmarkdown::pandoc_available()`. |

---

## Problemas de Formato de Datos

### 1. Nomenclatura y Estructura de Columnas
La aplicación requiere nombres de columna específicos. Los errores tipográficos o las discrepancias de mayúsculas y minúsculas son la causa más común de los errores de "columna faltante".

**Columnas Requeridas por Tipo de Archivo:**

| Tipo de Archivo | Columnas Requeridas |
|-----------------|---------------------|
| `homogeneity.csv` | `pollutant`, `level`, `replicate`, `value` |
| `stability.csv` | `pollutant`, `level`, `time`, `value` |
| `summary_n*.csv` | `pollutant`, `level`, `participant_id`, `value`, `u_x` (opcional), `U_x` (opcional) |

**Script de Corrección Rápida (R):**
```r
# Estandarizar nombres de columnas
names(df) <- tolower(trimws(names(df)))
names(df) <- gsub(" ", "_", names(df))
```

### 2. Separadores Decimales
Use puntos (`.`) para los decimales, no comas (`,`).

| Incorrecto | Correcto |
|------------|----------|
| `0,0523`   | `0.0523` |
| `12,5`     | `12.5`   |

**Solución:** En Excel, formatee las celdas como "Número" con `.` como separador decimal antes de exportar a CSV.

### 3. Codificación de Archivos (UTF-8)
Los caracteres especiales (acentos, ñ) causan errores de `invalid multibyte string` si no se guardan en UTF-8.

**Solución:**
- **Excel:** Archivo → Guardar como → CSV UTF-8 (delimitado por comas) (*.csv).
- **R:** `read.csv("file.csv", fileEncoding = "UTF-8")` o `fileEncoding = "UTF-8-BOM"`.

### 4. Valores Faltantes (NA)
Las celdas vacías o cadenas como "N/A" pueden bloquear los cálculos.

**Solución:**
```r
# Reemplazar cadenas inválidas comunes con NA adecuado
df <- df %>% mutate(across(everything(), ~na_if(., ""))) %>% mutate(across(everything(), ~na_if(., "N/A")))
```

---

## Inicio e Instalación de la Aplicación

### Paquete ptcalc No Encontrado
Si ve `there is no package called 'ptcalc'`:

1.  **Instalar desde la fuente:**
    ```bash
    devtools::install("ptcalc")
    ```
2.  **Modo Desarrollador:** Si está modificando el paquete, use `devtools::load_all("ptcalc")` en `app.R` en lugar de `library(ptcalc)`.

### Incompatibilidad de Versión de R
La aplicación requiere R >= 4.2.0. Las versiones anteriores pueden fallar al instalar las dependencias `bslib` o `plotly`.

---

## Problemas Específicos por Módulo

### Homogeneidad y Estabilidad
- **"No hay suficientes replicas"**: La homogeneidad requiere al menos 2 réplicas por muestra.
- **"No hay suficientes items"**: La homogeneidad requiere al menos 2 ítems/unidades distintas.
- **Varianza negativa**: Puede ocurrir en el cálculo de `s_within` si los datos son altamente inconsistentes. Verifique errores de entrada de datos.

### Asignación de Valores y Puntajes
- **"No hay datos de referencia disponibles"**: Los métodos de referencia requieren una fila donde `participant_id = "ref"`.
- **"Calcule los puntajes primero"**: Debe hacer clic en el botón "Ejecutar" / "Run" para activar la caché de cálculo.
- **Combinaciones faltantes**: Si los puntajes no aparecen para un contaminante específico, verifique que exista tanto en los archivos de resumen como en los de valor de referencia/asignado.

---

## Optimización del Rendimiento

### Conjuntos de Datos Grandes (>100MB)
| Tamaño del Conjunto de Datos | Comportamiento Esperado | Optimización |
|------------------------------|-------------------------|--------------|
| 10-100 MB | Retraso moderado | Aumentar el límite de memoria de R |
| > 100 MB | Lento / Caídas | Pre-agregar datos |

**Aumentar el Límite de Memoria (Windows):**
```r
memory.limit(size = 8000) # Establecer en 8GB
```

### Renderizado de Gráficos Lento
Plotly puede ser lento con >10,000 puntos.
- **Solución:** Reducir la muestra de datos para visualización: `data %>% sample_n(min(n(), 5000))`.
- **Gráficos Estáticos:** Use `ggplot2` sin `ggplotly()` para un renderizado más rápido de conjuntos de datos extremadamente grandes.

---

## Compatibilidad del Navegador y Problemas de IU

### Navegadores Compatibles
- **Recomendado:** Chrome, Firefox, Edge (Chromium).
- **Safari:** Problemas conocidos con los nombres de archivo de descarga (puede requerir cambio de nombre manual) y el diseño flexbox en versiones < 15.
- **IE 11:** No compatible.

### Problemas de Visualización de la IU
- **Gráficos no se renderizan:** Verifique la consola del navegador (F12) para ver si hay errores de JavaScript. Asegúrese de que existan datos para la selección.
- **Diseño roto:** Restablezca el zoom del navegador al 100%. Ajuste los controles deslizantes de "Layout Width" en la barra lateral de la aplicación.
- **Bloqueo de Ventanas Emergentes:** Asegúrese de que se permitan las ventanas emergentes para la generación/descarga de informes.

---

## Consejos de Depuración

### Habilitar Registro Detallado
En su sesión de R antes de ejecutar la aplicación:
```r
options(shiny.trace = TRUE)
options(shiny.fullstacktrace = TRUE)
options(shiny.reactlog = TRUE) # Presione Ctrl+F3 en el navegador para ver el flujo reactivo
```

### Imprimir Diagnósticos
Agregue `observe({ print(input$pollutant_selector) })` en la función del servidor para rastrear cambios de estado.

---

## Prevención: Mejores Prácticas

- [ ] **Codificación UTF-8:** Guarde siempre los CSV como UTF-8.
- [ ] **Verificar Encabezados:** Asegúrese de que los nombres de las columnas coincidan exactamente con la tabla de "Columnas Requeridas".
- [ ] **Limpieza de Datos:** Elimine las filas vacías y busque caracteres no numéricos en las columnas de valores.
- [ ] **Pasos Pequeños:** Pruebe con un pequeño subconjunto de datos si falla un archivo grande.
- [ ] **Hacer clic en Ejecutar:** Recuerde que la aplicación requiere clics explícitos en el botón "Ejecutar" para los cálculos principales.

---

## Referencia de Correcciones Rápidas

| Problema | Corrección Rápida |
|----------|-------------------|
| El archivo no se sube | Verifique el tamaño del archivo (< 30MB), use codificación UTF-8 |
| Error de columnas faltantes | Verifique los nombres exactos de las columnas (distingue mayúsculas y minúsculas) |
| El cálculo no se ejecuta | Haga clic primero en el botón "Ejecutar" |
| No hay valores de referencia | Agregue la fila `participant_id = "ref"` a los datos |
| La generación del informe falla | Verifique si pandoc está instalado |
| Gráficos en blanco | Verifique que existan datos para la selección; compruebe el zoom del navegador |
| Rendimiento lento | Reduzca el tamaño de los datos; cierre otras pestañas del navegador |

---

## Ver También

- `01_carga_datos.md` - Especificaciones detalladas del formato de datos.
- `15_architecture.md` - Descripción general de la estructura del sistema.
- `02a_ptcalc_api.md` - Documentación de las funciones de cálculo subyacentes.
