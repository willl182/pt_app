# Plan: Preprocesamiento CALAIRE como módulo interno de pt_app

**Created**: 2026-04-24 16:24 -05
**Updated**: 2026-04-24 16:24 -05
**Status**: draft
**Slug**: preprocesamiento-calaire

## Objetivo

Implementar el preprocesamiento de los datos CALAIRE dentro de `pt_app` como módulo interno específico del proyecto, manteniendo `ptcalc` como núcleo estadístico genérico y dejando `calaire-app` como portal operativo que podrá consumir resultados ya validados.

El pipeline debe convertir archivos minutales crudos en insumos listos para análisis de ronda, homogeneidad, estabilidad e incertidumbre.

## Decisión Arquitectónica

El preprocesamiento se implementará en `pt_app`, no en `ptcalc` ni directamente en `calaire-app`.

Razones:

- `ptcalc` debe permanecer genérico y reusable: ISO 13528, puntajes, homogeneidad, estabilidad y estadística robusta.
- Este preprocesamiento depende de convenciones CALAIRE: nombres de archivos, columnas, niveles nominales, datos generados, reglas de limpieza y diseño experimental.
- `pt_app` ya es la app R/Shiny específica del proyecto y contiene el flujo estadístico y documental más cercano al análisis.
- `calaire-app` es Next.js/Supabase/WorkOS y debe encargarse de gestión operativa: rondas, participantes, autenticación, carga y consumo de resultados.
- No se recomienda `git submodule` por ahora: añade fricción de sincronización y versionado sin aportar valor claro mientras el pipeline pertenece al mismo flujo de negocio de `pt_app`.

## Estructura Propuesta

```text
pt_app/
  R/
    preprocessing/
      read_calaire_raw.R
      clean_calaire_raw.R
      hourly_averages.R
      moving_hourly_means.R
      uncertainty_report.R
      validation.R
      pipeline_calaire.R
  scripts/
    preprocesar_calaire.R
  data/
    raw/
      datos_ronda.csv
      datos_estabilidad_homogeneidad.csv
    processed/
      h_datos_ronda.csv
      h_estabilidad_homogeneidad.csv
      mm_estabilidad_homogeneidad.csv
      incertidumbre.md
    metadata/
      niveles_calaire.csv
      diseno_estabilidad_homogeneidad.csv
      preprocesamiento_log.csv
```

## Contrato De Entradas

### `data/raw/datos_ronda.csv`

Archivo minutal de la ronda.

Características observadas:

- Separador `;`.
- Fila 1: nombres de columnas.
- Fila 2: unidades/metadatos.
- Columnas esperadas: fecha, hora, CO CALAIRE, CO Invitado1, SO2 CALAIRE, SO2 Invitado1, CO generado, SO2 generado.
- Puede contener fila final vacía.

### `data/raw/datos_estabilidad_homogeneidad.csv`

Archivo minutal para estabilidad/homogeneidad.

Características observadas:

- Separador `;`.
- Fila 1: nombres de columnas.
- Fila 2: unidades/metadatos.
- Columnas esperadas: fecha, hora, CO-TAPI, CO generado, SO2, SO2 generado.
- Puede mezclar coma decimal y punto decimal.
- Puede contener blancos en columnas generadas.

### `data/metadata/niveles_calaire.csv`

Tabla explícita de niveles nominales y tolerancias. No se debe agrupar por concentración generada exacta, porque los valores generados pueden fluctuar minutalmente.

Estructura sugerida:

```csv
pollutant,unit,nominal,tolerance,label
co,ppm,0,0.15,0-ppm
co,ppm,1.4,0.25,1.4-ppm
co,ppm,2.8,0.25,2.8-ppm
co,ppm,4.2,0.25,4.2-ppm
co,ppm,6.3,0.25,6.3-ppm
so2,ppb,0,5,0-ppb
so2,ppb,40,10,40-ppb
so2,ppb,80,10,80-ppb
so2,ppb,119,10,119-ppb
so2,ppb,179,10,179-ppb
```

### `data/metadata/diseno_estabilidad_homogeneidad.csv`

Tabla obligatoria para asignar nivel, réplica, muestra y tipo de estudio cuando no sea seguro inferirlo desde la hora.

Estructura sugerida:

