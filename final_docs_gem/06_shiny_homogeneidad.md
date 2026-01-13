# Módulo Shiny: Homogeneidad y Estabilidad

## 1. Descripción General
Este módulo implementa la interfaz de usuario y la lógica reactiva para evaluar la homogeneidad y estabilidad de los ítems del ensayo de aptitud. Sirve como puente entre la entrada del usuario y las funciones estadísticas en el paquete `ptcalc`.

**Ubicación en Código:** `cloned_app.R` (Lógica: líneas ~239-486)

---

## 2. Mapa de Componentes UI

| Elemento UI | Tipo | ID de Entrada | ID de Salida | Reactivo Relacionado |
|:---|:---|:---|:---|:---|
| **Botón Ejecutar** | `actionButton` | `run_analysis` | - | `analysis_trigger()` |
| **Analito** | `selectInput` | `pollutant_analysis` | `pollutant_selector_analysis` | `homogeneity_run()` |
| **Nivel** | `selectInput` | `target_level` | `level_selector` | `homogeneity_run()` |
| **Caja de Conclusión** | `uiOutput` | - | `homog_conclusion` | `homogeneity_run()` |
| **Tabla de Resultados** | `tableOutput` | - | `variance_components` | `homogeneity_run()` |
| **Ejecutar Estabilidad** | `actionButton` | `run_stability` | - | `stability_trigger()` |

---

## 3. Lógica Reactiva

### 3.1 `homogeneity_run()`
**Disparador:** `input$run_analysis`

1.  **Recolección de Entradas:** Lee el contaminante y nivel seleccionados.
2.  **Obtención de Datos:** Llama a `get_wide_data(hom_data_full(), ...)` para preparar los datos.
3.  **Cálculo:** Llama a `ptcalc::calculate_homogeneity_stats()` para obtener $s_s$, $s_w$, medias, etc.
4.  **Evaluación:** Llama a `ptcalc::evaluate_homogeneity()` para comparar $s_s$ contra los criterios ($c, c'$).
5.  **Retorno:** Una lista completa que contiene estadísticas, tabla ANOVA y conclusiones de pasa/falla.

### 3.2 Manejo de Errores
Si faltan datos o son inválidos (por ejemplo, < 2 ítems), el reactivo devuelve una lista con una cadena `$error`. La interfaz de usuario muestra este mensaje de error en un cuadro de alerta rojo en lugar de bloquearse.

```r
if (g < 2) {
  return(list(error = "No hay suficientes ítems (se requieren al menos 2)..."))
}
```

---

## 4. Visualizaciones y Salidas

### 4.1 Tabla de Resultados (`variance_components`)
Muestra los resultados principales del ANOVA:
*   Media General ($\bar{x}_{pt}$)
*   DE Entre muestras ($s_s$)
*   DE Dentro de muestras ($s_w$)
*   DE Permitida ($\sigma_{pt}$)

### 4.2 Caja de Conclusión (`homog_conclusion`)
Salida HTML dinámica que cambia de color según el resultado:
*   **Verde:** PASA ($s_s \le c$)
*   **Amarillo:** PASA (Condicional, $s_s \le c'$)
*   **Rojo:** FALLA ($s_s > c'$)

---

## 5. Integración de Estabilidad

El análisis de estabilidad es un paso opcional que se ejecuta después de la homogeneidad.

*   **Reactivo:** `stability_run()`
*   **Dependencia:** Requiere que `homogeneity_run()` sea exitoso primero.
*   **Lógica:** Compara la media de las muestras de control de estabilidad contra la media de homogeneidad.
*   **Salida:** Agrega la incertidumbre de estabilidad ($u_{stab}$) al presupuesto final de incertidumbre.

---

## 6. Mensajes de Error Comunes

| Mensaje | Causa | Solución |
|---------|-------|----------|
| "No hay datos cargados" | No se han subido archivos CSV | Ir a pestaña "Carga de datos" y subir archivos. |
| "No se encontraron datos de homogeneidad..." | El analito seleccionado no está en el archivo | Verificar nombres en el CSV. |
| "No hay suficientes réplicas" | Menos de 2 columnas de datos | Asegurar que `replicate` tenga al menos 1 y 2. |
