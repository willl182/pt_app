# Funcionamiento del preprocesador

Este documento describe el flujo de preprocesamiento de datos en `pt_app`,
incluyendo la generacion posterior del archivo de ronda completa.

## Objetivo

El preprocesador transforma archivos crudos minuto a minuto de CALAIRE en
archivos consolidados que puede consumir el modulo de analisis de ensayos de
aptitud.

El flujo completo tiene dos partes:

1. Preprocesamiento de archivos crudos.
2. Consolidacion final de referencia y participantes en `ronda_<n>_completa.csv`.

Estas dos partes son pasos separados en la GUI.

## Ubicacion en la aplicacion

Desde la aplicacion Shiny:

1. Abrir **Preprocesador de datos**.
2. Cargar los archivos requeridos.
3. Usar **Ejecutar preprocesamiento**.
4. Usar **Generar ronda completa** en la seccion **Consolidacion final**.

El boton **Ejecutar preprocesamiento** no genera por si solo el archivo
`ronda_<n>_completa.csv`. Ese archivo se genera con el boton
**Generar ronda completa**.

## Entradas del preprocesador

### Datos crudos CALAIRE

Son archivos CSV minuto a minuto exportados desde CALAIRE. Se cargan en la GUI
como **datos crudos CALAIRE** y se guardan temporalmente en `data/raw/`.

Nombres esperados:

- `datos_estabilidad_homogeneidad.csv`: mediciones para estabilidad y
  homogeneidad.
- `datos_ronda.csv`: referencia principal de la ronda.
- `datos_ronda_part.csv`: participante procesado internamente, si aplica.
- `datos_ronda_2a.csv`, `datos_ronda_2b.csv`, etc.: subrondas de referencia.
- `datos_ronda_2a_part.csv`, `datos_ronda_2b_part.csv`, etc.: participantes
  asociados a subrondas.

Los archivos deben conservar columnas de fecha, hora, mediciones de analitos y
generadores.

### Tabla de niveles/generadores

Archivo CSV cargado como **tabla de niveles/generadores**.

Columnas requeridas:

- `pollutant`: analito en minusculas, por ejemplo `co`, `so2`, `no`, `no2`,
  `nox`, `o3`.
- `unit`: unidad del nivel, por ejemplo `umol/mol`, `nmol/mol`, `ppm` o `ppb`.
- `generator_col`: columna del archivo crudo que contiene el valor del
  generador.

Ejemplo:

```csv
pollutant,unit,generator_col
co,umol/mol,co_gen_ppm
so2,nmol/mol,so2_gen_ppb
o3,nmol/mol,o3_gen_ppb
```

### Diseno de estabilidad/homogeneidad

Archivo CSV cargado como **diseno de estabilidad/homogeneidad**.

Este archivo no contiene mediciones. Contiene el mapa que indica que bloques de
tiempo deben extraerse desde `datos_estabilidad_homogeneidad.csv`.

Columnas requeridas:

- `source`
- `pollutant`
- `instrument`
- `level`
- `replicate`
- `sample_id`
- `study_type`
- `start_timestamp`
- `end_timestamp`
- `source_column`
- `unit`
- `notes`

`start_timestamp` y `end_timestamp` deben usar el formato `YYYY-MM-DD HH:MM`.

## Que hace el preprocesador

El script principal es:

```text
scripts/aplicativo/preprocesar_calaire.R
```

Este script carga las funciones de `R/preprocessing/` y ejecuta los pipelines
disponibles segun los archivos encontrados en `data/raw/`.

### 1. Lectura de archivos crudos

Archivo:

```text
R/preprocessing/read_calaire_raw.R
```

La lectura:

- verifica que el archivo exista;
- elimina lineas vacias;
- detecta automaticamente el separador (`;`, `,`, tabulador o espacios);
- detecta si hay fila de unidades;
- conserva los valores inicialmente como texto para limpiarlos despues.

### 2. Limpieza y normalizacion

Archivo:

```text
R/preprocessing/clean_calaire_raw.R
```

La limpieza:

- recorta espacios;
- convierte celdas vacias en `NA`;
- normaliza nombres de columnas;
- convierte coma decimal a punto decimal;
- crea la columna `timestamp`;
- valida orden cronologico;
- detecta timestamps duplicados;
- detecta huecos de mas de un minuto;
- convierte columnas de medicion a numericas.

El resultado interno principal es una tabla limpia con `date`, `time`,
`timestamp` y columnas numericas normalizadas por analito/instrumento.

### 3. Promedios horarios

Archivo:

```text
R/preprocessing/hourly_averages.R
```

El preprocesador calcula promedios horarios para referencia, participantes y
bloques de estabilidad/homogeneidad.

Una hora se considera valida si tiene al menos 45 datos minuto validos. Esto
equivale al 75% de una hora.

Campos importantes de salida:

- `pollutant`
- `level`
- `instrument`
- `mean_value`
- `sd_value`
- `u_value`
- `n`
- `unit`
- `valid_hour`
- `validation_flags`

Para datos de ronda, el nivel se deriva directamente del valor del generador y
la unidad definida en `niveles_calaire.csv`.

### 4. Consolidacion por nivel

La funcion `summarise_reference_levels()` consolida horas validas por analito,
nivel, instrumento y corrida.

Campos importantes:

- `mean_h1`
- `mean_h2`
- `mean_h3`
- `mean_value`
- `sd_value`
- `u_value`
- `n_hours`
- `hour_starts`

Este archivo aun no es la ronda completa; es una salida consolidada de
referencia o de participante.

### 5. Medias moviles para estabilidad/homogeneidad

