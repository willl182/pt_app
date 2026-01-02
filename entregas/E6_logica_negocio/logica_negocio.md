# Entregable 6.1: Lógica de Negocio y Flujo de Datos

Este documento detalla el funcionamiento interno del servidor de la aplicación (Server Logic), explicando cómo se procesan los datos y la interconexión entre los diferentes módulos reactivos.

## 1. El Motor Reactivo de Shiny

La aplicación utiliza objetos `reactive()`, `reactiveValues()` y `observeEvent()` para gestionar el estado y los cálculos.

### 1.1. Reactivos de Datos Base
- **`hom_data_full()`**: Carga y valida el archivo de homogeneidad.
- **`stab_data_full()`**: Carga y valida el archivo de estabilidad.
- **`pt_prep_data()`**: Procesa y agrega los datos de los participantes para los niveles de intercomparación.

### 1.2. Triggers (Disparadores)
Para evitar cálculos innecesarios en cada cambio de input, se utilizan disparadores manuales:
- `analysis_trigger()`: Se activa solo cuando el usuario presiona "Ejecutar análisis" en los módulos de preparación.
- `algoA_trigger()` / `scores_trigger()`: Gestionan la ejecución de los algoritmos de consenso y puntajes respectivamente.

## 2. Flujo de Procesamiento

El flujo de datos sigue una ruta lineal obligatoria:

1. **Ingesta:** Los datos brutos son limpiados y transformados a formato "wide" mediante `get_wide_data`.
2. **Preparación del Ítem:**
   - La lógica de `compute_homogeneity_metrics` deriva las varianzas ANOVA.
   - Estos resultados alimentan la lógica de estabilidad.
3. **Consenso y VA:**
   - Se procesan los promedios de los participantes.
   - El Algoritmo A itera sobre estos promedios para obtener $x^*$ y $s^*$.
4. **Cálculo de Desempeño:**
   - Se cruzan los valores asignados con los resultados individuales por participante.
   - Se generan las tablas finales de puntajes z, En y zeta.

## 3. Gestión de Cache

La aplicación mantiene los resultados en caches reactivos (`algoA_results_cache`, `scores_results_cache`) permitiendo que la navegación entre pestañas sea instantánea sin necesidad de recalcular. Los caches se limpian automáticamente si el usuario carga nuevos archivos de datos para mantener la integridad de los resultados.
