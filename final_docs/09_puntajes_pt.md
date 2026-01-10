# Módulo Shiny: Puntajes PT

## 1. Descripción General
Este módulo orquesta el cálculo de todos los puntajes de desempeño ($z, z', \zeta, E_n$) y los visualiza. Es el motor analítico central para la evaluación de los participantes.

**Ubicación del Archivo:** `cloned_app.R` (Pestaña "Puntajes PT")

---

## 2. Pipeline de Cálculo

### 2.1 La Función `compute_scores_metrics`
Esta es una función contenedora masiva que:
1.  **Agrega Entradas:** Recolecta $x_{pt}$, $\sigma_{pt}$, $u(x_{pt})$ de módulos anteriores.
2.  **Itera:** Recorre cada participante en el conjunto de datos seleccionado.
3.  **Calcula:** Llama a `ptcalc::calculate_*_score` para cada métrica.
4.  **Clasifica:** Aplica la lógica de clasificación `a1-a7`.
5.  **Retorna:** Un dataframe estandarizado listo para graficar.

### 2.2 Comportamiento de Cambio de Pestaña
La UI utiliza un `tabsetPanel` para mostrar diferentes puntajes.
*   **Pestañas:** z-score, z'-score, zeta-score, En-score.
*   **Optimización:** Todos los puntajes se calculan de una vez cuando se hace clic en "Calcular Puntajes". Cambiar de pestaña simplemente revela columnas diferentes del dataframe *ya calculado*, asegurando una respuesta instantánea de la UI.

---

## 3. Lógica de Visualización

### 3.1 Generación de Gráficos (`plot_scores`)
Utiliza `ggplot2` para crear gráficos de desempeño estandarizados.

*   **Eje X:** ID del Participante (ordenado).
*   **Eje Y:** Valor del puntaje.
*   **Zonas:**
    *   Zona Verde: $\pm 2$
    *   Zona Amarilla: $\pm 3$
    *   Zona Roja: $> \pm 3$
*   **Características:**
    *   Líneas horizontales en los límites (+2, -2, +3, -3).
    *   Puntos coloreados por estado.
    *   Tooltips interactivos (vía conversión `plotly`).

### 3.2 Estrategia de Caché
Para prevenir recálculos pesados cada vez que un usuario ve un gráfico:
*   `scores_results_cache()` almacena el dataframe calculado completo.
*   Los gráficos dependen de este caché, no de la función de cálculo cruda.
*   El caché se invalida solo cuando se cargan nuevos datos o cambian parámetros significativos.

---

## 4. Fragmento de Código: Clasificación de Puntajes
```r
# Lógica simplificada del servidor
mutate(
  z_class = case_when(
    abs(z) <= 2 ~ "Satisfactorio",
    abs(z) > 2 & abs(z) < 3 ~ "Cuestionable",
    abs(z) >= 3 ~ "No Satisfactorio"
  ),
  # Mapeo de colores para UI
  color = case_when(
    z_class == "Satisfactorio" ~ "#4DB848", # Verde
    z_class == "Cuestionable" ~ "#FDB913", # Amarillo
    z_class == "No Satisfactorio" ~ "#E03C31" # Rojo
  )
)
```
