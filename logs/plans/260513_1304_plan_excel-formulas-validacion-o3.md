# Plan: Excel con formulas validacion O3

**Timestamp:** 260513_1304
**Slug:** excel-formulas-validacion-o3
**Estado:** En progreso

## Objetivo
Crear hojas de calculo Excel para validar, con formulas visibles y auditables, los
resultados O3 de los niveles `0-nmol/mol`, `80-nmol/mol` y `180-nmol/mol`.
Los libros deben reconstruir los calculos desde los datos base usados por
`app.R` y comparar cada resultado contra el snapshot congelado en
`validation_1/validation/excel/validacion_o3/valores_validacion_o3.csv`.

El objetivo no es reemplazar los libros actuales hardcodeados
`validacion_excel_o3_*.xlsx`, sino producir una segunda familia de libros con
formulas, trazabilidad y controles de diferencia.

## Alcance
- Analito: O3.
- Niveles: `0-nmol/mol`, `80-nmol/mol`, `180-nmol/mol`.
- Fuentes app.R:
  - `data/homogeneity - homogeneity.csv`
  - `data/stability - stability.csv`
  - `data/summary_n13.csv`
  - `data/pt_data_n13.csv` para `u_i`, si aplica.
- Scripts actuales:
  - `validation_1/validation/excel/validacion_o3/generar_valores_validacion_o3.R`
  - `validation_1/validation/excel/validacion_o3/script_excel_validacion_o3.R`
- Snapshot esperado:
  - `validation_1/validation/excel/validacion_o3/valores_validacion_o3.csv`
- Salidas propuestas:
  - `validation_1/validation/excel/validacion_o3/formulas/validacion_formula_o3_0.xlsx`
  - `validation_1/validation/excel/validacion_o3/formulas/validacion_formula_o3_80.xlsx`
  - `validation_1/validation/excel/validacion_o3/formulas/validacion_formula_o3_180.xlsx`
  - `validation_1/validation/excel/validacion_o3/script_excel_formulas_validacion_o3.R`
  - `validation_1/validation/excel/validacion_o3/formulas/resumen_validacion_formulas_o3.csv`

## Principios de diseno
- Los calculos numericos del libro deben estar en formulas Excel, no en valores
  calculados por R.
- R solo debe preparar datos crudos, escribir formulas, escribir valores
  esperados del snapshot y aplicar formato.
- Cada resultado calculado debe tener, cuando aplique, columnas:
  `calculado`, `esperado_app`, `delta_abs`, `tolerancia`, `estado`.
- Las formulas deben manejar ceros y dispersion nula sin producir errores Excel.
- Las hojas de resumen visibles deben conservar las etiquetas que ve el usuario
  en `app.R`, especialmente:
  - `Resumen del Estudio (Metodo MADe)`
  - `Resumen del Estudio (Metodo nIQR)`
  - `valor_asignado`
  - `algoritmo_A`
  - `puntajes_EA`
  - `informe_global`
- Los heat maps deben validar la misma matriz numerica que `app.R` muestra en
  `global_heatmap_*`: participantes en filas, niveles en columnas y etiqueta
  numerica redondeada a 2 decimales. El color es opcional y solo se valida si
  se implementa formato condicional.
- La validacion debe terminar con cero errores de formula:
  `#REF!`, `#DIV/0!`, `#VALUE!`, `#N/A`, `#NAME?`.

## Diseno de hojas por libro

### README
| Bloque | Contenido |
|--------|-----------|
| Identificacion | Combo, nivel, analito, fecha de generacion, script generador. |
| Fuentes | CSV de homogeneidad, estabilidad, resumen y snapshot esperado. |
| Convenciones | Azul = dato fuente, negro = formula, verde = link interno, amarillo = control. |
| Criterios | Tolerancia numerica y regla de comparacion. |

### datos_homogeneidad
| Bloque | Formula / Contenido |
|--------|----------------------|
| Datos crudos | `sample_id`, `sample_1`, `sample_2` filtrados por O3/nivel. |
| Promedio por muestra | `=AVERAGE(sample_1:sample_2)` por fila. |
| Rango absoluto | `=ABS(sample_1-sample_2)` por fila. |
| Diferencia contra x_pt | `=ABS(sample_2-x_pt_hom)` por fila. |

