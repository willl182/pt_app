# Entregable 6.2: Dependencias Reactivas de la Aplicación

**Proyecto:** Aplicativo para Evaluación de Ensayos de Aptitud (PT App)  
**Organización:** Laboratorio CALAIRE - Universidad Nacional de Colombia  
**Fecha:** 2026-01-03

---

## 1. Introducción

Este documento mapea todas las dependencias reactivas de la aplicación, ilustrando cómo los cambios en los inputs se propagan a través del sistema hasta generar las salidas finales.

---

## 2. Grafo de Dependencias Global

```mermaid
graph TD
    subgraph "📂 Archivos de Entrada"
        F1[("hom_file")]
        F2[("stab_file")]
        F3[("summary_files")]
    end
    
    subgraph "🔄 Reactivos de Datos"
        R1["hom_data_full()"]
        R2["stab_data_full()"]
        R3["pt_prep_data()"]
    end
    
    subgraph "🎛️ Inputs de Usuario"
        I1["pollutant"]
        I2["level"]
        I3["n_lab"]
        I4["sigma_pt"]
        I5["u_xpt"]
        I6["k_factor"]
        I7["metric"]
    end
    
    subgraph "⚡ Triggers"
        T1{{"analysis_trigger"}}
        T2{{"algoA_trigger"}}
        T3{{"scores_trigger"}}
    end
    
    subgraph "🧮 Funciones de Cálculo"
        C1["compute_homogeneity_metrics()"]
        C2["compute_stability_metrics()"]
        C3["run_algorithm_a()"]
        C4["compute_scores_metrics()"]
    end
    
    subgraph "💾 Caches"
        CA1[("hom_results_cache")]
        CA2[("algoA_results_cache")]
        CA3[("scores_results_cache")]
    end
    
    subgraph "📊 Outputs"
        O1["Tabla Homogeneidad"]
        O2["Boxplot Homogeneidad"]
        O3["Tabla Estabilidad"]
        O4["Tabla Algoritmo A"]
        O5["Gráfico Convergencia"]
        O6["Tabla Puntajes"]
        O7["Gráfico Barras"]
        O8["Heatmap"]
        O9["📄 Informe Word"]
    end
    
    %% Conexiones de archivos a reactivos
    F1 --> R1
    F2 --> R2
    F3 --> R3
    
    %% Conexiones de reactivos e inputs a cálculos
    R1 & I1 & I2 & T1 --> C1
    R2 & I1 & I2 & C1 --> C2
    R3 & I1 & I2 & I3 & T2 --> C3
    R3 & I1 & I2 & I3 & I4 & I5 & I6 & T3 --> C4
    
    %% Conexiones a caches
    C1 --> CA1
    C3 --> CA2
    C4 --> CA3
    
    %% Conexiones a outputs
    C1 & CA1 --> O1 & O2
    C2 --> O3
    C3 & CA2 --> O4 & O5
    C4 & CA3 --> O6 & O7
    C4 & I7 --> O8
    CA1 & CA2 & CA3 --> O9
```

---

## 3. Dependencias por Módulo

### 3.1. Módulo de Carga de Datos

```mermaid
graph LR
    subgraph Input
        A1["input$hom_file"]
        A2["input$stab_file"]
        A3["input$summary_files"]
    end
    
    subgraph Proceso
        B1["vroom()"]
        B2["validate()"]
    end
    
    subgraph Reactivo
        C1["hom_data_full()"]
        C2["stab_data_full()"]
        C3["pt_prep_data()"]
    end
    
    subgraph Output
        D1["DTOutput: data_preview"]
        D2["selectizeInput: pollutant (actualiza opciones)"]
        D3["selectizeInput: level (actualiza opciones)"]
    end
    
    A1 --> B1 --> B2 --> C1 --> D1 & D2
    A2 --> B1 --> B2 --> C2
    A3 --> B1 --> B2 --> C3 --> D3
```

**Dependencias:**
| Reactivo | Depende de | Actualiza |
|----------|-----------|-----------|
| `hom_data_full()` | `input$hom_file` | `pollutant` choices, `data_preview` |
| `stab_data_full()` | `input$stab_file` | — |
| `pt_prep_data()` | `input$summary_files` | `level` choices, `n_lab` choices |

### 3.2. Módulo de Homogeneidad

