# Mapa funcional del aplicativo vigente

**Fuente principal:** `app.R` del commit base.

**Alcance:** funciones visibles y dependencias directas; no constituye todavía
una validación funcional extremo a extremo.

## Flujo de usuario

1. Cargar CSV de homogeneidad, estabilidad y participantes; opcionalmente
   cargar una referencia CALAIRE separada.
2. Ejecutar homogeneidad y estabilidad, revisar datos, conclusiones MADe/nIQR
   y contribuciones de incertidumbre.
3. Revisar valores atípicos de participantes mediante la prueba de Grubbs.
4. Calcular valores asignados por referencia, consenso, Algoritmo A o expertos,
   y evaluar compatibilidad metrológica.
5. Calcular puntajes z, z', zeta y En por analito, esquema y nivel.
6. Consultar el informe global y el detalle por participante.
7. Configurar, previsualizar y descargar el informe individual en DOCX.

## Módulos visibles

| Módulo | Entradas/acciones | Salidas principales | Dependencias o estado previo |
|---|---|---|---|
| Carga de datos | Tres CSV obligatorios; referencia separada opcional; apertura del preprocesador | Estado de carga y datos reactivos normalizados | Esquema de columnas validado por `app.R` |
| Preprocesador | Archivos CALAIRE, ronda, exportación/importación y consolidación | CSV de referencia, participantes y ronda completa | Funciones de `R/preprocessing/` y `scripts/aplicativo/` |
| Homogeneidad y estabilidad | Ejecutar, escoger analito y nivel | Vista previa, histogramas, tablas ANOVA, conclusiones MADe/nIQR, `u_hom`, `u_stab` y CSV exportables | Datos de homogeneidad y estabilidad cargados |
| Valores atípicos | Escoger analito y nivel | Resumen Grubbs, histograma y caja | Datos consolidados de participantes |
| Valor asignado | Algoritmo A, consenso, compatibilidad; selección y máximo de iteraciones | Iteraciones, valores winsorizados, consenso MADe/nIQR, referencia, expertos y compatibilidad | Participantes y referencia disponibles |
| Puntajes EA | Calcular; escoger analito, esquema y nivel | Parámetros, resumen por participante, evaluación y paneles z, z', zeta, En; CSV | Valores asignados y contribuciones de incertidumbre |
| Informe global | Escoger combinación | Resumen x_pt, evaluaciones, resultados y mapas de calor por cinco métodos; CSV final | Puntajes calculados |
| Participantes | Escoger analito y nivel | Pestañas dinámicas con detalle individual | Puntajes calculados |
| Generación de informes | Identificación, participante, métrica, método, k, instrumentación opcional y formato | Estado, vista previa y descarga DOCX | Ronda y resultados disponibles; plantilla en `reports/` |

## Pestañas y subpestañas identificadas

| Pestaña principal (`value`) | Subpestañas visibles |
|---|---|
| Carga de datos (`carga_datos`) | No aplica; incluye modal **Preprocesador de datos** con cuatro etapas |
| Análisis de homogeneidad y estabilidad (`analisis_hom_estab`) | Vista previa de datos; Evaluación de homogeneidad; Evaluación de estabilidad; Contribuciones a la incertidumbre |
| Valores Atípicos (`valores_atipicos`) | No aplica |
| Valor asignado (`valor_asignado`) | Algoritmo A; Valor consenso; Valor de referencia; Método de expertos; Compatibilidad Metrológica |
| Puntajes EA (`puntajes_pt`) | Resultados de puntajes; Puntajes Z; Puntajes Z'; Puntajes Zeta; Puntajes En |
| Informe global (`informe_global`) | Resumen global; Referencia (1); Consenso MADe (2a); Consenso nIQR (2b); Algoritmo A (3); Expertos (4) |
| Participantes (`participantes`) | Pestañas dinámicas, una por participante disponible |
| Generación de informes (`generacion_informes`) | 1. Identificación; 2. Vista Previa |

## Cálculos y criterios expuestos

| Área | Cálculos/criterios identificados en código |
|---|---|
| Homogeneidad | ANOVA, varianza entre/dentro de muestras, MADe, nIQR, criterio de homogeneidad y `u_hom` |
| Estabilidad | Diferencia entre medias, criterios MADe/nIQR, `Dmax` y `u_stab` |
| Valores atípicos | Prueba de Grubbs y resumen por combinación |
| Valor asignado | Referencia, mediana/consenso, MADe, nIQR, Algoritmo A con winsorización, expertos y compatibilidad |
| Puntajes | z, z', zeta, En; incertidumbre base/definitiva y clasificación cualitativa |
| Informes | Selección de métrica/método, factor `k`, compatibilidad y resultados por participante |