### calc_homogeneidad
| Resultado | Formula Excel esperada |
|-----------|-------------------------|
| `g` | `=COUNT(datos_homogeneidad[sample_id])` |
| `m` | constante estructural `2`, documentada como numero de replicas. |
| `general_mean` | `=AVERAGE(sample_1:sample_2)` sobre toda la matriz. |
| `x_pt` | `=MEDIAN(datos_homogeneidad[sample_1])` |
| `s_x_bar_sq` | `=VAR.S(promedios_muestra)` |
| `sw` | `=SQRT(SUMSQ(rangos)/(2*g))` para `m = 2`. |
| `ss_sq` | `=s_x_bar_sq-(sw^2/m)` |
| `ss` | `=IF(ss_sq<0,0,SQRT(ss_sq))` |
| `MADe` | `=1.483*MEDIAN(abs(sample_2-x_pt))` |
| `u_sigma_pt` | `=1.25*MADe/SQRT(g)` |
| `Q1` | `=QUARTILE.INC(sample_1,1)` o formula validada equivalente a R type 7. |
| `Q3` | `=QUARTILE.INC(sample_1,3)` o formula validada equivalente a R type 7. |
| `IQR` | `=Q3-Q1` |
| `nIQR` | `=0.7413*IQR` |
| `u_sigma_pt_niqr` | `=1.25*nIQR/SQRT(g)` |
| Criterio simple | `=0.3*sigma_pt` para MADe y nIQR. |
| Criterio expandido | tabla F1/F2 por `g`, con `g` clamp 7-20, y formula `F1*(0.3*sigma_pt)^2+F2*sw^2`. |
| Resultado | `=IF(ss<=criterio,"Cumple","No cumple")`. |

### resultado_homogeneidad
| Bloque | Contenido |
|--------|-----------|
| Tabla MADe | Links a `calc_homogeneidad`, con las mismas etiquetas visibles en `app.R`. |
| Tabla nIQR | Links a `calc_homogeneidad`, en la misma hoja. |
| Validacion | Comparacion fila a fila contra snapshot `resultado_homogeneidad`. |

### datos_estabilidad
| Bloque | Formula / Contenido |
|--------|----------------------|
| Datos crudos | `sample_id`, `sample_1`, `sample_2` filtrados por O3/nivel. |
| Promedio por muestra | `=AVERAGE(sample_1:sample_2)` por fila. |
| Rango absoluto | `=ABS(sample_1-sample_2)` por fila. |

### calc_estabilidad
| Resultado | Formula Excel esperada |
|-----------|-------------------------|
| `general_mean_stab` | `=AVERAGE(sample_1:sample_2)` sobre estabilidad. |
| `x_pt_stab` | `=MEDIAN(datos_estabilidad[sample_1])`. |
| `sw_stab`, `ss_stab` | Mismo patron ANOVA de homogeneidad. |
| `diff_hom_stab` | `=ABS(general_mean_stab-general_mean_homog)`. |
| `u_hom_mean` | `=STDEV.S(valores_homogeneidad)/SQRT(n_valores_hom)`. |
| `u_stab_mean` | `=STDEV.S(valores_estabilidad)/SQRT(n_valores_stab)`. |
| Criterio simple | `=0.3*MADe` y `=0.3*nIQR`. |
| Criterio expandido | `=criterio_simple+2*SQRT(u_hom_mean^2+u_stab_mean^2)`. |
| Resultado | `=IF(diff_hom_stab<=criterio,"Cumple","No cumple")`. |

### resultado_estabilidad
| Bloque | Contenido |
|--------|-----------|
| Tabla visible app.R | Debe repetir la primera tabla MADe/nIQR derivada de homogeneidad, tal como `app.R` la muestra actualmente. |
| Calculos internos | Pueden quedar referenciados en `calc_estabilidad`, no como tabla principal. |
| Validacion | Comparacion fila a fila contra snapshot `resultado_estabilidad`. |

### datos_participantes
| Bloque | Formula / Contenido |
|--------|----------------------|
| Datos base | Participantes distintos de `ref` desde `summary_n13.csv`. |
| Resultado participante | Promedio por participante/nivel, equivalente a `aggregate(mean_value ~ participant_id, mean)`. |
| `sd_value` | Promedio por participante/nivel, equivalente al script actual. |
| `u_i` | Link desde `pt_data_n13.csv`; si no existe, celda vacia controlada. |
| `u_i_check` | `=sd_value/SQRT(3)`, solo como control. |

### datos_referencia
| Bloque | Formula / Contenido |
|--------|----------------------|
| Datos base | Filas `participant_id == "ref"` desde `summary_n13.csv` o referencia CALAIRE procesada, segun el flujo validado. |
| `x_pt_ref` | `=AVERAGE(ref mean_value)` para el nivel/analito. |
| `u_ref_reportada` | Incertidumbre reportada de la referencia (`sd_value` cuando representa `u(x_pt)` o `u_value` de CALAIRE). |
| `u_ref_check` | `=STDEV.S(ref mean_value)/SQRT(n_ref)`, solo como chequeo trazable. |
| Regla critica | La incertidumbre reportada de referencia no se usa como `sigma_pt`; solo como `u_xpt`. |

