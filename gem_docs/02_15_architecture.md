# System Architecture

## 1. Overview
The application follows a standard Shiny implementation of the Model-View-Controller (MVC) pattern, although simplified as "UI-Server-Global".

*   **View (UI):** `fluidPage` with `bslib` styling.
*   **Controller (Server):** Reactive event handlers managing user input.
*   **Model (Logic):** Pure functions in `ptcalc` and reactive data processors in `cloned_app.R`.

## 2. Dependency Graph

```mermaid
graph TD
    subgraph Client Layer
        UI[User Interface]
        Inputs[Input Selectors]
        Outputs[Tables/Plots]
    end
    
    subgraph Reactive Layer
        DL[Data Loading Reactives]
        AL[Analysis Reactives]
        VR[Visual Rendering]
    end
    
    subgraph Calculation Layer (ptcalc)
        Robust[Robust Stats]
        Hom[Homogeneity]
        Scores[Scoring]
    end

    Inputs --> DL
    DL --> AL
    AL --> Robust
    AL --> Hom
    AL --> Scores
    AL --> VR
    VR --> Outputs
```

## 3. State Management

The application uses specific mechanisms to manage state across the session.

### 3.1 `reactiveValues`
Used for storing state that needs to persist or be mutated within observers.
*   `rv$raw_summary_data`: Stores the loaded participant data.
*   `rv$raw_summary_data_list`: Stores the raw file references.

### 3.2 `reactiveVal` as Cache
Used extensively to cache expensive calculation results.
*   `algoA_results_cache`: Stores Algorithm A convergence results.
*   `scores_results_cache`: Stores the final scoring dataframe.
*   `consensus_results_cache`: Stores simple robust stats (MADe/nIQR).

**Pattern:**
1.  User clicks "Run".
2.  Observer checks input parameters.
3.  If params match cache key, return cache.
4.  Else, run calculation -> update cache -> return result.

## 4. Performance Considerations
*   **Data Size:** The app uses `vroom` for fast CSV reading.
*   **Rendering:** Tables use `DT::renderDataTable` with server-side processing for large datasets.
*   **Vectorization:** All `ptcalc` functions are vectorized where possible.
