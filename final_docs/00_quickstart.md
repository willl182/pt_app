# Guía de Inicio Rápido: Aplicación de Ensayos de Aptitud

## Descripción General

Esta aplicación implementa el análisis de ensayos de aptitud (PT) para gases contaminantes criterio siguiendo las normas ISO 17043:2024 e ISO 13528:2022. Desarrollada por el Laboratorio CALAIRE (Universidad Nacional de Colombia) en alianza con el Instituto Nacional de Metrología (INM).

---

## Requisitos del Sistema

| Requisito | Versión Mínima | Recomendado |
|-----------|----------------|-------------|
| R | 4.1.0 | 4.3.0 o superior |
| RStudio | 2023.06 | 2024.04 o superior |
| Sistema Operativo | Windows 10+, macOS 11+, Linux | Cualquier SO moderno |
| RAM | 4 GB | 8 GB+ |

### Instalación

#### 1. Instalar Paquetes de R

Abra R o RStudio y ejecute:

```r
install.packages(c(
  "shiny", "bslib", "tidyverse", "vroom", "DT", "rhandsontable",
  "shinythemes", "outliers", "patchwork", "bsplus", "plotly", "rmarkdown", "devtools"
))
```

#### 2. Instalar el Paquete ptcalc

La aplicación requiere el paquete `ptcalc` para los cálculos ISO 13528/17043.

```r
# Desde el directorio de la aplicación:
devtools::load_all("ptcalc")
```

Para despliegue en producción:

```r
devtools::install("ptcalc")
```

---

## Lanzamiento de la Aplicación

### Método 1: Desde R/RStudio (Recomendado)

```r
setwd("/ruta/a/pt_app")
shiny::runApp("cloned_app.R")
```

La aplicación se abrirá en su navegador web predeterminado en `http://127.0.0.1:XXXX`.

### Método 2: Línea de Comandos

```bash
Rscript cloned_app.R
```

---

## Su Primer Análisis en 5 Minutos

### Paso 1: Preparar sus Archivos de Datos

La aplicación requiere tres tipos de archivos CSV. Ejemplos disponibles en la carpeta `data/`.

#### 1. Datos de Homogeneidad (`homogeneity.csv`)
Contiene mediciones replicadas de las pruebas de homogeneidad.

```csv
"pollutant","level","replicate","sample_id","value"
"co","0-umol/mol",1,1,0.00670
"co","0-umol/mol",1,2,0.00479
"co","0-umol/mol",2,1,-0.0480
```

| Columna | Tipo | Descripción |
|---------|------|-------------|
| pollutant | texto | Identificador del gas (ej: "co", "so2", "no") |
| level | texto | Nivel de concentración (ej: "0-umol/mol") |
| replicate | entero | Número de réplica (1, 2, ...) |
| sample_id | entero | Identificador de la muestra/ítem |
| value | numérico | Concentración medida |

#### 2. Datos de Estabilidad (`stability.csv`)
Mismo formato que los datos de homogeneidad, medidos en un punto de tiempo posterior.

#### 3. Archivos Resumen de Participantes (`summary_n*.csv`)
Un archivo por escenario de cantidad de participantes, nombrado con el patrón `summary_n{N}.csv`.

```csv
"pollutant","level","participant_id","replicate","sample_group","mean_value","sd_value"
"co","0-umol/mol","part_1",2,"1-10",-0.0271,0.0278
"co","0-umol/mol","part_2",3,"1-10",-0.0059,0.0217
"co","0-umol/mol","ref",1,"1-10",-0.0335,0.0261
```

| Columna | Tipo | Descripción |
|---------|------|-------------|
| pollutant | texto | Identificador del gas |
| level | texto | Nivel de concentración |
| participant_id | texto | ID del Laboratorio ("part_1", "part_2", ...) o "ref" |
| mean_value | numérico | Resultado medio del participante |
| sd_value | numérico | Desviación estándar del participante |

### Paso 2: Cargar Archivos de Datos

1. Navegue a la pestaña **"Carga de datos"**.
2. Suba sus archivos:
   - Haga clic en "Archivo de homogeneidad" y seleccione `homogeneity.csv`.
   - Haga clic en "Archivo de estabilidad" y seleccione `stability.csv`.
   - Haga clic en "Archivos resumen" y seleccione todos los archivos `summary_n*.csv`.

### Paso 3: Ejecutar Análisis de Homogeneidad

1. Vaya a la pestaña **"Homogeneidad"**.
2. Seleccione un analito (ej: `so2`) y un nivel (ej: `20-nmol/mol`).
3. Haga clic en **"Ejecutar análisis"**.
4. Revise los resultados:
   - Tabla de varianza ($s_s$, $s_w$).
   - Evaluación del criterio de homogeneidad ("PASA" o "FALLA").
   - Gráficos visuales.

### Paso 4: Calcular Valor Asignado

1. Navegue a la pestaña **"Valor Asignado"**.
2. Elija un método:
   - **Algoritmo A**: Valor de consenso robusto (recomendado).
   - **Referencia**: Usa el participante "ref".
3. Haga clic en el botón de cálculo correspondiente.

### Paso 5: Calcular Puntajes PT

1. Vaya a la pestaña **"Puntajes PT"**.
2. Seleccione el tipo(s) de puntaje:
   - **z**: Puntaje estándar.
   - **z'**: Incluye incertidumbre del valor asignado.
   - **ζ (zeta)**: Incluye incertidumbre del participante.
   - **En**: Error normalizado.
3. Haga clic en **"Calcular puntajes"**.

### Paso 6: Generar Informes

1. Navegue a la pestaña **"Generación de Informes"**.
2. Complete los metadatos del informe (ID del PT, fecha, coordinador).
3. Seleccione el formato de salida (Word o HTML).
4. Haga clic en **"Generar Informe"**.

---

## Solución de Problemas Comunes

### Error: "Column not found"

Asegúrese de que sus archivos CSV contengan todas las columnas requeridas con los nombres exactos (distingue mayúsculas y minúsculas).

### Error: "Insufficient data"

- Homogeneidad/estabilidad requieren al menos 2 ítems y 2 réplicas.
- El Algoritmo A requiere al menos 3 participantes.

### La aplicación no inicia

Verifique que el paquete `ptcalc` se cargue correctamente:

```r
devtools::load_all("ptcalc")
```

---

## Próximos Pasos

- [Glosario de Términos](00_glossary.md) - Terminología Español/Inglés
- [Referencia de Formatos de Datos](01a_data_formats.md) - Especificaciones completas de CSV
- [API del Paquete](02_ptcalc_package.md) - Funciones matemáticas
