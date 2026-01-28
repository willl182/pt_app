# 15. Inmersión Profunda en la Arquitectura del Sistema

| Propiedad | Valor |
|----------|-------|
| **Tipo de Documento** | Referencia de Arquitectura |
| **Archivo Principal** | `app.R` (aprox. 5,685 líneas) |
| **Paquete** | `ptcalc/` |
| **Arquitectura** | MVC (Modelo-Vista-Controlador) con Programación Reactiva |
| **Docs Relacionados** | `02_paquete_ptcalc.md`, `README.md`, `01_carga_datos.md`, `03_estadisticas_robustas_pt.md`, `05_puntajes_pt.md` |

---

## 1. Descripción General

La aplicación PT sigue una **clara separación de responsabilidades** y una arquitectura **Modelo-Vista-Controlador (MVC)** simplificada:

*   **Vista (UI):** Definida mediante `fluidPage` con estilos de `bslib`. Gestiona la interfaz de usuario y los componentes de entrada/salida.
*   **Controlador (Servidor):** Manejadores de eventos reactivos en `app.R` que orquestan las funciones del paquete, gestionan el estado y manejan los eventos del usuario.
*   **Modelo (Lógica/Datos):** 
    *   **`ptcalc/`**: Un paquete de R puro que contiene las funciones matemáticas y la lógica de negocio (sin dependencias de Shiny).
    *   **Procesadores de Datos Reactivos**: Reactivos internos en la lógica del servidor que manejan la transformación y agregación de datos.

### Beneficios Clave
- **Pruebas Unitarias**: Los cálculos pueden probarse independientemente de la interfaz de usuario a través del paquete `ptcalc`.
- **Reutilización**: Las funciones de `ptcalc` pueden usarse en otros contextos como scripts o informes automatizados.
- **Desempeño**: Los límites claros permiten estrategias de optimización y almacenamiento en caché dirigidas.

---

## 2. Gráficos de Dependencias

### 2.1 Gráfico Completo de Dependencias Reactivas
Este gráfico ilustra el flujo desde las entradas del lado del cliente a través de la capa reactiva hasta el paquete de cálculo central y, finalmente, a la capa de visualización.

```mermaid
graph TD
    subgraph Capa_Cliente["Capa de Cliente (UI)"]
        UI["Interfaz de Usuario"]
        INPUTS["Selectores de Entrada<br/>fileInput, selectInput, sliderInput"]
        OUTPUTS["Salidas<br/>Tablas, Gráficos, Informes"]
    end
    
    subgraph Capa_Reactiva["Capa Reactiva (Servidor)"]
        DL["Reactivos de Carga de Datos<br/>hom_data_full(), stab_data_full(), pt_prep_data()"]
        VR["Valores Reactivos<br/>rv$raw_summary_data, rv$raw_summary_data_list"]
        AL["Reactivos de Análisis<br/>homogeneity_run(), stability_run()"]
        TR["Valores de Disparo (Trigger)<br/>analysis_trigger, algoA_trigger, consensus_trigger, scores_trigger"]
        CACHE["Reactivos de Caché<br/>algoA_results_cache, consensus_results_cache, scores_results_cache"]
        METROLOGICAL["Compatibilidad Metrológica<br/>metrological_compatibility_data()"]
    end
    
    subgraph Capa_Calculo["Capa de Cálculo (ptcalc)"]
        ROBUST["Estadísticas Robustas<br/>algorithm_A(), calculate_niqr(), calculate_made()"]
        HOM["Homogeneidad<br/>calculate_s_within(), calculate_s_between()"]
        STAB["Estabilidad<br/>stability_test()"]
        SCORES["Puntuación<br/>calculate_z_score(), calculate_z_prime(), calculate_zeta(), calculate_en()"]
        CONSENSUS["Consenso<br/>simple_robust_stats()"]
    end
    
    subgraph Capa_Visualizacion["Capa de Visualización"]
        PLOTS["Gráficos Plotly<br/>dispersión, histogramas, boxplots"]
        TABLES["DataTables<br/>tablas de resultados, tablas de puntajes"]
        REPORTS["Informes RMarkdown<br/>exportaciones HTML/Word"]
    end

    INPUTS --> DL
    DL --> VR
    VR --> AL
    AL --> ROBUST
    AL --> HOM
    AL --> STAB
    AL --> CONSENSUS
    TR --> CACHE
    CACHE --> SCORES
    ROBUST --> SCORES
    CONSENSUS --> SCORES
    CONSENSUS --> METROLOGICAL
    HOM --> METROLOGICAL
    STAB --> METROLOGICAL
    METROLOGICAL --> TABLES
    METROLOGICAL --> REPORTS
    SCORES --> PLOTS
    SCORES --> TABLES
    SCORES --> REPORTS
    PLOTS --> OUTPUTS
    TABLES --> OUTPUTS
    REPORTS --> OUTPUTS
    UI -.-> INPUTS
    OUTPUTS -.-> UI
```

