# 17. Guía de Solución de Problemas y Preguntas Frecuentes (FAQ)

| Propiedad | Valor |
|----------|-------|
| **Tipo de Documento** | FAQ / Solución de Errores |
| **Archivo Principal** | `app.R` / `cloned_app.R` |
| **Docs Relacionados** | `01_carga_datos.md`, `15_arquitectura.md`, `02_paquete_ptcalc.md` |

Este documento proporciona soluciones a los errores, problemas y dificultades comunes encontrados al utilizar el Aplicativo de Análisis de Datos de PT. Incluye la solución de problemas para la carga de datos, los cálculos, la optimización del desempeño y la compatibilidad del navegador.

---

## Diagnósticos Rápidos

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
    "No instalado"
  }
})

# 3. Comprobar que el paquete ptcalc es cargable
library(ptcalc)
```

---

## Mensajes de Error Comunes

| Mensaje de Error | Contexto | Causa Raíz | Solución |
|---------------|---------|------------|----------|
| `disconnected from the server` | Caída general de la aplicación | Sesión de R sin memoria o error de sintaxis | Comprobar la consola de R para el rastreo de la pila. Aumentar la memoria de R o reducir el tamaño del archivo de entrada. |
| `must contain the columns 'value', 'pollutant', 'level'` | Carga de datos | El encabezado del CSV no coincide con el formato esperado | Verificar que los nombres de las columnas coincidan exactamente (sensible a mayúsculas: `value` ≠ `Value`). |
| `No hay suficientes ítems...` | Análisis de homogeneidad | Menos de 2 grupos en el ANOVA | Asegurarse de que el CSV tenga al menos 2 grupos de `level` diferentes para el contaminante seleccionado. |
| `replacement has length zero` | Cálculo | La función devolvió `NULL` o un vector vacío | Comprobar si hay valores `NA` en los datos de entrada o si faltan columnas. |
| `there is no package called 'ptcalc'` | Inicio del aplicativo | El paquete ptcalc no está instalado | Ejecutar `devtools::install("ptcalc")` desde el directorio raíz del proyecto. |
| `Error in algorithm_A(x) : Not enough data` | Cálculo del Algoritmo A | Menos de 3 participantes/valores | El Algoritmo A requiere ≥ 3 valores. Añadir más participantes o usar MADe/nIQR. |
| `Algorithm A did not converge` | Cálculo iterativo | Valores atípicos extremos o datos erróneos | Eliminar los valores atípicos extremos o comprobar errores de entrada de datos. |
| `argument is not numeric or logical` | Cálculo de puntajes | La columna de datos contiene valores no numéricos | Buscar texto como "N/A" en lugar de `NA`. Convertir a numérico. |
| `sigma_pt is zero or negative` | Cálculo de puntajes | Sin variación en los datos | Verificar las entradas de las fórmulas y asegurar que haya suficiente variación en los resultados de los participantes. |
| `object 'input$...' not found` | Evaluación reactiva | Errores tipográficos en el código o falta de elemento en la UI | Verificar que el ID de entrada coincida con la definición de la UI. |
| `Error generating Word document` | Generación de informe | Problema de Pandoc/RMarkdown | Comprobar la instalación de pandoc con `rmarkdown::pandoc_available()`. |

---

## Problemas de Formato de Datos

### 1. Nomenclatura y Estructura de Columnas
La aplicación requiere nombres de columna específicos. Los errores tipográficos o las discrepancias de mayúsculas/minúsculas son la causa más común de los errores de "columna faltante".

**Columnas requeridas por tipo de archivo:**

| Tipo de Archivo | Columnas Requeridas |
|-----------|------------------|
| `homogeneity.csv` | `pollutant`, `level`, `replicate`, `value` |
| `stability.csv` | `pollutant`, `level`, `time`, `value` |
| `summary_n*.csv` | `pollutant`, `level`, `participant_id`, `value`, `u_x` (opcional), `U_x` (opcional) |

**Script de Solución Rápida (R):**
```r
# Estandarizar los nombres de las columnas
names(df) <- tolower(trimws(names(df)))
names(df) <- gsub(" ", "_", names(df))
```

### 2. Separadores Decimales
Utilice puntos (`.`) para los decimales, no comas (`,`).

| Incorrecto | Correcto |
|-----------|---------|
| `0,0523`  | `0.0523` |
| `12,5`    | `12.5`   |

**Solución:** En Excel, formatee las celdas como "Número" con `.` como separador decimal antes de exportar a CSV.

### 3. Codificación de Archivos (UTF-8)
Los caracteres especiales (acentos, ñ) causan errores de `invalid multibyte string` si no se guardan en UTF-8.

**Solución:**
- **Excel:** Archivo → Guardar como → CSV UTF-8 (delimitado por comas) (*.csv).
- **R:** `read.csv("archivo.csv", fileEncoding = "UTF-8")` o `fileEncoding = "UTF-8-BOM"`.

### 4. Valores Faltantes (NA)
Las celdas vacías o las cadenas como "N/A" pueden bloquear los cálculos.

**Solución:**
```r
# Reemplazar las cadenas inválidas comunes por el NA adecuado
df <- df %>% mutate(across(everything(), ~na_if(., ""))) %>% mutate(across(everything(), ~na_if(., "N/A")))
```

---

## Inicio e Instalación del Aplicativo

### Paquete ptcalc no Encontrado
Si ve `there is no package called 'ptcalc'`:

1.  **Instalar desde la fuente:**
    ```bash
    devtools::install("ptcalc")
    ```
2.  **Modo Desarrollador:** Si está modificando el paquete, use `devtools::load_all("ptcalc")` en `app.R` en lugar de `library(ptcalc)`.

### Incompatibilidad de la Versión de R
La aplicación requiere R >= 4.2.0. Las versiones anteriores pueden fallar al instalar las dependencias de `bslib` o `plotly`.

---

## Problemas Específicos de Módulos

### Homogeneidad y Estabilidad
- **"No hay suficientes réplicas"**: La homogeneidad requiere al menos 2 réplicas por muestra.
- **"No hay suficientes ítems"**: La homogeneidad requiere al menos 2 ítems/unidades distintos.
- **Varianza negativa**: Puede ocurrir en el cálculo de `s_within` si los datos son altamente inconsistentes. Comprobar errores de entrada de datos.

### Asignación de Valor y Puntuación
- **"No hay datos de referencia disponibles"**: Los métodos de referencia requieren una fila donde `participant_id = "ref"`.
- **"Calcule los puntajes primero"**: Debe hacer clic en el botón "Ejecutar" para activar el caché de cálculo.
- **Combinaciones faltantes**: Si los puntajes no aparecen para un contaminante específico, compruebe que exista tanto en el resumen como en los archivos de referencia/valor asignado.

---

## Optimización del Desempeño

### Conjuntos de Datos Grandes (>100MB)
| Tamaño del Conjunto | Comportamiento Esperado | Optimización |
|--------------|-------------------|--------------|
| 10-100 MB | Retraso moderado | Aumentar el límite de memoria de R |
| > 100 MB | Lento / Caídas | Pre-agregar los datos |

**Aumentar el Límite de Memoria (Windows):**
```r
memory.limit(size = 8000) # Establecer en 8GB
```

### Renderizado Lento de Gráficos
Plotly puede ser lento con más de 10,000 puntos.
- **Solución**: Reducir la muestra de datos para la visualización: `data %>% sample_n(min(n(), 5000))`.
- **Gráficos Estáticos**: Usar `ggplot2` sin `ggplotly()` para un renderizado más rápido de conjuntos de datos extremadamente grandes.

---

## Compatibilidad del Navegador y Problemas de UI

### Navegadores Soportados
- **Recomendado**: Chrome, Firefox, Edge (Chromium).
- **Safari**: Problemas conocidos con los nombres de los archivos descargados (puede requerir renombrado manual) y el diseño de flexbox en versiones < 15.
- **IE 11**: No soportado.

### Problemas de Visualización de la UI
- **Los gráficos no se renderizan**: Comprobar la consola del navegador (F12) para ver si hay errores de JavaScript. Asegurarse de que existan datos para la selección.
- **Diseño roto**: Restablecer el zoom del navegador al 100%. Ajustar los deslizadores de "Ancho del diseño" en la barra lateral de la aplicación.
- **Bloqueo de Ventanas Emergentes**: Asegurarse de que las ventanas emergentes estén permitidas para la generación de informes/descargas.

---

## Consejos de Depuración

### Habilitar el Registro Detallado
En su sesión de R antes de ejecutar la aplicación:
```r
options(shiny.trace = TRUE)
options(shiny.fullstacktrace = TRUE)
options(shiny.reactlog = TRUE) # Presione Ctrl+F3 en el navegador para ver el flujo reactivo
```

### Imprimir Diagnósticos
Añada `observe({ print(input$pollutant_selector) })` en la función del servidor para rastrear los cambios de estado.

---

## Prevención: Mejores Prácticas

- [ ] **Codificación UTF-8**: Guarde siempre los CSV como UTF-8.
- [ ] **Comprobar Encabezados**: Asegúrese de que los nombres de las columnas coincidan exactamente con la tabla de "Columnas Requeridas".
- [ ] **Limpieza de Datos**: Elimine las filas vacías y compruebe si hay caracteres no numéricos en las columnas de valor.
- [ ] **Pasos Pequeños**: Pruebe con un pequeño subconjunto de datos si falla un archivo grande.
- [ ] **Clic en Ejecutar**: Recuerde que la aplicación requiere clics explícitos en el botón "Ejecutar" para los cálculos principales.

---

## Referencia de Soluciones Rápidas

| Problema | Solución Rápida |
|---------|-----------|
| El archivo no se sube | Comprobar el tamaño del archivo (< 30MB), usar codificación UTF-8 |
| Error de columnas faltantes | Verificar los nombres exactos de las columnas (sensible a mayúsculas) |
| El cálculo no se ejecuta | Hacer clic primero en el botón "Ejecutar" |
| Sin valores de referencia | Añadir una fila `participant_id = "ref"` a los datos |
| Falla la generación del informe | Comprobar si pandoc está instalado |
| Gráficos en blanco | Verificar que existan datos para la selección; comprobar el zoom del navegador |
| Desempeño lento | Reducir el tamaño de los datos; cerrar otras pestañas del navegador |

---

## Ver También

- `01_carga_datos.md` - Especificaciones detalladas del formato de datos.
- `15_arquitectura.md` - Vista general de la estructura del sistema.
- `02a_api_ptcalc.md` - Documentación de las funciones de cálculo subyacentes.
