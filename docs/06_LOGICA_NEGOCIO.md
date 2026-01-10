# Lógica de Negocio y Reactividad

## Flujo de Datos Principal

1.  **Carga de Datos (`vroom`, `reactive`)**
    *   `hom_data_full`: Datos crudos de homogeneidad.
    *   `stab_data_full`: Datos crudos de estabilidad.
    *   `pt_prep_data`: Datos resumen de participantes (procesados desde múltiples CSVs).

2.  **Preparación de Datos (`R/homogeneity_stability.R`)**
    *   `get_wide_data`: Transforma formato largo a ancho (replicates en columnas) para cálculos de ANOVA.

3.  **Cálculos Estadísticos (Bajo demanda)**
    *   **Homogeneidad (`homogeneity_run`):** Se dispara al pulsar "Ejecutar". Llama a `compute_homogeneity_metrics`.
    *   **Estabilidad (`stability_run`):** Depende de `homogeneity_run`. Llama a `compute_stability_metrics`.
    *   **Algoritmo A (`algorithm_a_selected`):** Se dispara específicamente para la combinación seleccionada. Llama a `run_algorithm_a` (`R/robust_stats.R`).
    *   **Puntajes (`scores_run`):** Itera sobre todas las combinaciones disponibles en los datos resumen y pre-calcula todos los puntajes (Z, Z', Zeta, En) para todos los métodos (Ref, Consenso, Algo A). Almacena en cache (`scores_results_cache`).

4.  **Generación de Reportes (`rmarkdown`)**
    *   Recopila los estados reactivos actuales (tablas de resultados, conclusiones).
    *   Pasa estos objetos como `params` a la plantilla `report_template.Rmd`.
    *   La plantilla renderiza las tablas y gráficos estáticos para el documento final.

## Dependencias Críticas
*   Los cálculos de estabilidad requieren que el cálculo de homogeneidad sea exitoso (para obtener $\sigma_{pt}$ y media de referencia).
*   Los puntajes requieren que se haya definido un $x_{pt}$ y $\sigma_{pt}$. El módulo de puntajes calcula internamente estos valores para los métodos de consenso si es necesario, o usa la Referencia.

## Manejo de Errores
*   Uso de `validate(need(...))` para verificar estructura de archivos subidos.
*   Funciones de cálculo devuelven listas con campo `error` si fallan (e.g., insuficientes datos), lo que la UI renderiza como alertas rojas.
