# Solución de Problemas y Preguntas Frecuentes

Esta guía proporciona soluciones a errores comunes, problemas de formato de datos y consejos de rendimiento.

---

## Mensajes de Error Comunes

| Mensaje de Error | Contexto | Causa Raíz | Solución |
|------------------|----------|------------|----------|
| `disconnected from the server` | Caída general | R se quedó sin memoria o error de sintaxis grave. | Verifique la consola de R. Aumente la memoria o reduzca el tamaño del archivo. |
| `must contain the columns 'value', 'pollutant'...` | Carga de datos | Encabezados CSV incorrectos. | Corrija los nombres de columnas. Recuerde que distingue mayúsculas (`value` ≠ `Value`). |
| `No hay suficientes ítems...` | Homogeneidad | Menos de 2 grupos (ítems) en el ANOVA. | Asegúrese de que el CSV tenga al menos 2 `sample_id` diferentes por nivel. |
| `replacement has length zero` | Cálculos | Función retornó `NULL`. | Verifique valores `NA` en los datos de entrada o filtros que resultan vacíos. |
| `there is no package called 'ptcalc'` | Inicio | Paquete local no instalado. | Ejecute `devtools::install("ptcalc")` desde la raíz del proyecto. |
| `Error in algorithm_A(x) : Not enough data` | Algoritmo A | Menos de 3 participantes. | El Algoritmo A requiere $n \geq 3$. Agregue datos o use otro método. |

---

## Problemas de Formato de Datos

### Separador Decimal
**Problema:** La aplicación rechaza valores con comas (`,`) como decimales.
**Solución:** Use puntos (`.`).
*   Incorrecto: `0,0523`
*   Correcto: `0.0523`

### Codificación de Caracteres
**Problema:** Caracteres extraños en nombres de laboratorios o unidades (ej: `µmol`).
**Solución:** Guarde sus archivos CSV con codificación **UTF-8**.
*   En Excel: Guardar como -> CSV UTF-8 (delimitado por comas).

### Valores Faltantes
**Problema:** Celdas vacías o textos como "ND".
**Solución:**
*   Use `NA` para valores faltantes si es necesario, pero es preferible eliminar la fila.
*   Asegúrese de que las columnas numéricas (`value`, `mean_value`) no contengan texto.

---

## Problemas de Rendimiento

### Archivos Grandes
Si la aplicación es lenta al cargar o calcular:
1.  **Aumente la memoria de R:** `memory.limit(size = ...)` en Windows.
2.  **Pre-agregación:** Si tiene miles de datos crudos, considere pre-procesarlos antes de subir si solo necesita el resumen.

### Gráficos Lentos
Los gráficos interactivos (`plotly`) pueden volverse lentos con >10,000 puntos.
*   **Solución:** Filtre los datos por nivel o contaminante para visualizar conjuntos más pequeños a la vez.

---

## Compatibilidad del Navegador

| Navegador | Estado | Notas |
|-----------|--------|-------|
| Chrome | Recomendado | Mejor rendimiento JS. |
| Firefox | Soportado | Buen rendimiento. |
| Edge | Soportado | Basado en Chromium. |
| Safari | Soportado | Versiones antiguas pueden tener problemas de diseño. |
| IE 11 | No Soportado | No use Internet Explorer. |

**Nota sobre Descargas:** Asegúrese de que su bloqueador de ventanas emergentes (pop-ups) permita descargas desde la aplicación para la generación de informes.

---

## Cómo Reportar un Error

Si encuentra un error no listado aquí, por favor recopile:
1.  El mensaje de error exacto (copiar de la consola o UI).
2.  Una captura de pantalla si es un problema visual.
3.  Una muestra pequeña de los datos que causan el error (anonimizados).
4.  Los pasos exactos para reproducirlo.