```csv
source,pollutant,level,replicate,sample_id,study_type,start_timestamp,end_timestamp,source_column
estabilidad_homogeneidad,co,0-ppm,1,1,homogeneity,2026-04-22 13:30,2026-04-22 15:28,co_tapi_ppm
```

## Subetapa 1: Lectura, Limpieza Y Normalización

Archivo responsable sugerido: `R/preprocessing/read_calaire_raw.R` y `R/preprocessing/clean_calaire_raw.R`.

Reglas:

1. Leer siempre con separador `;`.
2. Separar fila 1 como encabezado y fila 2 como unidades/metadatos.
3. Excluir la fila de unidades de los datos analíticos.
4. Aplicar `trim` a todas las celdas.
5. Convertir cadenas vacías, espacios y campos vacíos a `NA`.
6. Eliminar filas completamente vacías.
7. Convertir coma decimal a punto decimal en columnas numéricas.
8. Rechazar formatos numéricos ambiguos como `1,234.56` o `1.234,56`.
9. Parsear `Date + Time` como `timestamp` local.
10. Validar orden cronológico, duplicados y saltos de un minuto.
11. Mantener valores negativos pequeños cerca de cero, salvo regla metrológica explícita en contra.

Salidas internas recomendadas:

- Dataset limpio de ronda.
- Dataset limpio de estabilidad/homogeneidad.
- Log de filas descartadas, columnas convertidas, valores no parseables y NA por columna.

## Subetapa 2: Promedios Horarios, Desviación Estándar E Incertidumbre

Archivo responsable sugerido: `R/preprocessing/hourly_averages.R`.

Salidas:

- `data/processed/h_datos_ronda.csv`
- `data/processed/h_estabilidad_homogeneidad.csv`
- `data/processed/incertidumbre.md`

Regla principal:

Cada promedio horario válido debe calcularse con exactamente `n = 60` datos minutales válidos.

Para cada combinación de fuente, contaminante, instrumento, nivel nominal y hora:

```text
media_h = sum(x_i) / n
sd_h = sqrt(sum((x_i - media_h)^2) / (n - 1))
u_h = sd_h / sqrt(n)
```

Con `n = 60`:

```text
u_h = sd_h / sqrt(60)
```

Columnas recomendadas para `h_datos_ronda.csv`:

```csv
source,date,hour_start,pollutant,level,generated_nominal,generated_mean,generated_sd,instrument,participant_id,mean_value,sd_value,u_value,n,unit,valid_hour,validation_flags
```

Columnas recomendadas para `h_estabilidad_homogeneidad.csv`:

```csv
source,date,hour_start,pollutant,level,generated_nominal,generated_mean,generated_sd,instrument,mean_value,sd_value,u_value,n,unit,study_type_candidate,sample_id_candidate,replicate_candidate,valid_hour,validation_flags
```

Reglas de inclusión:

- La hora debe tener 60 timestamps minutales únicos.
- Los minutos deben cubrir 00 a 59 cuando se agregue por hora calendario.
- Todas las lecturas requeridas deben ser numéricas finitas.
- La concentración generada debe pertenecer a un único nivel nominal dentro de tolerancia.
- No debe haber mezcla de niveles dentro de una misma hora.
- Horas parciales al inicio o final se excluyen del análisis principal o se reportan como inválidas.

Contenido mínimo de `incertidumbre.md`:

- Alcance: incertidumbre Tipo A de promedio horario.
- Unidad estadística: 60 lecturas minutales por hora/nivel.
- Fórmulas de media, desviación estándar muestral e incertidumbre estándar.
- Criterios de exclusión.
- Advertencia: `u_h` cubre repetibilidad minutal, no incertidumbre metrológica total.
- Componentes no incluidos: patrón, calibración, deriva, resolución, linealidad, blanco y condiciones ambientales.

## Subetapa 3: Medias Móviles Horarias

Archivo responsable sugerido: `R/preprocessing/moving_hourly_means.R`.

Salida:

- `data/processed/mm_estabilidad_homogeneidad.csv`

Regla principal:

Calcular medias móviles simples de ventana 60 datos minutales para cada contaminante, nivel y réplica.

Para producir 60 medias móviles por nivel y réplica se requieren 119 datos minutales por bloque:

```text
mm_1  = mean(x[1:60])
mm_2  = mean(x[2:61])
...
mm_60 = mean(x[60:119])
```

Columnas recomendadas:

