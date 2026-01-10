# Módulo: Carga de datos

## Descripción
Este módulo gestiona la carga y validación inicial de archivos CSV. Es el punto de entrada para todas las etapas del análisis y garantiza integridad antes de ejecutar cálculos estadísticos.

---

## Ubicación en el código

| Elemento | Valor |
|---|---|
| Archivo | `cloned_app.R` |
| Líneas | 79–156 (server) |
| UI | `tabPanel("Carga de datos")` |
| Dependencias | `vroom`, `stringr`, `dplyr` |

---

## Flujo general de datos

```mermaid
flowchart TB
    subgraph ARCHIVOS[Archivos subidos]
        HOM[homogeneity.csv]
        STAB[stability.csv]
        SUM[summary_n*.csv]
    end

    subgraph VALIDACION[Capa de validación]
        V1[hom_data_full()]
        V2[stab_data_full()]
        V3[pt_prep_data()]
    end

    subgraph ALMACENAMIENTO[Almacenamiento reactivo]
        R1[hom_data_full]
        R2[stab_data_full]
        R3[rv$raw_summary_data]
        R4[rv$raw_summary_data_list]
    end

    subgraph PROCESO[Procesamiento]
        W[get_wide_data()]
        H[homogeneity_run()]
        S[stability_run()]
        P[Pipeline de puntajes]
    end

    ARCHIVOS --> VALIDACION
    VALIDACION --> ALMACENAMIENTO
    R1 --> W --> H
    R2 --> W --> S
    R3 --> P
```

---

## Archivos de entrada esperados

### 1. Homogeneidad (`homogeneity.csv`)

Formato largo. Cada fila es una medición.

```csv
"pollutant","level","replicate","sample_id","value"
"co","0-umol/mol",1,1,0.00670
"co","0-umol/mol",2,1,-0.04796
```

**Columnas clave**: `pollutant`, `level`, `value` (obligatorias). `replicate` y `sample_id` son necesarias para el pivote a formato ancho.

### 2. Estabilidad (`stability.csv`)

Mismo formato que homogeneidad, medido en el tiempo final.

### 3. Resúmenes de participantes (`summary_n*.csv`)

Incluye resultados agregados por participante. El número en el nombre del archivo se extrae como `n_lab`.

```csv
"pollutant","level","participant_id","replicate","sample_group","mean_value","sd_value"
"co","0-umol/mol","part_1",2,"1-10",-0.0279,0.0282
"co","0-umol/mol","ref",1,"1-10",-0.0217,0.0274
```

**Valores especiales**: `participant_id = "ref"` identifica el laboratorio de referencia.

---

## Reglas de validación

### Homogeneidad y estabilidad

- **Columnas requeridas**: `value`, `pollutant`, `level`.
- **Errores típicos**: se muestra un mensaje indicando columnas faltantes.

### Resúmenes de participantes

- **Columnas requeridas**: `participant_id`, `pollutant`, `level`, `mean_value`, `sd_value`.
- **Extracción de esquema**: se usa un regex sobre el nombre del archivo para determinar `n_lab`.
- **Mensajes de error**: si faltan columnas o no se puede extraer `n_lab`.

---

## Salidas reactivas

- `hom_data_full` y `stab_data_full`: datos largos para homogeneidad y estabilidad.
- `rv$raw_summary_data`: tabla con resultados agregados.
- `rv$raw_summary_data_list`: lista de archivos `summary_n*.csv` por esquema.

Estas salidas alimentan la transformación a formato ancho (`get_wide_data()`) y el cálculo de puntajes.
