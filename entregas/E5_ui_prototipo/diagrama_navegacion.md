# Entregable 5.2: Diagrama de Navegación de la UI

**Proyecto:** Aplicativo para Evaluación de Ensayos de Aptitud (PT App)  
**Organización:** Laboratorio CALAIRE - Universidad Nacional de Colombia  
**Fecha:** 2026-01-03

---

## 1. Flujo Principal de Trabajo

El siguiente diagrama representa el flujo lógico que debe seguir el usuario para completar un ejercicio de intercomparación:

```mermaid
flowchart TD
    Start((🏠 Inicio)) --> Load[📂 Carga de Datos]
    
    subgraph Preparación ["1️⃣ Preparación del Ítem"]
        Load --> Hom[🔬 Homogeneidad]
        Hom --> HCheck{¿Cumple?}
        HCheck -->|Sí| Stab[⏱️ Estabilidad]
        HCheck -->|No| HFail[❌ Revisar Ítem]
        Stab --> SCheck{¿Estable?}
        SCheck -->|Sí| VA
        SCheck -->|No| SFail[❌ Revisar Condiciones]
    end
    
    subgraph ValorAsignado ["2️⃣ Cálculo del Valor Asignado"]
        VA{Método} --> Ref[📌 Referencia]
        VA --> Cons[📊 Consenso]
        VA --> Algo[🔄 Algoritmo A]
    end
    
    subgraph Evaluacion ["3️⃣ Evaluación del Desempeño"]
        Ref & Cons & Algo --> Scores[📈 Puntajes PT]
        Scores --> Global[🗺️ Informe Global]
        Global --> Indiv[👤 Informes Individuales]
    end
    
    subgraph Salida ["4️⃣ Generación de Informes"]
        Indiv --> Report[📄 Descargar Word]
        Report --> End((✅ Fin))
    end
    
    style Start fill:#4CAF50,color:white
    style End fill:#2196F3,color:white
    style HFail fill:#f44336,color:white
    style SFail fill:#f44336,color:white
```

---

## 2. Mapa de Navegación Detallado

### 2.1. Estructura de Pestañas

```mermaid
graph LR
    subgraph NavPanel["Panel de Navegación"]
        N1[Inicio]
        N2[Carga de Datos]
        N3[Homogeneidad]
        N4[Estabilidad]
        N5[Valor Referencia]
        N6[Valor Consenso]
        N7[Algoritmo A]
        N8[Puntajes PT]
        N9[Informe Global]
        N10[Informes Indiv.]
        N11[Participantes]
    end
    
    N1 --> Content1[Instrucciones]
    N2 --> Content2[FileInputs + Preview]
    N3 --> Content3[ANOVA + Boxplot]
    N4 --> Content4[Comparación + Gráfico]
    N5 --> Content5[Entrada Manual]
    N6 --> Content6[MADe / nIQR]
    N7 --> Content7[Iteraciones]
    N8 --> Content8[Tabla + Barras]
    N9 --> Content9[Heatmap]
    N10 --> Content10[Matriz Individual]
    N11 --> Content11[Edición rhandsontable]
```

### 2.2. Dependencias entre Módulos

```mermaid
graph TD
    subgraph Datos["Entrada de Datos"]
        D1[("hom_file")]
        D2[("stab_file")]
        D3[("summary_files")]
    end
    
    subgraph Reactivos["Reactivos Intermedios"]
        R1["hom_data_full()"]
        R2["stab_data_full()"]
        R3["pt_prep_data()"]
    end
    
    subgraph Calculos["Cálculos"]
        C1["compute_homogeneity_metrics()"]
        C2["compute_stability_metrics()"]
        C3["run_algorithm_a()"]
        C4["compute_scores_metrics()"]
    end
    
    D1 --> R1
    D2 --> R2
    D3 --> R3
    
    R1 --> C1
    R2 & C1 --> C2
    R3 --> C3
    R3 & C3 --> C4
```

---

## 3. Flujo de Datos por Módulo

### 3.1. Módulo: Carga de Datos

```mermaid
sequenceDiagram
    participant U as Usuario
    participant UI as fileInput
    participant S as Server
    participant V as Validación
    participant P as Preview
    
    U->>UI: Selecciona archivo CSV
    UI->>S: input$hom_file
    S->>V: Verificar columnas
    alt Columnas válidas
        V->>S: OK
        S->>P: Renderizar tabla
        P->>U: Mostrar vista previa
    else Columnas faltantes
        V->>S: Error
        S->>U: Mensaje de validación
    end
```

### 3.2. Módulo: Homogeneidad

```mermaid
sequenceDiagram
    participant U as Usuario
    participant F as Filtros
    participant B as Botón Ejecutar
    participant C as compute_homogeneity_metrics
    participant T as Tabla Resultados
    participant G as Gráfico Boxplot
    
    U->>F: Selecciona pollutant, level
    U->>B: Clic "Ejecutar Análisis"
    B->>C: Trigger analysis_trigger
    C->>C: Calcular ss, sw, σpt
    C->>T: Renderizar resultados
    C->>G: Renderizar boxplot
    T->>U: Ver parámetros
    G->>U: Ver distribución
```

### 3.3. Módulo: Puntajes PT

```mermaid
sequenceDiagram
    participant U as Usuario
    participant P as Parámetros
    participant B as Botón Calcular
    participant S as compute_scores_metrics
    participant T as Tabla Puntajes
    participant G as Gráfico Barras
    participant D as Download
    
    U->>P: Ingresa σpt, u_xpt, k
    U->>B: Clic "Calcular Puntajes"
    B->>S: Trigger scores_trigger
    S->>S: Calcular z, z', zeta, En
    S->>T: Tabla con evaluaciones
    S->>G: Barras codificadas
    T->>U: Ver resultados
    U->>D: Descargar informe
```