### valor_asignado
| Metodo | Formulas |
|--------|----------|
| Referencia (1) | `x_pt = AVERAGE(ref mean_value)`, `u_xpt = u_ref_reportada`, `u_ref_check = STDEV.S(ref mean_value)/SQRT(n_ref)` solo control, `sigma_pt = a*x_pt+b` con coeficientes del metodo de expertos. |
| Consenso MADe (2a) | `x_pt = MEDIAN(resultados_participantes)`, `sigma_pt = 1.483*MEDIAN(ABS(xi-mediana))`. |
| Consenso nIQR (2b) | `x_pt = MEDIAN(resultados_participantes)`, `sigma_pt = 0.7413*(Q3-Q1)`. |
| Algoritmo A (3) | Links a hoja `algoritmo_A_iteraciones`. |
| Expertos (4) | `x_pt = AVERAGE(ref mean_value)`, `u_xpt = u_ref_reportada`, `sigma_pt = a*x_pt+b` con los mismos coeficientes usados para Referencia (1). |
| Incertidumbres | `u_xpt = 1.25*sigma_pt/SQRT(n_participantes)`, `u_hom = ss`, `u_stab = diff_hom_stab/SQRT(3)`, `u_xpt_def = SQRT(u_xpt^2+u_hom^2+u_stab^2)`, `U_xpt = 2*u_xpt_def`. |

### algoritmo_A_iteraciones
| Bloque | Formula / Contenido |
|--------|----------------------|
| Inicializacion | `x*0 = MEDIAN(xi)`, `s*0 = 1.483*MEDIAN(ABS(xi-x*0))`. |
| Iteraciones 1:50 | Filas por iteracion con `delta = 1.5*s*`, limites, valores winzorizados por participante, `x*_new`, `s*_new`, deltas y convergencia. |
| Winsorizacion | `=MIN(MAX(xi,lower),upper)` por participante. |
| Actualizacion | `x*_new = AVERAGE(winzorizados)`, `s*_new = 1.134*STDEV.S(winzorizados)`. |
| Convergencia | Comparacion a 3 cifras significativas. Se debe definir formula Excel equivalente y validarla contra `signif()` de R. |
| Guardia numerica | `ABS(delta_x)<1E-10` y `ABS(delta_s)<1E-10`. |
| Seleccion final | Primer fila convergida; si no converge, ultima iteracion disponible. |
| Nivel cero | Para O3 0, mantener salida en cero para coincidir con la regla congelada del usuario. |

### algoritmo_A
| Bloque | Contenido |
|--------|-----------|
| Resumen visible | `Analito`, `Esquema (n)`, `Nivel`, `n participantes`, `x*0`, `s*0`, `x*`, `s*`, observaciones winzorizadas, observaciones totales, `n_iteraciones`, criterio, guardia numerica, primera iteracion 3ra cifra. |
| Validacion | Comparacion contra snapshot `algoritmo_A`. |

### puntajes_EA
| Score | Formula Excel |
|-------|---------------|
| z | `=(x_i-x_pt)/sigma_pt`, con control para `sigma_pt = 0`. |
| z' | `=(x_i-x_pt)/SQRT(sigma_pt^2+u_xpt_def^2)`, con control de denominador. |
| zeta | `=(x_i-x_pt)/SQRT(u_i^2+u_xpt_def^2)`, con control de denominador. |
| En | `=(x_i-x_pt)/SQRT((2*u_i)^2+(2*u_xpt_def)^2)`, con control de denominador. |
| Evaluacion z/z'/zeta | `N/A` si no finito; `Satisfactorio` si `ABS(score)<=2`; `Cuestionable` si `<3`; `No satisfactorio` si `>=3`. |
| Evaluacion En | `N/A` si no finito; `Satisfactorio` si `ABS(En)<=1`; `No satisfactorio` si `>1`. |
| Validacion | Comparacion por metodo y participante contra snapshot `puntajes_EA`. |

### informe_global
| Bloque | Formula / Contenido |
|--------|----------------------|
| Valor asignado | Links a `valor_asignado`. |
| Tabla resumen global | Conteos por metodo, score y categoria para z, z', zeta y En. Esta es la tabla prioritaria que falta frente al estado actual. |
| Conteos evaluacion | `COUNTIFS` por metodo y categoria para z, z', zeta y En. |
| Validacion | Comparacion contra snapshot `informe_global`. |

