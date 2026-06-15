# Workflow definitivo de preprocesamiento

## Objetivo

Definir el flujo operativo entre datos crudos, `pt_app` y `calaire-app` hasta obtener el consolidado final usado para el análisis de aptitud:

```text
data/processed/ronda_<n>_completa.csv
```

## Vista general

```text
1. Datos crudos Calaire
   crudos -> pt_app

2. Intercambio pt_app <-> calaire-app
   pt_app -> calaire-app: archivo de referencia para configurar/cargar ronda
   calaire-app -> pt_app: archivos de participantes recibidos por aplicativo

3. Consolidación final
   referencia + participantes -> ronda_<n>_completa.csv
```

## 1. Preprocesamiento de datos crudos: crudos -> pt_app

### Propósito

Convertir datos crudos de Calaire al formato interno que entiende `pt_app`.

Este preprocesamiento se usa principalmente para datos de referencia. También puede usarse con datos de participantes cuando Calaire quiera verificar o reproducir técnicamente sus resultados desde datos crudos.

### Entradas típicas

```text
data/raw/datos_ronda.csv
data/raw/datos_ronda_part.csv
data/raw/datos_ronda_<sufijo>.csv
data/raw/datos_ronda_<sufijo>_part.csv
```

### Scripts principales

```bash
Rscript scripts/aplicativo/preprocesar_calaire.R
```

o, para procesamiento por lotes:

```bash
Rscript scripts/adicionales/run_preprocessor_calaire.R
```

### Salidas esperadas

Para referencia:

```text
data/processed/ronda_<n>_referencia.csv
```

Para participantes verificados desde crudos:

```text
data/processed/ronda_<n>_participantes.csv
```

### Contrato interno esperado por `pt_app`

Columnas principales:

```text
pollutant
level
source
run
unit
instrument
mean_h1
mean_h2
mean_h3
mean_value
sd_value
u_value
u_exp
k_factor
n_hours
hour_starts
participant_id
tipo
n_lab
```

Notas:

- `u_value` corresponde a incertidumbre estándar `u_xi`.
- `u_exp` corresponde a incertidumbre expandida `U_xi`.
- `k_factor` corresponde al factor de cobertura `k`.
- `tipo` debe ser `referencia` o `participante`.

## 2. Exportación pt_app -> calaire-app

### Propósito

Generar desde `pt_app` el archivo en formato compatible con `calaire-app` para cargar la referencia de la ronda.

Nombre sugerido del archivo:

```text
data/to_calaire-app/<ronda>-ref.csv
```

Ejemplo:

```text
data/to_calaire-app/1-ref.csv
```

### Script

```bash
Rscript scripts/aplicativo/convert_pt_app_to_calaire_app.R \
  data/processed/ronda_1_referencia.csv \
  data/to_calaire-app/1-ref.csv \
  reference
```

Si se desea exportar desde el consolidado completo, filtrando solo referencia:

```bash
Rscript scripts/aplicativo/convert_pt_app_to_calaire_app.R \
  data/processed/ronda_1_completa.csv \
  data/to_calaire-app/1-ref.csv \
  reference
```

### Contrato de salida para `calaire-app`

```text
pollutant
run
level
participant_id
replicate
sample_group
d1
d2
d3
mean_value
sd_value
ux
k
ux_exp
```

Mapeo desde `pt_app`:

| `pt_app` | `calaire-app` |
|---|---|
| `mean_h1` | `d1` |
| `mean_h2` | `d2` |
| `mean_h3` | `d3` |
| `u_value` | `ux` |
| `k_factor` | `k` |
| `u_exp` | `ux_exp` |

Si no existe `u_exp`, se calcula como:

```text
ux_exp = ux * k
```

## 3. Importación calaire-app -> pt_app

### Propósito

Recibir los archivos generados por `calaire-app` con los datos reportados por participantes y convertirlos al formato interno de `pt_app`.

Entrada típica:

```text
data/from_calaire-app/1-pt.csv
```

Salida sugerida:

```text
data/processed/ronda_1_participantes_from_calaire.csv
```

### Script

