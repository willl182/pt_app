# Archivos que se cargan desde la GUI

El aplicativo no debe depender de archivos precargados en `data/`. La carpeta
`data/` queda como espacio de trabajo temporal: la GUI guarda allí archivos
subidos y salidas generadas durante la ejecución.

## 1. Datos crudos CALAIRE

Se cargan en el preprocesador de datos.

Estos CSV son los archivos minuto a minuto de la ronda. Deben conservar las
columnas de tiempo, analizadores y generadores que produce CALAIRE. El
preprocesador los normaliza, calcula promedios horarios y genera los archivos
consolidados para el análisis.

Nombres recomendados:

- `datos_ronda.csv`: referencia principal de la ronda.
- `datos_ronda_part.csv`: participante procesado internamente, si aplica.
- `datos_ronda_2a.csv`, `datos_ronda_2b.csv`, etc.: referencias por ronda o
  subronda.
- `datos_ronda_2a_part.csv`, `datos_ronda_2b_part.csv`, etc.: participantes
  asociados a esas subrondas.
- `datos_estabilidad_homogeneidad.csv`: mediciones para homogeneidad y
  estabilidad.

Cómo generarlos:

1. Exportar desde CALAIRE el archivo minuto a minuto de la ronda.
2. Mantener columnas de fecha/hora, concentración y generador.
3. Usar nombres de columnas consistentes con la tabla de niveles y el diseño de
   estabilidad/homogeneidad.
4. Cargar los CSV en la ventana `Preprocesador de datos`.

## 2. Tabla de niveles/generadores

Archivo que se carga en `Cargar tabla de niveles/generadores`.

Define, para cada analito, cuál columna del CSV crudo contiene el valor del
generador y en qué unidad se expresa el nivel.

Columnas requeridas:

- `pollutant`: analito en minúsculas, por ejemplo `co`, `so2`, `no`, `no2`,
  `o3`.
- `unit`: unidad que se anexará al nivel, por ejemplo `umol/mol`, `nmol/mol`,
  `ppm` o `ppb`.
- `generator_col`: nombre exacto de la columna del archivo crudo que contiene
  el generador para ese analito.

Ejemplo:

```csv
pollutant,unit,generator_col
co,umol/mol,co_gen_ppm
so2,nmol/mol,so2_gen_ppb
o3,nmol/mol,o3_gen_ppb
```

Cómo generarlo:

1. Revisar los encabezados del CSV crudo.
2. Identificar la columna de generador para cada analito.
3. Crear un CSV con una fila por analito.
4. Cargarlo en la GUI cada vez que cambien niveles, unidades o nombres de
   columnas.

## 3. Diseño de estabilidad/homogeneidad

Archivo que se carga en `Cargar diseño de estabilidad/homogeneidad`.

Este archivo describe los bloques de tiempo que pertenecen a cada muestra o
réplica de estabilidad/homogeneidad. No contiene mediciones; contiene el mapa
para extraerlas desde `datos_estabilidad_homogeneidad.csv`.

Columnas requeridas:

- `source`: origen del bloque, por ejemplo `estabilidad_homogeneidad`.
- `pollutant`: analito.
- `instrument`: instrumento o columna lógica evaluada.
- `level`: nivel nominal con unidad.
- `replicate`: número de réplica.
- `sample_id`: identificador de muestra.
- `study_type`: tipo de estudio, por ejemplo `stability_homogeneity`.
- `start_timestamp`: inicio del bloque, formato `YYYY-MM-DD HH:MM`.
- `end_timestamp`: fin del bloque, formato `YYYY-MM-DD HH:MM`.
- `source_column`: nombre exacto de la columna de medición en el CSV crudo.
- `unit`: unidad de la medición.
- `notes`: texto libre opcional.

Ejemplo:

```csv
source,pollutant,instrument,level,replicate,sample_id,study_type,start_timestamp,end_timestamp,source_column,unit,notes
estabilidad_homogeneidad,co,co_tapi,0-ppm,1,1,stability_homogeneity,2026-04-22 13:30,2026-04-22 16:28,co_tapi_ppm,ppm,nivel_cero_co_rep1
```

Cómo generarlo:

1. Definir, desde el diseño experimental, los intervalos de tiempo de cada
   muestra y réplica.
2. Revisar el CSV crudo para identificar la columna de medición que corresponde
   a cada analito/instrumento.
3. Crear una fila por bloque de tiempo.
4. Cargarlo en la GUI junto con `datos_estabilidad_homogeneidad.csv`.

## 4. Tabla de instrumentación de participantes

Se carga en el módulo de informe, no desde `data/`.

Columnas esperadas para instrumentación completa:

- `Codigo_Lab`
- `Analizador_SO2`
- `Analizador_CO`
- `Analizador_O3`
- `Analizador_NO_NO2`

Si no se carga, el informe puede derivar una tabla mínima desde los
participantes presentes en los datos consolidados, pero no debe buscar archivos
de respaldo en `data/processed`.