---

## 4. Estados de la Aplicación

### 4.1. Diagrama de Estados

```mermaid
stateDiagram-v2
    [*] --> SinDatos: Iniciar App
    
    SinDatos --> DatosHom: Cargar homogeneity.csv
    SinDatos --> DatosStab: Cargar stability.csv
    SinDatos --> DatosSummary: Cargar summary_*.csv
    
    DatosHom --> DatosCompletos: + stability + summary
    DatosStab --> DatosCompletos: + homogeneity + summary
    DatosSummary --> DatosCompletos: + homogeneity + stability
    
    DatosCompletos --> AnálisisListo: Ejecutar Homogeneidad
    AnálisisListo --> VACalculado: Calcular Valor Asignado
    VACalculado --> PuntajesListos: Calcular Puntajes
    PuntajesListos --> InformeGenerado: Descargar Informe
    
    InformeGenerado --> [*]
```

### 4.2. Validaciones por Estado

| Estado | Validación Requerida | Mensaje de Error |
|--------|---------------------|------------------|
| SinDatos | Ninguna | "Cargue sus archivos de datos" |
| DatosHom | Columnas: value, pollutant, level | "Archivo debe contener..." |
| DatosCompletos | Datos de ref en summary | "No se encontró participante 'ref'" |
| AnálisisListo | g ≥ 2, m ≥ 2 | "Se requieren al menos 2 ítems" |
| VACalculado | σpt > 0 | "La dispersión es insuficiente" |

---

## 5. Interacciones Usuario-Sistema

### 5.1. Acciones Principales

| Acción | Input | Trigger | Resultado |
|--------|-------|---------|-----------|
| Cargar archivo | fileInput | onChange | Reactivo se actualiza |
| Filtrar datos | selectizeInput | onChange | Vista se filtra |
| Ejecutar análisis | actionButton | onClick | Cálculo se ejecuta |
| Cambiar tema | themeSelector | onChange | CSS se recarga |
| Ajustar layout | sliderInput | onChange | Grid se redimensiona |
| Descargar informe | downloadButton | onClick | Word se genera |

### 5.2. Retroalimentación Visual

```mermaid
graph LR
    A[Acción del Usuario] --> B{¿Exitoso?}
    B -->|Sí| C[🟢 Resultados visibles]
    B -->|Proceso| D[🔄 Indicador de carga]
    B -->|No| E[🔴 Mensaje de error]
    
    C --> F[Tabla/Gráfico actualizado]
    D --> G[withProgress/spinner]
    E --> H[validate/shinyFeedback]
```

---

## 6. Navegación Condicional

### 6.1. Habilitación de Pestañas

```mermaid
graph TD
    T1[Carga de Datos] --> |Datos OK| T2[Homogeneidad]
    T2 --> |Cumple| T3[Estabilidad]
    T3 --> |Estable| T4[Valor Asignado]
    T4 --> |VA Calculado| T5[Puntajes PT]
    T5 --> |Puntajes OK| T6[Informes]
    
    T2 --> |No Cumple| X1[⚠️ Pestañas siguientes bloqueadas]
    T3 --> |Inestable| X2[⚠️ Pestañas siguientes bloqueadas]
```

### 6.2. Mensajes de Guía

| Pestaña | Condición | Mensaje |
|---------|-----------|---------|
| Homogeneidad | Sin archivo | "Primero cargue el archivo de homogeneidad" |
| Estabilidad | Sin homogeneidad | "Complete primero el análisis de homogeneidad" |
| Puntajes | Sin VA | "Calcule primero el valor asignado" |
| Informes | Sin puntajes | "No hay puntajes calculados para generar el informe" |

---

## 7. Flujo de Generación de Informes

```mermaid
flowchart LR
    subgraph Inputs
        I1[summary_data]
        I2[hom_data]
        I3[stab_data]
        I4[parámetros]
    end
    
    subgraph Proceso
        P1[downloadHandler]
        P2[rmarkdown::render]
        P3[knitr]
        P4[pandoc]
    end
    
    subgraph Output
        O1[📄 Informe.docx]
    end
    
    I1 & I2 & I3 & I4 --> P1
    P1 --> P2
    P2 --> P3
    P3 --> P4
    P4 --> O1
```

---

## 8. Casos de Uso

### 8.1. Caso: Evaluación Completa de un EA

```
1. Usuario carga homogeneity.csv
2. Usuario carga stability.csv
3. Usuario carga summary_n7.csv
4. Sistema valida todos los archivos ✓
5. Usuario navega a "Homogeneidad"
6. Usuario selecciona SO2 / level_1
7. Usuario hace clic en "Ejecutar Análisis"
8. Sistema muestra: ss=0.02, CUMPLE ✓
9. Usuario repite para Estabilidad → ESTABLE ✓
10. Usuario navega a "Algoritmo A"
11. Usuario ejecuta → x*=100.5, s*=5.2
12. Usuario navega a "Puntajes PT"
13. Usuario ingresa σpt=5.2, u_xpt=1.0, k=2
14. Usuario calcula → Tabla de resultados
15. Usuario descarga informe Word
```

### 8.2. Caso: Error en Datos

```
1. Usuario carga archivo con columnas incorrectas
2. Sistema muestra:
   "Error: El archivo debe contener las columnas 
    'value', 'pollutant' y 'level'"
3. Usuario corrige archivo
4. Usuario recarga → Validación exitosa
```

---

**Archivos del Entregable E5:**
- `prototipo_ui.md` — Estructura de componentes
- `diagrama_navegacion.md` — Este documento