```mermaid
graph TD
    subgraph Inputs
        I1["pollutant"]
        I2["level"]
        I3["run_hom_analysis (button)"]
    end
    
    subgraph Reactivos
        R1["hom_data_full()"]
        R2["analysis_trigger()"]
    end
    
    subgraph Cálculo
        C1["compute_homogeneity_metrics()"]
    end
    
    subgraph Cache
        CA["hom_results_cache"]
    end
    
    subgraph Outputs
        O1["hom_intermediate_table"]
        O2["hom_results_table"]
        O3["hom_boxplot"]
    end
    
    I1 & I2 --> C1
    I3 --> R2
    R1 & R2 --> C1
    C1 --> CA
    CA --> O1 & O2 & O3
```

**Flujo de invalidación:**
1. Usuario cambia `pollutant` → No recalcula (aislado por trigger)
2. Usuario cambia `level` → No recalcula (aislado por trigger)
3. Usuario presiona botón → Incrementa `analysis_trigger()`
4. `analysis_trigger()` cambia → Recalcula `compute_homogeneity_metrics()`
5. Resultado se guarda en cache
6. Outputs se actualizan

### 3.3. Módulo del Algoritmo A

```mermaid
graph TD
    subgraph Inputs
        I1["pollutant"]
        I2["level"]
        I3["n_lab"]
        I4["run_algo_a (button)"]
    end
    
    subgraph Reactivos
        R1["pt_prep_data()"]
        R2["algoA_trigger()"]
    end
    
    subgraph Cálculo
        C1["run_algorithm_a()"]
    end
    
    subgraph Cache
        CA["algoA_results_cache"]
    end
    
    subgraph Outputs
        O1["algo_a_summary"]
        O2["algo_a_iterations"]
        O3["algo_a_convergence_plot"]
    end
    
    I1 & I2 & I3 --> C1
    I4 --> R2
    R1 & R2 --> C1
    C1 --> CA
    CA --> O1 & O2 & O3
```

### 3.4. Módulo de Puntajes

```mermaid
graph TD
    subgraph Inputs
        I1["pollutant"]
        I2["level"]
        I3["n_lab"]
        I4["sigma_pt"]
        I5["u_xpt"]
        I6["k_factor"]
        I7["metric"]
        I8["calculate_scores (button)"]
    end
    
    subgraph Reactivos
        R1["pt_prep_data()"]
        R2["algoA_results_cache"]
        R3["scores_trigger()"]
    end
    
    subgraph Cálculo
        C1["compute_scores_metrics()"]
    end
    
    subgraph Cache
        CA["scores_results_cache"]
    end
    
    subgraph Outputs
        O1["scores_table"]
        O2["scores_barplot"]
        O3["scores_summary"]
    end
    
    I1 & I2 & I3 & I4 & I5 & I6 --> C1
    I8 --> R3
    R1 & R2 & R3 --> C1
    C1 --> CA
    CA & I7 --> O1 & O2 & O3
```

---

## 4. Matriz de Dependencias

### 4.1. Inputs → Reactivos

| Input | hom_data_full | stab_data_full | pt_prep_data | analysis_trigger | algoA_trigger | scores_trigger |
|-------|:-------------:|:--------------:|:------------:|:----------------:|:-------------:|:--------------:|
| hom_file | ✓ | | | | | |
| stab_file | | ✓ | | | | |
| summary_files | | | ✓ | | | |
| run_hom_analysis | | | | ✓ | | |
| run_algo_a | | | | | ✓ | |
| calculate_scores | | | | | | ✓ |

### 4.2. Reactivos → Cálculos

| Reactivo | compute_hom | compute_stab | run_algo_a | compute_scores |
|----------|:-----------:|:------------:|:----------:|:--------------:|
| hom_data_full | ✓ | | | |
| stab_data_full | | ✓ | | |
| pt_prep_data | | | ✓ | ✓ |
| analysis_trigger | ✓ | ✓ | | |
| algoA_trigger | | | ✓ | |
| scores_trigger | | | | ✓ |
| algoA_cache | | | | ✓ |
| hom_results | | ✓ | | |

### 4.3. Cálculos → Outputs

| Cálculo | Tablas | Gráficos | Informe |
|---------|:------:|:--------:|:-------:|
| compute_homogeneity | hom_intermediate, hom_results | hom_boxplot | ✓ |
| compute_stability | stab_results | stab_plot | ✓ |
| run_algorithm_a | algo_summary, algo_iter | convergence_plot | ✓ |
| compute_scores | scores_table | scores_bar, heatmap | ✓ |

---

## 5. Propagación de Cambios

### 5.1. Escenario: Usuario Carga Nuevo Archivo de Homogeneidad