### 2.2 Flujo de Datos Principal
```mermaid
flowchart TD
    subgraph "Entradas de Archivos"
        HF[input$hom_file]
        SF[input$stab_file]
        SUM[input$summary_files]
    end

    subgraph "Reactivos de Datos Brutos"
        HDF[hom_data_full]
        SDF[stab_data_full]
        PPD[pt_prep_data]
    end

    subgraph "Datos Procesados"
        RD[raw_data]
        SDR[stability_data_raw]
        RV[rv$raw_summary_data]
    end

    subgraph "Resultados del Análisis"
        HR[homogeneity_run]
        SR[stability_run]
    end

    HF --> HDF --> RD --> HR
    SF --> SDF --> SDR --> SR
    SUM --> PPD --> RV --> SR
```

#### 2.2.1 Reactivos de Disparo/Caché (Trigger/Cache)
Los cálculos de alto costo utilizan disparadores explícitos y resultados almacenados en caché para evitar repetir el trabajo cuando los filtros o las entradas de la UI cambian.

| Reactivos de Disparo | Reactivos de Caché | Uso Típico |
|------------------|-----------------|-------------|
| `analysis_trigger()` | - | Ejecución de homogeneidad/estabilidad |
| `algoA_trigger()` | `algoA_results_cache()` | Iteraciones del Algoritmo A |
| `consensus_trigger()` | `consensus_results_cache()` | Valores de consenso (2a/2b) |
| `scores_trigger()` | `scores_results_cache()` | Puntajes PT finales (z, z', zeta, En) |

### 2.3 Cadena de Cálculo de Puntajes
```mermaid
flowchart TD
    BTN[clic en botón<br/>input$scores_run] --> OE[observeEvent]
    
    OE --> LOOP{Para cada<br/>analito/nivel/n_lab}
    
    LOOP --> CSF[compute_scores_for_selection]
    
    CSF --> CHM[compute_homogeneity_metrics]
    CSF --> CSM[compute_stability_metrics]
    CSF --> RAA[run_algorithm_a]
    
    CHM --> |sigma_pt, u_xpt| CCS[compute_combo_scores]
    CSM --> |u_stab| CCS
    RAA --> |assigned_value, robust_sd| CCS
    
    CCS --> |para cada método| CACHE[scores_results_cache]
    
    CACHE --> TRIG[scores_trigger]
    TRIG --> SRS[scores_results_selected]
    SRS --> OUT[Tablas/gráficos de salida]
```

### 2.4 Flujo de Compatibilidad Metrológica
```mermaid
flowchart LR
    REF[Valores de Referencia] --> COMP[Compatibilidad Metrológica]
    CONSENSUS[Valores de Consenso 2a/2b/3] --> COMP
    HOM[Homogeneidad u_hom] --> COMP
    STAB[Estabilidad u_stab] --> COMP
    COMP --> TABLE[Salida de Tabla de Compatibilidad]
```

---

## 3. Estructura de la Función del Servidor

La función del servidor está organizada en secciones lógicas que cubren la carga de datos, el procesamiento y la lógica específica del módulo.

| Sección | Líneas (aprox.) | Propósito |
|---------|-----------------|---------|
| **Carga de Datos** | 80-160 | Reactivos de carga de archivos y validación (`hom_data_full`, `stab_data_full`, `pt_prep_data`) |
| **Configuración de Disparador/Caché** | 161-224 | Definiciones de disparadores, inicialización de caché y manejadores de reinicio |
| **Funciones Auxiliares** | 226-638 | Lógica interna para la conversión de datos anchos y cálculo de métricas |
| **Manejador del Algoritmo A** | 642-715 | `observeEvent(input$algoA_run)` - estimación robusta iterativa |
| **Diseño de UI Dinámico** | 717-1165 | Renderizado de `output$main_layout` para el navlistPanel adaptativo |
| **Homogeneidad/Estabilidad** | 1168-1390 | Reactivos de análisis central y salidas de incertidumbre |
| **Tablas de Incertidumbre** | 1291-1389 | Generación de `u_hom_data` y `u_stab_data` |
| **Salidas de Vista Previa de Datos** | 1391-1718 | Tablas, histogramas y visualizaciones de validación |
| **Módulo de Puntajes PT** | 1720-2255 | Selectores de puntajes y lógica de cálculo multimétodo |
| **Módulo de Informe Global** | 2256-3237 | Mapas de calor agregados, tablas resumen y clasificación |
| **Módulo de Participantes** | 3238-3746 | Vistas individuales de laboratorio y gráficos de desempeño |
| **Generación de Informes** | 3748-4690 | Renderizado de RMarkdown y `downloadHandler` |
| **Módulo de Valor Asignado** | 4715-5042 | Controles manuales para los valores de consenso y referencia |
| **Módulo de Valores Atípicos** | 5114-5176 | Visualización y análisis de la prueba de Grubbs |

---

## 4. Gestión del Estado

La aplicación utiliza mecanismos específicos para gestionar el estado y asegurar el desempeño.

### 4.1 Valores Reactivos (`rv`)
Se utilizan para almacenar el estado mutable que necesita persistir a través de las evaluaciones reactivas o ser modificado dentro de los observadores.

| Variable | Tipo | Propósito | Actualizado Por |
|----------|------|---------|------------|
| `rv$raw_summary_data` | `data.frame` | Datos resumen combinados de todos los archivos cargados | `pt_prep_data()` |
| `rv$raw_summary_data_list` | `list` | Dataframes individuales (uno por archivo cargado) | `pt_prep_data()` |

### 4.2 Patrón Disparador-Caché (Trigger-Cache)
Para los cálculos costosos (como el Algoritmo A o la puntuación multiesquema), la aplicación utiliza un **patrón disparador-caché**. Esto evita recálculos innecesarios y otorga a los usuarios un control explícito.

El impacto en el desempeño: los resultados almacenados en caché permanecen estables a través de las actualizaciones de la UI hasta que se dispara explícitamente un disparador, lo que reduce la rotación de reactividad cuando los usuarios refinan los filtros o exportan informes.

```mermaid
graph LR
    A[Usuario hace clic en el botón] --> B[observeEvent establece disparador]
    B --> C[la marca de tiempo del disparador cambia]
    C --> D[el reactivo se invalida]
    E[se ejecuta el cálculo]
    E --> F[los resultados se almacenan en caché]
    F --> G[la salida se actualiza]
    D --> E
```

#### Implementación de Disparador-Caché
1. **Inicializar**: `scores_results_cache <- reactiveVal(NULL)` y `scores_trigger <- reactiveVal(NULL)`.
2. **Disparar**: El usuario hace clic en ejecutar -> calcular todo -> `scores_results_cache(results)` -> `scores_trigger(Sys.time())`.
3. **Control (Gate)**: Los reactivos de resultados utilizan `req(scores_trigger())` para esperar la acción explícita del usuario.

#### Pares Principales de Disparador-Caché
| Disparador | Caché | Propósito |
|---------|-------|---------|
| `analysis_trigger()` | - | Ejecución de homogeneidad/estabilidad |
| `algoA_trigger()` | `algoA_results_cache()` | Resultados iterativos del Algoritmo A |
| `consensus_trigger()` | `consensus_results_cache()` | Estadísticas robustas (MADe/nIQR) |
| `scores_trigger()` | `scores_results_cache()` | Puntajes PT finales (z, z', zeta, En) |

### 4.3 Invalidación del Caché
Cuando los archivos resumen cambian, todos los cachés descendentes se limpian automáticamente para evitar datos obsoletos:
```mermaid
flowchart TD
    SUM[cambios en input$summary_files] --> OE[observeEvent]
    OE --> CL[Limpiar todos los cachés: algoA, consenso, scores]
    OE --> RT[Restablecer todos los disparadores a NULL]
```

---

## 5. Optimización del Desempeño

### 1. Procesamiento por Lotes (Batch)
En lugar de actualizaciones reactivas individuales, todas las combinaciones se procesan en un solo bucle durante el clic de un botón:
```r
observeEvent(input$algoA_run, {
  combos <- unique(data[, c("pollutant", "n_lab", "level")])
  results <- list()
  for (i in seq_len(nrow(combos))) {
    key <- paste(combos$pollutant[i], combos$n_lab[i], combos$level[i], sep = "||")
    results[[key]] <- run_algorithm_a(...)
  }
  algoA_results_cache(results) # Actualización única
})
```

### 2. Búsquedas por Clave Compuesta
Utiliza el formato `analito||n_lab||nivel` para el acceso al caché O(1) en lugar del costoso filtrado de dataframes.

### 3. Aislamiento Reactivo
Utiliza `isolate()` para evitar la re-ejecución al leer valores que no deberían disparar actualizaciones.

### 4. Renderizado y Carga
- **vroom**: Utiliza `vroom::vroom` para una lectura de CSV rápida y perezosa (lazy).
- **DataTables**: Implementa el procesamiento del lado del servidor (`server = TRUE`) para tablas responsivas con grandes conjuntos de datos.
- **Vectorización**: Las funciones centrales en `ptcalc` están vectorizadas para minimizar los bucles a nivel de R.

---

## 6. Arquitectura de Manejo de Errores

### 1. Capas de Validación
- **Validación de Entradas**: Restricciones de la UI y `validate(need())` para errores de cara al usuario.
- **Validación Reactiva**: Verifica la disponibilidad de los datos antes del procesamiento (`req()`).
- **Validación Matemática**: Verificaciones internas en `ptcalc` para datos suficientes (ej., $n \ge 3$ para el Algoritmo A).

### 2. Patrón de Lista de Errores
Las funciones devuelven una lista estructurada que contiene tanto el resultado como un mensaje de error opcional:
```r
# Patrón
list(result = calculo, error = NULL)
# En caso de falla
list(result = NULL, error = "Réplicas insuficientes...")
```

### 3. Flujo de Propagación de Errores
```
Error de Usuario -> Validación UI -> Puerta Reactiva -> Verificación del Paquete -> Visualización de Error Estructurado
```

---

## 7. Integración con el Paquete ptcalc

El paquete `ptcalc` sirve como el núcleo matemático.

### 7.1 Funciones Exportadas Clave
| Categoría | Funciones |
|----------|-----------|
| **Estadísticas Robustas** | `calculate_niqr()`, `calculate_mad_e()`, `run_algorithm_a()` |
| **Homogeneidad** | `calculate_homogeneity_stats()`, `evaluate_homogeneity()`, `calculate_u_hom()` |
| **Estabilidad** | `calculate_stability_stats()`, `evaluate_stability()`, `calculate_u_stab()` |
| **Puntajes** | `calculate_z_score()`, `calculate_z_prime_score()`, `calculate_zeta_score()`, `calculate_en_score()` |
| **Evaluación** | `evaluate_z_score_vec()`, `evaluate_en_score_vec()` |

### 7.2 Método de Integración
La aplicación carga el paquete al inicio mediante `library(ptcalc)`. Durante el desarrollo, se utiliza `devtools::load_all("ptcalc")` para sincronizar los cambios.

---

## 8. Secuencia del Flujo de Datos
```mermaid
sequenceDiagram
    participant U as Usuario
    participant UI as UI
    participant S as Reactivos del Servidor
    participant P as Paquete ptcalc
    participant C as Caché
    
    U->>UI: Subir archivos CSV
    UI->>S: input$files
    S->>S: Validar columnas y almacenar en rv
    U->>UI: Clic en "Calcular Puntajes"
    UI->>S: scores_run
    S->>C: Verificar clave de caché
    alt Fallo de Caché (Miss)
        S->>P: Llamar a ptcalc::compute_combo_scores
        P-->>S: Retornar puntajes
        S->>C: Actualizar caché
    end
    S->>UI: Actualizar mapas de calor Plotly y tablas DT
```

---

## 9. Concurrencia e Hilos
- **Estado Actual**: La aplicación es de un solo hilo (single-threaded). Shiny gestiona la cola reactiva.
- **Gestión del Desempeño**: El trabajo pesado se mitiga mediante el patrón disparador-caché y el procesamiento por lotes en lugar de la paralelización.
- **Oportunidad Futura**: Implementación de `future` y `promises` para el análisis independiente de contaminantes.

---

## 10. Ver También
- [01_carga_datos.md](01_carga_datos.md) - Cadenas detalladas de carga de datos.
- [03_estadisticas_robustas_pt.md](03_estadisticas_robustas_pt.md) - Detalles de la implementación del Algoritmo A.
- [02a_api_ptcalc.md](02a_api_ptcalc.md) - Referencia completa de la API del paquete.
- [09_puntajes_pt.md](09_puntajes_pt.md) - Implementación del módulo de puntuación.