```bash
Rscript scripts/aplicativo/convert_from_calaire_app_to_pt_app.R \
  data/from_calaire-app/1-pt.csv \
  data/processed/ronda_1_participantes_from_calaire.csv
```

### Mapeo hacia `pt_app`

| `calaire-app` | `pt_app` |
|---|---|
| `d1` | `mean_h1` |
| `d2` | `mean_h2` |
| `d3` | `mean_h3` |
| `ux` | `u_value` |
| `k` | `k_factor` |
| `ux_exp` | `u_exp` |

El script agrega columnas internas necesarias como `source`, `unit`, `instrument`, `tipo`, `n_hours`, `hour_starts` y `n_lab`.

## 4. Consolidación final en pt_app

### Propósito

Unir referencia y participantes para generar el archivo final usado por la aplicación Shiny y los cálculos de aptitud.

Salida final:

```text
data/processed/ronda_1_completa.csv
```

### Flujo recomendado para ronda 1

1. Preprocesar referencia desde crudos:

```bash
Rscript scripts/aplicativo/preprocesar_calaire.R
```

2. Exportar referencia hacia `calaire-app`:

```bash
Rscript scripts/aplicativo/convert_pt_app_to_calaire_app.R \
  data/processed/ronda_1_referencia.csv \
  data/to_calaire-app/1-ref.csv \
  reference
```

3. Recibir participantes desde `calaire-app` y convertirlos:

```bash
Rscript scripts/aplicativo/convert_from_calaire_app_to_pt_app.R \
  data/from_calaire-app/1-pt.csv \
  data/processed/ronda_1_participantes_from_calaire.csv
```

4. Consolidar referencia y participantes.

El consolidador definitivo acepta participantes procesados internamente o importados desde `calaire-app`:

```bash
Rscript scripts/aplicativo/consolidar_ronda_pt_app.R 1
```

También se pueden indicar rutas explícitas:

```bash
Rscript scripts/aplicativo/consolidar_ronda_pt_app.R 1 \
  data/processed/ronda_1_participantes_from_calaire.csv \
  data/processed/ronda_1_referencia.csv \
  data/processed/ronda_1_completa.csv
```

Para usar participantes procesados internamente:

```bash
Rscript scripts/aplicativo/consolidar_ronda_pt_app.R 1 \
  data/processed/ronda_1_participantes.csv \
  data/processed/ronda_1_referencia.csv \
  data/processed/ronda_1_completa.csv
```

`scripts/adicionales/unir_rondas.R` queda como script histórico/compatible con convenciones previas, pero el flujo recomendado es `scripts/aplicativo/consolidar_ronda_pt_app.R`.

## 5. Nombres recomendados

### Directorios

```text
data/raw/                 # Datos crudos Calaire
data/processed/           # Datos normalizados para pt_app
data/to_calaire-app/      # Archivos que salen hacia calaire-app
data/from_calaire-app/    # Archivos que llegan desde calaire-app
```

### Archivos

| Etapa | Archivo recomendado |
|---|---|
| Referencia procesada para `pt_app` | `data/processed/ronda_<n>_referencia.csv` |
| Participantes procesados/verificados para `pt_app` | `data/processed/ronda_<n>_participantes.csv` |
| Referencia para cargar en `calaire-app` | `data/to_calaire-app/<n>-ref.csv` |
| Participantes recibidos de `calaire-app` | `data/from_calaire-app/<n>-pt.csv` |
| Participantes convertidos para `pt_app` | `data/processed/ronda_<n>_participantes_from_calaire.csv` |
| Consolidado final | `data/processed/ronda_<n>_completa.csv` |

## 6. Regla de oro

`calaire-app` intercambia archivos en formato operativo:

```text
d1, d2, d3, ux, k, ux_exp
```

`pt_app` trabaja internamente en formato analítico:

```text
mean_h1, mean_h2, mean_h3, u_value, k_factor, u_exp
```

La frontera entre ambos sistemas son los scripts:

```text
scripts/aplicativo/convert_pt_app_to_calaire_app.R
scripts/aplicativo/convert_from_calaire_app_to_pt_app.R
```