Archivo:

```text
R/preprocessing/moving_hourly_means.R
```

Para cada bloque del diseno de estabilidad/homogeneidad, calcula medias moviles
de 60 puntos. Cada bloque requiere al menos 119 puntos validos.

Campos importantes:

- `pollutant`
- `instrument`
- `level`
- `replicate`
- `sample_id`
- `window_index`
- `window_start`
- `window_end`
- `value`
- `valid_mm`

### 6. Reporte y validaciones

Archivos:

```text
R/preprocessing/uncertainty_report.R
R/preprocessing/validation.R
```

El preprocesador genera reportes y logs con estados:

- `PASS`: validacion superada.
- `WARN`: advertencia que debe revisarse.
- `FAIL`: error que impide considerar exitoso el pipeline.

## Salidas del preprocesamiento

### Estabilidad/homogeneidad

Cuando existe `datos_estabilidad_homogeneidad.csv`, el pipeline genera:

```text
data/processed/h_estabilidad_homogeneidad.csv
data/processed/mm_estabilidad_homogeneidad.csv
data/processed/incertidumbre.md
data/metadata/preprocesamiento_log.csv
```

### Referencia de ronda

Para `datos_ronda.csv`, el pipeline genera:

```text
data/processed/h_referencia_ronda.csv
data/processed/referencia_ronda.csv
data/metadata/preprocesamiento_log_ronda.csv
```

Para subrondas como `datos_ronda_2a.csv`, genera archivos con sufijo:

```text
data/processed/h_referencia_ronda_2a.csv
data/processed/referencia_ronda_2a.csv
```

### Participantes procesados internamente

Para `datos_ronda_part.csv`, el pipeline genera:

```text
data/processed/h_p1_ronda.csv
data/processed/p1_ronda.csv
```

Estos archivos representan el resultado consolidado del participante interno,
pero todavia no son `ronda_<n>_completa.csv`.

## Ronda completa

El archivo de ronda completa se genera despues del preprocesamiento.

Script:

```text
scripts/aplicativo/consolidar_ronda_pt_app.R
```

Salida:

```text
data/processed/ronda_<n>_completa.csv
```

Ejemplo para ronda 1:

```text
data/processed/ronda_1_completa.csv
```

La ronda completa une:

- datos de participantes;
- datos de referencia;
- columnas normalizadas requeridas por el analisis PT.

## Como generar ronda completa desde la GUI

1. Abrir **Preprocesador de datos**.
2. Ejecutar el preprocesamiento.
3. Ir a **4. Consolidacion final**.
4. Elegir **Origen de participantes**:
   - **Desde calaire-app** si los participantes vienen importados desde
     `data/from_calaire-app/<n>-pt.csv`.
   - **Procesamiento interno** si los participantes fueron procesados por
     `pt_app` desde archivos crudos.
5. Pulsar **Generar ronda completa**.

Si el proceso termina correctamente, se crea:

```text
data/processed/ronda_<n>_completa.csv
```

## Archivos esperados por la consolidacion

Para ronda `n`, el consolidador busca referencia en:

```text
data/processed/ronda_<n>_referencia.csv
data/processed/ronda_<n>_r.csv
data/processed/referencia_ronda.csv
```

Y participantes en:

```text
data/processed/ronda_<n>_participantes_from_calaire.csv
data/processed/ronda_<n>_participantes.csv
data/processed/ronda_<n>_p_ronda.csv
data/processed/p1_ronda.csv
```

Cuando se llama desde la GUI, la seleccion **Origen de participantes** determina
que ruta de participantes se intenta usar primero.

## Flujo recomendado

### Caso A: participante procesado internamente

1. Cargar `datos_ronda.csv`.
2. Cargar `datos_ronda_part.csv`.
3. Cargar `niveles_calaire.csv`.
4. Cargar `diseno_estabilidad_homogeneidad.csv`.
5. Pulsar **Ejecutar preprocesamiento**.
6. En **Consolidacion final**, seleccionar **Procesamiento interno**.
7. Pulsar **Generar ronda completa**.
8. Verificar `data/processed/ronda_<n>_completa.csv`.

### Caso B: participantes importados desde calaire-app

1. Ejecutar o cargar la referencia de ronda.
2. Importar participantes desde calaire-app.
3. En **Consolidacion final**, seleccionar **Desde calaire-app**.
4. Pulsar **Generar ronda completa**.
5. Verificar `data/processed/ronda_<n>_completa.csv`.

## Diferencia entre salidas

| Archivo | Proposito |
|---|---|
| `h_referencia_ronda.csv` | Promedios horarios de referencia. |
| `referencia_ronda.csv` | Referencia consolidada por nivel. |
| `h_p1_ronda.csv` | Promedios horarios del participante interno. |
| `p1_ronda.csv` | Participante interno consolidado por nivel. |
| `ronda_<n>_participantes_from_calaire.csv` | Participantes importados desde calaire-app. |
| `ronda_<n>_completa.csv` | Archivo final unido para analisis PT. |

## Diagnostico rapido

Si no aparece `ronda_<n>_completa.csv`, revisar:

1. Que se haya pulsado **Generar ronda completa**.
2. Que exista una referencia consolidada.
3. Que exista un archivo de participantes compatible con el origen elegido.
4. Que el numero de ronda en la GUI coincida con el nombre esperado de salida.
5. Que el estado del workflow no muestre errores `FAIL`.

El preprocesamiento puede haber sido exitoso aunque todavia no exista
`ronda_<n>_completa.csv`, porque la consolidacion final es un paso separado.