### heatmap_datos_globales
| Bloque | Formula / Contenido |
|--------|----------------------|
| Fuente normalizada | Unificar los tres niveles O3 de `puntajes_EA` en una tabla larga por `method`, `score_tipo`, `participant_id`, `level`, `score_value`, `evaluation`. |
| Orden participantes | Mismo orden de `app.R`: `participant_id` ordenado alfabeticamente. |
| Orden niveles | Mismo orden de `app.R`: niveles ordenados por valor numerico extraido de `level`. |
| Metodos | `Referencia (1)`, `Consenso MADe (2a)`, `Consenso nIQR (2b)`, `Algoritmo A (3)`, `Expertos (4)`. |
| Scores | `z`, `z'`, `zeta`, `En`. |
| Etiqueta celda | `=IF(ISNUMBER(score_value),TEXT(score_value,"0.00"),"")`, equivalente a `sprintf("%.2f", score_value)` cuando el valor es finito. |

### heatmap_global_[metodo]
| Bloque | Formula / Contenido |
|--------|----------------------|
| Matrices por score | Cuatro matrices por metodo: z, z', zeta y En. |
| Valor de celda | Formula `INDEX/MATCH` o `XLOOKUP` por participante y nivel desde `heatmap_datos_globales`. |
| Evaluacion de celda | Formula paralela para traer `Satisfactorio`, `Cuestionable`, `No satisfactorio` o `N/A`. |
| Formato condicional opcional | Si se implementa color, usar verde `#00B050`, amarillo `#FFEB3B`, rojo `#D32F2F`, gris `#BDBDBD`, como `score_heatmap_palettes` en `app.R`; para `En`, `Cuestionable` tambien usa rojo `#D32F2F`. |
| Validacion requerida | Verificar que todas las celdas numericas esperadas existan y coincidan con `puntajes_EA` redondeado a 2 decimales. |
| Validacion opcional | Si hay color, verificar que corresponda a la evaluacion textual. |

### heatmap_reporte_revision
| Bloque | Formula / Contenido |
|--------|----------------------|
| Revision app.R | Revisar `report_heatmaps()` para confirmar si aplica al alcance O3 de estos libros. |
| Diferencias conocidas | Documentar que `report_heatmaps()` usa etiquetas `Insatisfactorio`, mientras `global_heatmap_*` usa `No satisfactorio`. |
| Decision | Implementar solo si el flujo de reporte debe quedar cubierto por la validacion Excel; si no, registrar exclusion justificada. |

### validacion_snapshot
| Bloque | Contenido |
|--------|-----------|
| Snapshot filtrado | Copia de `valores_validacion_o3.csv` para el combo del libro. |
| Indices de busqueda | Llaves auxiliares por seccion, tabla, parametro, metodo y participante. |
| Controles | Conteo de filas esperadas vs filas calculadas por seccion. |

### validacion_final
| Bloque | Contenido |
|--------|-----------|
| Resumen por hoja | Total comparaciones, aprobadas, fallidas, max delta. |
| Errores formula | Conteo de errores Excel detectados post-recalculo. |
| Estado global | `OK` solo si todas las comparaciones estan dentro de tolerancia y no hay errores. |

## Fases

### Fase 1: Inventario y mapeo de formulas
| Item | Estado | Notas |
|------|--------|-------|
| Revisar scripts actuales de snapshot | Completado | `generar_valores_validacion_o3.R` calcula valores app.R; `script_excel_validacion_o3.R` solo pega snapshot. |
| Mapear cada seccion del snapshot a hoja formula | Completado | Inventario en `validation_1/validation/excel/validacion_o3/formulas/inventario_fase1_o3.md`; llaves por seccion definidas. |
| Identificar funciones R que deben traducirse a Excel | Completado | Inventario cubre homogeneidad, estabilidad, MADe, nIQR, Algoritmo A, expertos, puntajes y conteos globales. |
| Revisar heat maps en `app.R` | Completado | Alcance obligatorio limitado a `global_heatmap_*`; `report_heatmaps()` queda documentado como flujo distinto por usar `Insatisfactorio`. |
| Definir tolerancias | Completado | `1e-8` internos, `5e-4` visibles a 4 decimales, `5e-3` heat maps a 2 decimales, textos/conteos exactos. |
| Revisar equivalencia de cuantiles | Completado | `QUARTILE.INC` coincide con `stats::quantile(type = 7)` para O3 0/80/180 con max delta 0. |

### Fase 2: Diseno tecnico del generador
| Item | Estado | Notas |
|------|--------|-------|
| Crear `script_excel_formulas_validacion_o3.R` | Completado | Script ejecutable creado; usa `openxlsx`, `writeFormula()` y genera libros de andamiaje en `formulas/`. |
| Crear helpers para rangos nombrados | Completado | `add_named_range()` y `add_table_named_ranges()` crean regiones por tabla y columna con nombres saneados. |
| Crear helpers de comparacion snapshot | Completado | `make_validation_rows()` y `write_validation_block()` generan columnas `calculado`, `esperado_app`, `delta_abs`, `tolerancia`, `estado`. |
| Crear helpers de estilo | Completado | `make_styles()` centraliza azul inputs, negro formulas, verde links internos, amarillo controles, OK y FALLA. |
| Crear carpeta `formulas/` | Completado | Creada al documentar `inventario_fase1_o3.md`; mantener ahi los libros con formulas separados de los hardcodeados. |