## Validaciones y mensajes identificados

| Momento | Validación o mensaje visible/operativo |
|---|---|
| Preprocesador | Exige al menos un CSV crudo para guardar; exige tabla de niveles y diseño para procesar; informa éxito o error de cada conversión/consolidación |
| Carga | Informa estado de archivos; valida columnas y disponibilidad antes de habilitar cálculos |
| Análisis | Muestra validación de datos de entrada y avisa si falta la columna `level` |
| Algoritmo A | Solicita ejecutar el cálculo; informa ausencia de participantes, no convergencia o falta de iteraciones |
| Consenso/referencia | Informa si no se generaron resultados o no existe referencia para la selección |
| Compatibilidad | Exige referencia y al menos un método de consenso |
| Informe global | Indica que primero deben calcularse los puntajes |
| Informe individual | Presenta estado/vista previa; la instrumentación es opcional y, si falta, usa participantes de la ronda |

Los textos exactos y el comportamiento de recuperación deberán confirmarse en
la ejecución Playwright; esta tabla registra la presencia estática en código.

## Entradas y salidas de archivo

| Dirección | Formato | Uso |
|---|---|---|
| Entrada | CSV | Homogeneidad, estabilidad, consolidado de participantes y referencia opcional |
| Entrada | CSV | Instrumentación opcional para el informe individual |
| Salida | CSV | Homogeneidad, estabilidad, intermedios de Algoritmo A, puntajes y puntajes finales |
| Salida | DOCX | Informe individual generado desde plantilla R Markdown |

## Rutas concretas y dependencias

| Ruta | Responsabilidad |
|---|---|
| `app.R` | UI, reactivos, validaciones, tablas, gráficos y descargas |
| `ptcalc/R/pt_robust_stats.R` | Estadística robusta y Algoritmo A |
| `ptcalc/R/pt_scores.R` | Puntajes y evaluaciones |
| `ptcalc/R/pt_homogeneity.R` | Homogeneidad/estabilidad |
| `R/export_final_scores.R` | Exportación consolidada de puntajes finales |
| `R/preprocessing/*.R` | Lectura, limpieza, promedios, incertidumbre, validación y pipeline CALAIRE |
| `scripts/aplicativo/preprocesar_calaire.R` | Orquesta preprocesamiento desde `data/raw/` hacia `data/processed/` |
| `scripts/aplicativo/convert_pt_app_to_calaire_app.R` | Exporta referencia o participantes a `data/to_calaire-app/` |
| `scripts/aplicativo/convert_from_calaire_app_to_pt_app.R` | Importa participantes desde `data/from_calaire-app/` |
| `scripts/aplicativo/consolidar_ronda_pt_app.R` | Genera `ronda_*_completa.csv` en `data/processed/` |
| `reports/report_template.Rmd` | Fuente de informes individuales DOCX |

## Dependencias técnicas vigentes

- Shiny organiza la navegación y los estados reactivos.
- `ptcalc` contiene los cálculos puros de estadística robusta, puntajes,
  homogeneidad y estabilidad.
- Plotly y DT presentan gráficos y tablas interactivas.
- R Markdown genera informes; `reports/report_template.Rmd` es la plantilla
  activa identificada.
- Los datos de demostración existentes en `data/` y `data_use_cases/` son
  candidatos para pruebas, pero deberán verificarse y anonimizarse en la fase
  de capturas.

## Riesgos observados para fases posteriores

- La descripción del paquete declara ISO 17043:2024, mientras el plan y el
  proyecto citan ISO 17043:2023; la edición debe verificarse antes de publicar.
- `app.R` contiene texto visible con erratas (`evalua`, `item`, `princiios`) que
  no deben copiarse sin corrección editorial.
- Parte de la lógica permanece en un archivo `app.R` extenso; un inventario de
  funciones debe distinguir funciones del paquete, helpers y cálculo inline.
- Este mapa se obtuvo por inspección estática. La fase visual deberá confirmar
  estados reales, mensajes de error y comportamiento responsivo.
