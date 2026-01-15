# Módulo Shiny: Informe Global

## 1. Descripción General
El módulo de Informe Global proporciona una vista de alto nivel de todo el esquema de ensayo de aptitud, agregando resultados a través de todos los contaminantes y niveles en mapas de calor y tablas de resumen.

**Ubicación del Archivo:** `cloned_app.R` (Pestaña "Informe global")

---

## 2. Arquitectura

### 2.1 Pipeline de Agregación de Datos
1.  **Disparador:** Reactivo `global_report_data()`.
2.  **Recolección:** Itera a través de todos los contaminantes (`CO, NO, NO2...`) y niveles disponibles.
3.  **Recuperación:** Obtiene puntajes en caché de `scores_results_cache`. Si una combinación específica no se ha ejecutado, la omite o muestra "N/A".
4.  **Filtrado:** Elimina el laboratorio de referencia (`participant_id == "ref"`) para centrarse en el desempeño de los participantes.
5.  **Pivote:** Transforma los datos en un formato de matriz adecuado para mapas de calor (Filas: Participantes, Cols: Contaminante/Nivel).

### 2.2 Lógica del Mapa de Calor
Utiliza `plotly::plot_ly` (traza de mapa de calor).

*   **Eje X:** Contaminante + Nivel (ej: "SO2-bajo").
*   **Eje Y:** ID del Participante.
*   **Valor Z:** El puntaje en sí (z, z', etc.) o un entero mapeado para clasificación discreta.
*   **Colores:** Escala de colores personalizada que coincide con la paleta oficial de semáforo (Verde/Amarillo/Rojo).

---

## 3. Reactivos Clave

### `global_report_summary()`
Genera la tabla de resumen basada en texto.
*   **Columnas:** Contaminante, Nivel, N (Participantes), Media, DE, Tasa de Aprobación (%).
*   **Cálculo de Tasa de Aprobación:**
    $$Tasa = \frac{\text{Conteo}(|z| \le 2)}{\text{Total Participantes}} \times 100$$

### `global_report_combos()`
Identifica combinaciones válidas de datos para poblar los selectores desplegables, asegurando que los usuarios no intenten ver mapas de calor vacíos.

---

## 4. Referencias Cruzadas

- **Puntajes PT:** [09_puntajes_pt.md](09_puntajes_pt.md)
- **Glosario:** [00_glossary.md](00_glossary.md)