### Fase 3: Datos crudos y hojas base
| Item | Estado | Notas |
|------|--------|-------|
| Escribir `datos_homogeneidad` por combo | Completado | Fuente filtrada por O3/nivel con columnas crudas y fórmulas de control `promedio_muestra` y `rango_absoluto`. |
| Escribir `datos_estabilidad` por combo | Completado | Misma estructura que homogeneidad. |
| Escribir `datos_participantes` por combo | Completado | Excluye `participant_id == "ref"` y agrega control `u_i_check`. |
| Escribir `datos_referencia` por combo | Completado | Mantiene `x_pt_ref` y `u_ref_check` como controles trazables. |
| Escribir `validacion_snapshot` por combo | Completado | Copia solo filas del combo desde `valores_validacion_o3.csv`. |
| Agregar rangos nombrados | Completado | Se conservan los rangos de tabla para las hojas base y snapshot. |

### Fase 4: Homogeneidad y estabilidad con formulas
| Item | Estado | Notas |
|------|--------|-------|
| Implementar `calc_homogeneidad` | Completado | Hoja creada con formulas Excel para `g`, `m`, media general, `x_pt`, `sw`, `ss`, MADe, nIQR, incertidumbres y criterios. |
| Implementar `resultado_homogeneidad` | Completado | Tabla visible app.R con comparacion contra snapshot; 14/14 OK por libro tras recalculo LibreOffice. |
| Implementar `calc_estabilidad` | Completado | Hoja creada con formulas Excel para estadisticos internos, `diff_hom_stab`, incertidumbres de medias y criterios. |
| Implementar `resultado_estabilidad` | Completado | Repite la tabla MADe/nIQR de homogeneidad, segun comportamiento app.R confirmado; 14/14 OK por libro. |
| Validar ceros O3 0 | Completado | O3 0 recalculado sin `#DIV/0!`; homogeneidad y estabilidad quedaron 14/14 OK. |

### Fase 5: Valor asignado y Algoritmo A
| Item | Estado | Notas |
|------|--------|-------|
| Implementar `valor_asignado` | Completado | Referencia y Expertos usan `x_pt`/`u_xpt` de referencia y `sigma_pt = 0.02*x_pt+1`; MADe, nIQR y Algoritmo A se recalculan con formulas y validan 5/5 OK por libro. |
| Implementar `algoritmo_A_iteraciones` | Completado | Hoja con inicializacion, 50 iteraciones, winsorizacion, convergencia, guardia numerica y seleccion final. |
| Implementar `algoritmo_A` | Completado | Resumen visible y comparacion contra snapshot; 14/14 OK por libro tras recalculo LibreOffice. |
| Resolver formula de 3 cifras significativas | Completado | Helper `sig3_formula()` usa `ROUND(x, MAX(3-1-INT(LOG10(ABS(x))), 0))` con guardia para cero/no numericos. |
| Regla especial O3 0 | Completado | `algoritmo_A` devuelve ceros para O3 0, preservando el snapshot congelado. |

### Fase 6: Puntajes e informe global
| Item | Estado | Notas |
|------|--------|-------|
| Implementar `puntajes_EA` | Completado | Hoja con formulas para z, z', zeta, En y evaluaciones por metodo/participante; 60/60 OK por libro. |
| Implementar manejo de denominadores cero | Completado | Denominadores no numericos o cero devuelven celda vacia y evaluacion `N/A`, coincidiendo con snapshot; zeta/En usan `u_i` reportado. |
| Implementar tabla resumen de `informe_global` | Completado | Conteos por metodo, score y categoria calculados con `COUNTIFS` desde `puntajes_EA`; 25/25 OK por libro. |
| Implementar bloque de valor asignado en `informe_global` | Completado | Links a `valor_asignado` para `x_pt`, `sigma_pt`, `u_xpt`, `u_hom`, `u_stab`, `u_xpt_def`, `U_xpt` y `n_participants`. |
| Comparar contra snapshot | Completado | Numericos y textos validados contra `validacion_snapshot`; los tres libros recalculados quedaron `Estado global = OK`. |
| Hardcodear resumen global en libros actuales | Completado | Worker `Schrodinger` agrego `Resumen global de evaluaciones` al snapshot hardcodeado y regenero los tres xlsx actuales. |

