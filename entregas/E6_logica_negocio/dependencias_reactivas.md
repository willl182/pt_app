# Entregable 6.2: Dependencias Reactivas de la Aplicación

Este diagrama visualiza cómo los cambios en los inputs del usuario (archivos o parámetros) se propagan a través de los diversos módulos reactivos hasta generar las salidas finales.

```mermaid
graph TD
    subgraph Inputs
        H_file[input$hom_file]
        S_file[input$stab_file]
        Sum_files[input$summary_files]
        Params[Parámetros de Evaluación]
    end

    subgraph "Reactivos Intermedios"
        H_data[hom_data_full]
        S_data[stab_data_full]
        P_data[pt_prep_data]
        Cache[Caches de Resultados]
    end

    subgraph "Triggers (Acción)"
        Ana_Trig{analysis_trigger}
        Score_Trig{scores_trigger}
    end

    subgraph "Cálculos Core"
        Hom_M[compute_homogeneity_metrics]
        Stab_M[compute_stability_metrics]
        AlgoA[run_algorithm_a]
        Scores_M[compute_scores_metrics]
    end

    %% Relaciones
    H_file --> H_data
    S_file --> S_data
    Sum_files --> P_data
    
    H_data & Ana_Trig --> Hom_M
    Hom_M & S_data --> Stab_M
    
    P_data --> AlgoA
    AlgoA & Score_Trig & Params --> Scores_M
    
    Scores_M --> Cache
    Cache --> Report[Generación de Reporte]
```

## Importancia de la Estructura

- **Desacoplamiento:** Los cálculos están aislados en funciones puras (sin dependencias reactivas internas), facilitando su testeo.
- **Eficiencia:** El uso de triggers previene que la aplicación se "congele" durante cambios menores en la UI, ejecutando los cálculos pesados solo cuando el usuario lo solicita explícitamente.
