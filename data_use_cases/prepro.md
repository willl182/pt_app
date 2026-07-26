# Preprocesamiento de datos de rondas

## Regla horaria

El preprocesador toma datos por minuto y los agrupa por bloques horarios. Una hora es válida con al menos 45 registros por minuto válidos (`n_valid >= 45`). Para cada hora válida calcula:

- `mean_value`: promedio horario.
- `sd_value`: desviación estándar.
- `u_value`: incertidumbre estándar (`sd / sqrt(n)`).

El código responsable está en `R/preprocessing/hourly_averages.R`, principalmente en `compute_hourly_averages()` y `compute_hourly_averages_ronda()`.

## Archivos de entrada generales

- `datos_ronda.csv` o `datos_ronda_<sufijo>.csv`: datos crudos de estación o referencia.
- `datos_ronda_part.csv` o `datos_ronda_<sufijo>_part.csv`: datos crudos de participante, opcionales.
- `datos_estabilidad_homogeneidad.csv`: datos crudos del diseño de estabilidad.
- `niveles_calaire.csv`: medias del generador.
- `diseno_estabilidad_homogeneidad.csv`: metadatos de bloques de tiempo.

Variables esperadas incluyen fecha, hora, gases de referencia CalAire, valores nominales del generador y mediciones de participantes. La limpieza normaliza fechas, horas, separadores decimales y valores vacíos antes de calcular resultados horarios.

## Cadena R3

Entradas crudas:

- `data_use_cases/data/raw/R3_NO.csv`
- `data_use_cases/data/raw/R3_NO2.csv`
- `data_use_cases/data/raw/R3_O3.csv`

Ejecutar Fase 1:

```bash
Rscript data_use_cases/scripts/preprocess_r3.R
```

Genera:

- `r3_capacidad_horaria.csv`: diagnóstico de minutos, horas computables y cumplimiento mínimo.
- `r3_promedios_horarios.csv`: resultados por hora e instrumento.
- `r3_resumen_niveles.csv`: resumen por contaminante, corrida, nivel e instrumento.

`r3_promedios_horarios.csv` se conserva para trazabilidad; no se carga directamente en pt_app.

### Preparación para pt_app

Ejecutar builder:

```bash
Rscript data_use_cases/scripts/build_r3_pt_app.R
```

Builder cruza `r3_resumen_niveles.csv` con `r3_capacidad_horaria.csv` por `pollutant` y `run`. Reemplaza nivel ordinal por nivel nominal `<gen_nominal>-<unit>`. Ejemplos: `0-nmol/mol`, `180-nmol/mol`, `144-nmol/mol`.

Roles se asignan por serial:

- Prefijo `4U`, sin distinguir mayúsculas: referencia CalAire.
- Cualquier otro prefijo: participante.
- `participant_id` conserva serial original del participante.

Genera:

- `ronda_3_p_ronda.csv`: participantes.
- `ronda_3_r.csv`: referencia, con `instrument = calaire_ref` y serial original en `serial`.

Builder exige exactamente un serial de referencia y aborta si existe corrida sin nivel nominal.

### Consolidación cargable

```bash
Rscript scripts/aplicativo/consolidar_ronda_pt_app.R \
  3 \
  data_use_cases/data/processed/ronda_3_p_ronda.csv \
  data_use_cases/data/processed/ronda_3_r.csv \
  data_use_cases/data/processed/ronda_3_completa.csv
```

Salida `ronda_3_completa.csv` contiene participantes y referencia con esquema pt_app. Para datos R3 actuales contiene 30 filas: 15 participante y 15 referencia, cinco niveles por cada uno de tres contaminantes, con `n_lab = 1`.

Cargar `data_use_cases/data/processed/ronda_3_completa.csv` en sección **3. Datos Consolidados de participantes** de pt_app.