### Fase 7: Heat maps y validacion visual
| Item | Estado | Notas |
|------|--------|-------|
| Construir `heatmap_datos_globales` | Completado | Hoja larga creada por libro desde `puntajes_EA`: cinco metodos, cuatro scores, participantes alfabeticos y nivel del combo. |
| Implementar matrices `heatmap_global_*` | Completado | Hoja consolidada `heatmap_global` con bloques por metodo/score; cada bloque muestra participante, nivel, etiqueta y evaluacion. |
| Validar datos numericos de heat map | Completado | 240/240 controles OK por libro; etiquetas `TEXT(score,"0.00")` contra `puntajes_EA`. |
| Replicar paletas de `app.R` | Pendiente | Opcional: usar formato condicional con colores de `score_heatmap_palettes`. |
| Validar orden de ejes | Completado | Participantes ordenados alfabeticamente; cada libro representa su nivel O3 y conserva el nivel como columna de matriz. |
| Validar etiquetas numericas | Completado | Valores finitos muestran dos decimales; no numericos quedan en blanco, igual que `render_global_score_heatmap()`. |
| Revisar `report_heatmaps()` | Completado | Decision Fase 1: excluido del alcance obligatorio; documentar como flujo distinto si se implementa reporte Word. |
| Crear controles de colores | Pendiente | Opcional, solo si se implementa formato condicional. |

### Fase 8: Recalculo y verificacion automatica
| Item | Estado | Notas |
|------|--------|-------|
| Ejecutar generador | Completado | `Rscript validation_1/validation/excel/validacion_o3/script_excel_formulas_validacion_o3.R` regenero los tres libros `validacion_formula_o3_*.xlsx`. |
| Recalcular con LibreOffice | Completado | Recalculo headless en `/tmp/pt_o3_formula_recalc_phase8/out`; las copias recalculadas reemplazaron los artefactos finales en `formulas/`. |
| Escanear errores de formula | Completado | Escaneo XML sin literales `#REF!`, `#DIV/0!`, `#VALUE!`, `#N/A`, `#NAME?`; `validacion_final` reporta `Total errores Excel = 0` por libro. |
| Exportar resumen CSV | Completado | `resumen_validacion_formulas_o3.csv` regenerado con 54 filas, estado por libro/hoja, fase `Fase 8` y `total_errores_excel = 0`. |
| Revisar diferencias | Completado | Los tres libros recalculados quedaron con `Estado global = OK`; no hubo diferencias fuera de tolerancia que investigar. |

### Fase 9: Documentacion, revision y persistencia
| Item | Estado | Notas |
|------|--------|-------|
| Documentar uso en README o README de carpeta | Pendiente | Comandos para refrescar snapshot y generar libros con formulas. |
| Ejecutar revisor de fase | Pendiente | Revisor debe buscar inconsistencias, riesgos y formulas fragiles. |
| Actualizar este plan | Pendiente | Registrar hallazgos, decisiones y comandos ejecutados. |
| Usar skill `saver` | Pendiente | Persistir estado de sesion y hallazgos. |
| Commit y push | Pendiente | Requerido por `AGENTS.md` al completar fases. |

## Riesgos y decisiones pendientes
- Excel y R deben coincidir en cuantiles. Si `QUARTILE.INC` no reproduce
  exactamente `stats::quantile(type = 7)` en todos los niveles, crear formula
  explicita de interpolacion type 7.
- Excel no tiene una funcion directa identica a `signif()` de R para 3 cifras
  significativas. Hay que definir y probar una formula auxiliar, especialmente
  para valores cercanos a cero.
- `openxlsx` escribe formulas pero no calcula valores. La verificacion requiere
  recalculo externo con LibreOffice antes de leer resultados.
- Los valores visibles del snapshot estan redondeados a 4 decimales en varias
  secciones. La comparacion debe distinguir campos visibles formateados de
  calculos internos no redondeados.
- Para O3 0, varias dispersiones son cero. Las formulas deben evitar errores y
  devolver los textos `N/A` o ceros que coinciden con `app.R`/snapshot.
- `resultado_estabilidad` debe conservar la regla confirmada: mostrar la misma
  tabla MADe/nIQR de homogeneidad, aunque exista una hoja interna con calculos
  de estabilidad.
- Para `Referencia (1)`, `sigma_pt` debe salir de la ecuacion de expertos
  `a*x_pt+b`. La incertidumbre reportada de referencia alimenta `u_xpt`; la
  desviacion experimental `sd(ref mean_value)/sqrt(n_ref)` es solo chequeo y
  no debe entrar como denominador de `z`.