```mermaid
sequenceDiagram
    participant U as Usuario
    participant FI as fileInput
    participant HDF as hom_data_full
    participant CACHE as Caches
    participant SEL as selectizeInputs
    participant PREV as data_preview
    
    U->>FI: Selecciona nuevo archivo
    FI->>HDF: Invalida reactivo
    HDF->>HDF: Lee y valida archivo
    HDF->>CACHE: Limpia caches dependientes
    HDF->>SEL: Actualiza opciones de pollutant
    HDF->>PREV: Actualiza vista previa
    Note over CACHE: hom_results_cache = NULL
    Note over CACHE: algoA_results_cache = NULL
    Note over CACHE: scores_results_cache = NULL
```

### 5.2. Escenario: Usuario Cambia Nivel de Concentración

```mermaid
sequenceDiagram
    participant U as Usuario
    participant SEL as selectizeInput (level)
    participant TRIG as analysis_trigger
    participant CALC as compute_*
    participant OUT as Outputs
    
    U->>SEL: Cambia level a "level_2"
    Note right of SEL: NO dispara recálculo
    Note right of SEL: Inputs aislados por trigger
    U->>U: Debe presionar "Ejecutar"
    U->>TRIG: Clic en botón
    TRIG->>CALC: trigger() + 1
    CALC->>OUT: Nuevos resultados
```

### 5.3. Escenario: Usuario Descarga Informe

```mermaid
sequenceDiagram
    participant U as Usuario
    participant DL as downloadButton
    participant DH as downloadHandler
    participant C1 as hom_cache
    participant C2 as algoA_cache
    participant C3 as scores_cache
    participant RMD as rmarkdown::render
    participant F as Archivo .docx
    
    U->>DL: Clic "Descargar Informe"
    DL->>DH: Ejecuta content()
    DH->>C1: Lee resultados homogeneidad
    DH->>C2: Lee resultados Algoritmo A
    DH->>C3: Lee resultados puntajes
    DH->>RMD: Pasa parámetros
    RMD->>F: Genera Word
    F->>U: Descarga
```

---

## 6. Aislamiento y Optimización

### 6.1. Uso de `isolate()`

```r
# Sin isolate - recalcula con CADA cambio de pollutant o level
bad_example <- reactive({
  compute_something(input$pollutant, input$level)  # ❌
})

# Con isolate - solo recalcula cuando trigger cambia
good_example <- eventReactive(analysis_trigger(), {
  pol <- isolate(input$pollutant)  # ✓
  lev <- isolate(input$level)      # ✓
  compute_something(pol, lev)
})
```

### 6.2. Patrón de Invalidación Controlada

```mermaid
graph TD
    subgraph "Sin Trigger (Problemático)"
        A1[pollutant cambia] --> B1[Recalcula]
        A2[level cambia] --> B1
        A3[n_lab cambia] --> B1
        B1 --> C1[3 recálculos innecesarios]
    end
    
    subgraph "Con Trigger (Óptimo)"
        A4[pollutant cambia] --> X1[No recalcula]
        A5[level cambia] --> X2[No recalcula]
        A6[n_lab cambia] --> X3[No recalcula]
        A7[Botón presionado] --> B2[1 recálculo]
    end
```

---

## 7. Diagrama de Estados Reactivos

```mermaid
stateDiagram-v2
    [*] --> Inicial: App inicia
    
    Inicial --> DatosDisponibles: Archivos cargados
    DatosDisponibles --> AnálisisEjecutado: Trigger activado
    AnálisisEjecutado --> ResultadosEnCache: Cálculo completado
    ResultadosEnCache --> OutputsActualizados: Render completado
    
    OutputsActualizados --> ResultadosEnCache: Navegar pestaña
    OutputsActualizados --> DatosDisponibles: Nuevo archivo
    
    note right of ResultadosEnCache
        Los resultados permanecen
        en cache hasta que se
        carguen nuevos datos
    end note
```

---

## 8. Resumen de Buenas Prácticas

| Práctica | Beneficio | Implementación |
|----------|-----------|----------------|
| Triggers manuales | Control de cuándo recalcular | `reactiveVal()` + `observeEvent()` |
| Cache de resultados | Evitar recálculos idénticos | `reactiveValues()` |
| `isolate()` | Leer sin crear dependencia | En `eventReactive()` |
| `req()` | Detener evaluación temprana | Al inicio de cada reactivo |
| Validación clara | Feedback al usuario | `validate(need(...))` |

---

**Archivos del Entregable E6:**
- `logica_negocio.md` — Flujo de datos y arquitectura
- `dependencias_reactivas.md` — Este documento