```csv
pollutant,run,level,replicate,sample_id,window_start,window_end,n_points,value,unit,validation_flags
```

Validaciones:

- Cada ventana debe contener exactamente 60 datos numéricos.
- Cada bloque debe producir exactamente 60 filas.
- Cada bloque debe estar definido por `diseno_estabilidad_homogeneidad.csv`.
- No inferir definitivamente nivel/réplica/muestra solo por orden temporal si no existe tabla de diseño.
- Si hay datos faltantes dentro de una ventana, la ventana debe fallar o marcarse inválida; no imputar por defecto.

## Validaciones Transversales

Archivo responsable sugerido: `R/preprocessing/validation.R`.

Checks obligatorios:

1. Archivos de entrada existen.
2. Separador correcto.
3. Número de columnas esperado.
4. Fila de unidades excluida.
5. Timestamps parseados sin error en filas válidas.
6. No hay duplicados por timestamp dentro de cada fuente.
7. Saltos temporales reportados.
8. Coma decimal convertida correctamente.
9. Blancos convertidos a `NA`.
10. Valores numéricos no parseables reportados.
11. Horas válidas tienen `n = 60`.
12. Ventanas móviles válidas tienen `n_points = 60`.
13. Niveles nominales asignados por tabla de tolerancias.
14. Salidas usan punto decimal.
15. Conteo de filas esperado reportado por etapa.

Estados recomendados:

- `PASS`: cumple regla crítica.
- `WARN`: condición aceptable pero debe revisarse.
- `FAIL`: no se debe usar la salida para análisis.

## Script Orquestador

Archivo: `scripts/preprocesar_calaire.R`.

Responsabilidades:

1. Cargar funciones desde `R/preprocessing/`.
2. Leer insumos desde `data/raw/`.
3. Leer metadata desde `data/metadata/`.
4. Ejecutar limpieza.
5. Ejecutar promedios horarios.
6. Ejecutar medias móviles.
7. Generar `incertidumbre.md`.
8. Escribir salidas en `data/processed/`.
9. Escribir `data/metadata/preprocesamiento_log.csv`.
10. Terminar con código distinto de cero si existe un `FAIL` crítico.

Comando esperado:

```bash
Rscript scripts/preprocesar_calaire.R
```

## Criterios De Aceptación

- El pipeline corre de inicio a fin con un solo comando.
- Los archivos originales no se modifican.
- Las salidas son reproducibles para los mismos inputs y metadata.
- `h_datos_ronda.csv` existe y contiene solo horas válidas o flags claros.
- `h_estabilidad_homogeneidad.csv` existe y contiene solo horas válidas o flags claros.
- `mm_estabilidad_homogeneidad.csv` existe y contiene 60 medias móviles por bloque definido válido.
- `incertidumbre.md` documenta fórmulas, alcance y limitaciones.
- El log reporta filas leídas, filas descartadas, NA por columna, conversiones decimales, horas inválidas y ventanas inválidas.
- No se asignan niveles/réplicas/muestras sin metadata explícita cuando exista ambigüedad.

## Riesgos Y Decisiones Pendientes

- Confirmar formato real de fecha: los datos observados parecen `m/d/Y`, aunque la fila de unidades diga `ddmmaaaa`.
- Definir tabla real de niveles nominales y tolerancias.
- Definir tabla real de diseño experimental para estabilidad/homogeneidad.
- Confirmar si las columnas generadas con blancos deben quedar como `NA` o si existe regla de relleno por tramos.
- Confirmar si `u = sd / sqrt(60)` es suficiente para el reporte requerido o si se necesita incertidumbre expandida `U = k*u`.
- Confirmar si `mm_estabilidad_homogeneidad.csv` debe incluir solo columnas mínimas o trazabilidad temporal completa.

## Log De Ejecución

- [x] Decidido ubicar el preprocesamiento en `pt_app` como módulo interno.
- [x] Decidido no usar `ptcalc` para lógica específica CALAIRE.
- [x] Decidido no usar `git submodule` por ahora.
- [ ] Crear estructura de carpetas.
- [ ] Mover/copiar archivos crudos a `data/raw/`.
- [ ] Crear metadata de niveles.
- [ ] Crear metadata de diseño experimental.
- [ ] Implementar funciones R.
- [ ] Ejecutar validación con datos reales.