- Los heat maps deben validarse principalmente como datos numericos y
  ordenamiento. El color es opcional; si se implementa, debe documentarse la
  paleta usada. Un cambio de texto entre `No satisfactorio` e
  `Insatisfactorio` debe tratarse como diferencia de flujo y documentarse.

## Criterios de aceptacion
- Existen tres libros con formulas para O3 0, 80 y 180.
- Cada libro contiene hojas de datos, calculo, resultado visible, snapshot y
  validacion final.
- Todas las formulas recalculan sin errores Excel.
- `validacion_final` queda en `OK` para los tres libros.
- Las hojas visibles comparan contra `valores_validacion_o3.csv` y no tienen
  diferencias fuera de tolerancia.
- La validacion incluye heat maps para O3 con participantes, niveles y valores
  numericos de score. Los colores son opcionales.
- La hoja `informe_global` incluye la tabla resumen global de conteos por
  metodo, score y categoria, no solo la tabla/resumen de puntajes EA.
- El script generador puede ejecutarse desde la raiz del proyecto con:
  `Rscript validation_1/validation/excel/validacion_o3/script_excel_formulas_validacion_o3.R`

## Log de Ejecucion
- [260513 13:04] Creado plan para generar libros Excel con formulas de validacion O3.
- [260513 13:04] Agregado alcance de heat maps: matrices globales por metodo/score, paletas, etiquetas y revision de `report_heatmaps()`.
- [260513 13:04] Ajustado alcance: color de heat maps opcional; datos numericos obligatorios. Priorizada tabla resumen global de `informe_global`.
- [260513 13:04] Asignado worker `Schrodinger` con `gpt-5.5` low para hardcodear tabla resumen global en artefactos actuales.
- [260513 13:04] Worker completo: `informe_global` contiene `Resumen global de evaluaciones` con 16 filas por combo (4 metodos x 4 scores).
- [260513 14:53] Decision metodologica: en `Referencia (1)`, `sigma_pt` viene del metodo de expertos; la incertidumbre reportada de referencia se usa como `u_xpt` y se chequea contra `sd(ref mean_value)/sqrt(n_ref)`.
- [260513 14:59] Inicio y cierre tecnico Fase 1: inventario, mapeo snapshot-hojas, funciones R a formulas Excel, heat maps, tolerancias y cuantiles documentados en `formulas/inventario_fase1_o3.md`.
- [260513 15:00] Revisor de fase encontro divergencias: snapshot usaba `sigma_pt` de homogeneidad para `Referencia (1)` y no incluia `Expertos (4)`.
- [260513 15:00] Corregido `generar_valores_validacion_o3.R`: `Referencia (1)` y `Expertos (4)` usan `sigma_pt = 0.020*x_pt+1.0` y `u_xpt` reportado por referencia; regenerados `valores_validacion_o3.csv` y los tres libros hardcodeados.
- [260513 15:25] Fase 2 implementada: creado `script_excel_formulas_validacion_o3.R` con helpers de fuentes, estilos, rangos nombrados, formulas y bloques de comparacion snapshot.
- [260513 15:25] Ejecutado generador de Fase 2; creados libros de andamiaje `validacion_formula_o3_0.xlsx`, `validacion_formula_o3_80.xlsx`, `validacion_formula_o3_180.xlsx` y `resumen_validacion_formulas_o3.csv`.
- [260513 15:30] Revisor de fase encontro riesgos en Fase 2: `NA` escrito como `#N/A`, referencias incompletas en helper de comparacion, `validacion_final` sin ruta a `OK` y auto-ejecucion al hacer `source()`.
- [260513 15:30] Corregidos hallazgos del revisor: `NA` se escribe como celda vacia, formulas de comparacion usan referencias con fila, `validacion_final` puede devolver `OK`, el script solo auto-ejecuta via `Rscript`, y los libros regenerados no contienen celdas de error Excel en XML.
- [260513 15:58] Fase 3 completada: `script_excel_formulas_validacion_o3.R` ahora escribe `datos_homogeneidad`, `datos_estabilidad`, `datos_participantes`, `datos_referencia`, `validacion_snapshot` y `validacion_final` con formulas de control visibles.
- [260513 15:58] Regenerados `valores_validacion_o3.csv` y los tres libros `validacion_formula_o3_*.xlsx` con la nueva estructura de hojas.
- [260513 17:27] Fase 4 implementada: datos de homogeneidad/estabilidad corregidos a formato ancho `sample_1`/`sample_2`; agregadas hojas `calc_homogeneidad`, `resultado_homogeneidad`, `calc_estabilidad` y `resultado_estabilidad`.
- [260513 17:27] Recalculo LibreOffice completado en `/tmp/pt_o3_formula_recalc`: los tres libros quedaron con 14/14 comparaciones OK en `resultado_homogeneidad` y 14/14 OK en `resultado_estabilidad`; sin errores literales `#REF!`, `#DIV/0!`, `#VALUE!`, `#N/A`, `#NAME?` en XML.
- [260513 17:27] Decision tecnica Fase 4: usar formulas Excel compatibles con LibreOffice `VAR` y `QUARTILE` en lugar de `VAR.S` y `QUARTILE.INC`, porque el recalc externo devolvia celdas vacias para esas funciones.
- [260513 17:35] Revisor de Fase 4 encontro bloqueantes: los xlsx finales bajo `formulas/` no estaban recalculados, `validacion_final` no miraba los estados reales y el conteo de errores Excel era solo texto.
- [260513 18:39] Fase 6 completada: agregadas hojas `puntajes_EA` e `informe_global` con formulas auditables y controles contra snapshot.
- [260513 18:39] Recalculo LibreOffice completado en `/tmp/pt_o3_formula_recalc_phase6_*`; los tres libros quedaron `Estado global = OK`, `puntajes_EA` 60/60 OK, `informe_global` 25/25 OK y cero errores Excel.
- [260513 18:39] Correcciones de revision local Fase 6: usar `method` visible en lugar de `method_key` vacio para `puntajes_EA`, y usar `u_i` reportado desde `pt_data_n13.csv` en lugar de `u_i_check`.
- [260513 17:35] Corregido `validacion_final`: ahora resume `resultado_homogeneidad!G:G` y `resultado_estabilidad!G:G`, calcula estado global real y cuenta errores `#REF!`, `#DIV/0!`, `#VALUE!`, `#N/A`, `#NAME?` en hojas de resultados/calculo.
- [260513 17:35] Regenerados y reemplazados los tres libros finales por copias recalculadas con LibreOffice en `validation_1/validation/excel/validacion_o3/formulas/`; verificacion directa de esos artefactos: `validacion_final = OK`, 14/14 OK en homogeneidad, 14/14 OK en estabilidad y conteos de errores Excel en cero.
- [260513 18:14] Fase 5 implementada: agregadas hojas `valor_asignado`, `algoritmo_A_iteraciones` y `algoritmo_A` al generador de libros con formulas O3.
- [260513 18:14] Decision tecnica Fase 5: usar `STDEV` en lugar de `STDEV.S` para `s_new` del Algoritmo A, por compatibilidad con el recalc de LibreOffice ya observada en Fase 4.
- [260513 18:14] Revision de fase: intento de subagente `revisor-fase` no disponible por limite de uso; revision local encontro un bloqueo en `validacion_final`, donde `Estado global` no dependia de errores Excel. Se corrigio agregando estado de errores en la fila `validacion_final` del resumen.
- [260513 18:14] Verificacion Fase 5: generador ejecutado, tres libros recalculados con LibreOffice en `/tmp/pt_o3_formula_recalc_phase5_*`; artefactos finales quedaron `validacion_final = OK`, `valor_asignado` 5/5 OK, `algoritmo_A` 14/14 OK y cero errores `#REF!`, `#DIV/0!`, `#VALUE!`, `#N/A`, `#NAME?`.
- [260513 19:14] Fase 7 implementada: agregadas hojas `heatmap_datos_globales` y `heatmap_global` como vistas reorganizadas desde `puntajes_EA`, sin recalcular estadistica nueva.
- [260513 19:14] Decision tecnica Fase 7: usar referencias directas por indice a `puntajes_EA` y a `heatmap_datos_globales`, evitando busquedas `MATCH` sobre columnas completas porque el heatmap solo reordena informacion existente.
- [260513 19:14] Verificacion Fase 7: generador ejecutado, tres libros recalculados con LibreOffice en `/tmp/pt_o3_formula_recalc_phase7_*`; `heatmap_datos_globales` 240/240 OK, `heatmap_global` 240/240 OK, `validacion_final = OK` y `Total errores Excel = 0` en los tres libros.
- [260513 19:25] Fase 8 completada: generador ejecutado, tres libros recalculados con LibreOffice en `/tmp/pt_o3_formula_recalc_phase8/out` y artefactos finales reemplazados por las copias recalculadas.
- [260513 19:25] Verificacion Fase 8: `validacion_final` reporta `Estado global = OK` y `Total errores Excel = 0` para O3 0, 80 y 180; escaneo XML sin `#REF!`, `#DIV/0!`, `#VALUE!`, `#N/A` ni `#NAME?`.
- [260513 19:25] Exportado `resumen_validacion_formulas_o3.csv` con 54 filas de estado por libro/hoja, 8 hojas `Implementado`, 10 controles `OK` y cero errores Excel por libro.
