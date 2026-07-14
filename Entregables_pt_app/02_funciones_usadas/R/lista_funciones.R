# ===================================================================
# Titulo: lista_funciones.R
# Entregable: 02
# Descripcion: Extrae y documenta todas las funciones usadas en app.R,
#   R/, ptcalc/R/ y reports/report_template.Rmd. El script parsea bloques
#   roxygen2 completos (titulo, descripcion, @param, @return, @examples,
#   @references, @seealso, @export, badges de lifecycle) y complementa con
#   anotaciones manuales para funciones internas de app.R y del reporte.
# Entrada: app.R, R/*.R, ptcalc/R/*.R, reports/report_template.Rmd
# Salida:
#   - Entregables_pt_app/02_funciones_usadas/funciones_extraidas.csv
#   - Entregables_pt_app/02_funciones_usadas/md/documentacion_funciones.md
# Referencia: ISO 13528:2022, ISO 17043:2023
# ===================================================================

library(roxygen2)
library(tidyverse)

# -------------------------------------------------------------------
# 1. Anotaciones manuales para funciones SIN roxygen2
# -------------------------------------------------------------------
# Cada fila describe una funcion interna de app.R o report_template.Rmd
# que carece de documentacion roxygen2. Los campos siguen el mismo
# esquema que la metadata extraida automaticamente.
# -------------------------------------------------------------------
anotaciones_manuales <- tibble::tribble(
  ~nombre_funcion, ~archivo, ~categoria, ~descripcion, ~parametros_desc, ~retorno, ~ejemplos, ~notas, ~referencia_iso,

  # --- Helpers de UI / utilidades ---
  "score_equation", "app.R", "UI / Utilidades",
  "Renderiza una ecuacion en LaTeX usando MathJax dentro de un div con estilo 'text-muted'.",
  "math: cadena LaTeX sin delimitadores (se envuelve en \\( ... \\)).",
  "Objeto Shiny (withMathJax + div).",
  'score_equation("z = \\frac{x - x_{pt}}{\\sigma_{pt}}")',
  "Usado para mostrar ecuaciones en paneles de ayuda.", NA,

  "safe_filename_stem", "app.R", "UI / Utilidades",
  "Limpia una cadena para usarla como nombre base de archivo: elimina espacios, tildes y caracteres especiales, colapsa guiones bajos y recorta extremos.",
  "x: valor a limpiar; fallback: nombre por defecto si x es vacio.",
  "Cadena de texto segura para usar en nombres de archivo.",
  'safe_filename_stem("Informe O3 Nivel Alto", "Informe_EA")',
  "Se usa al descargar informes y exportaciones.", NA,

  "%||%", "app.R", "UI / Utilidades",
  "Operador de coalescencia: devuelve x si no es NULL, de lo contrario y.",
  "x, y: valores a comparar.",
  "x o y.",
  'NULL %||% "default"',
  "Definido en app.R para evitar dependencias.", NA,

  # --- Servidor / orquestacion ---
  "server", "app.R", "Servidor Shiny",
  "Funcion servidor de la aplicacion Shiny. Contiene toda la logica reactiva, helpers internos, carga de datos, calculos de homogeneidad/estabilidad/puntajes y generacion de reportes.",
  "input, output, session: objetos Shiny estandar.",
  "Efectos secundarios en la sesion Shiny; no retorna valor.",
  NA,
  "Es la funcion principal de la aplicacion; las demas funciones documentadas en app.R estan anidadas o relacionadas con ella.", NA,

  "empty_algo_df", "app.R", "Reportes",
  "Devuelve un data frame vacio con la estructura esperada para resultados del Algoritmo A (usado como plantilla).",
  "Ninguno.",
  "Data frame vacio.",
  NA,
  "Defensa contra resultados nulos en reportes.", NA,

  "empty_consensus_df", "app.R", "Reportes",
  "Devuelve un data frame vacio con la estructura esperada para resumenes de consenso (usado como plantilla).",
  "Ninguno.",
  "Data frame vacio.",
  NA,
  "Defensa contra resultados nulos en reportes.", NA,

  "run_workflow_script", "app.R", "Servidor Shiny",
  "Ejecuta un script R externo a traves de Rscript en un proceso separado, capturando salida estandar y error.",
  "script: ruta al script; args: vector de argumentos de linea de comandos.",
  "Lista con status (codigo de salida) y output (texto concatenado).",
  'run_workflow_script("scripts/aplicativo/preprocesar_calaire.R", c("--input", "datos.csv"))',
  "Se usa para lanzar pipelines de preprocesamiento desde la UI.", NA,

  "save_preprocessor_raw_files", "app.R", "Servidor Shiny",
  "Guarda en disco los archivos raw seleccionados por el preprocesador y devuelve sus rutas temporales.",
  "raw_files: data frame con columnas name y datapath (tipico de input$file).",
  "Vector de rutas de archivo guardadas.",
  NA,
  "Funcion interna del preprocesador de datos CALAIRE.", NA,

  # --- Carga y normalizacion de datos ---
  "read_hom_stab_csv", "app.R", "Carga y Normalizacion",
  "Lee un CSV de homogeneidad o estabilidad con vroom y valida que contenga las columnas 'value', 'pollutant' y 'level'.",
  "path: ruta al archivo; label: etiqueta ('homogeneidad' o 'estabilidad') para mensajes de error.",
  "Data frame leido o mensaje de validacion Shiny si falla.",
  'read_hom_stab_csv("homogeneity.csv", "homogeneidad")',
  "Punto de entrada para los reactivos hom_data_full() y stab_data_full().", NA,

  "get_calaire_reference_for_combo", "app.R", "Carga y Normalizacion",
  "Filtra el data frame de referencia CALAIRE para devolver la fila correspondiente a un analito y nivel.",
  "target_pollutant: codigo del analito; target_level: nivel.",
  "Data frame filtrado o NULL si no hay referencia.",
  NA,
  "Depende del reactive calaire_reference_df().", NA,

  "infer_n_lab", "app.R", "Carga y Normalizacion",
  "Infere la columna n_lab (numero de laboratorio) de un data frame. Primero busca una columna existente, luego un patron en el nombre de archivo y finalmente cuenta participantes distintos por combinacion.",
  "df: data frame; filename: nombre de archivo opcional para extraer n_lab.",
  "Data frame con columna n_lab anadida o preservada.",
  'infer_n_lab(df, "ronda_n12_o3.csv")',
  "Permite compatibilidad con archivos que no incluyen n_lab explicitamente.", NA,

  "normalize_participant_uncertainty", "app.R", "Carga y Normalizacion",
  "Normaliza la incertidumbre reportada por participantes. Detecta alias de incertidumbre expandida (u_exp, U(xi), etc.) y factor de cobertura k, y deriva u_value cuando no esta presente. Advierte si hay inconsistencia entre u_value y u_exp/k.",
  "df: data frame con columnas de incertidumbre.",
  "Data frame con columnas u_exp, k_factor y u_value normalizadas.",
  NA,
  "Escala entre incertidumbre estandar y expandida para calculos zeta/En.", NA,

  "normalize_u_df", "app.R", "Carga y Normalizacion",
  "Normaliza un data frame de incertidumbres proveniente de un archivo consolidado: asegura columnas estandar, convierte formatos y emite notificaciones si detecta inconsistencias.",
  "df: data frame; source_label: etiqueta descriptiva; notify: mostrar notificaciones.",
  "Data frame normalizado.",
  NA,
  "Usada en la carga de archivos de incertidumbre.", NA,

  "normalize_pollutant_code", "app.R", "Carga y Normalizacion",
  "Normaliza codigos de analito a mayusculas, reemplaza subindices unicode por digitos y elimina caracteres no alfanumericos.",
  "pollutant: vector de codigos.",
  "Vector de codigos normalizados.",
  'normalize_pollutant_code("NO₂") # devuelve "NO2"',
  "Permite comparar contaminantes aunque vengan con diferentes formatos.", NA,

  "normalize_n", "app.R", "Carga y Normalizacion",
  "Normaliza valores de n (numero de laboratorio / ronda) a entero, limpiando prefijos como 'N' o 'n'.",
  "df: data frame con columna n_lab.",
  "Data frame con n_lab como entero.",
  NA,
  "Funcion interna del preprocesamiento.", NA,

  "get_wide_data", "app.R", "Carga y Normalizacion",
  "Transforma datos en formato largo a formato ancho (una fila por item, columnas sample_1, sample_2, ...) filtrando por analito.",
  "df: data frame largo; target_pollutant: analito a filtrar.",
  "Data frame ancho o NULL si no hay datos.",
  NA,
  "Usada tanto en app.R como en report_template.Rmd.", NA,

  # --- Formateo ---
  "format_num", "app.R", "Formateo",
  "Formatea un numero a n_digits decimales, manejando valores no finitos como cadena vacia.",
  "x: valor numerico; n_digits: numero de decimales (default 4).",
  "Cadena de texto formateada.",
  'format_num(pi, 3) # "3.142"',
  NA, NA,

  "format_numeric_columns", "app.R", "Formateo",
  "Aplica format_num a un conjunto de columnas numericas de un data frame.",
  "df: data frame; columns: nombres de columnas (default: todas las numericas).",
  "Data frame con columnas formateadas como texto.",
  NA,
  NA, NA,

  "stable_sigfig_value", "pt_robust_stats.R", "Estadisticos Robustos",
  "Redondea un valor al numero de cifras significativas estables usado por el Algoritmo A para verificar convergencia.",
  "x: valor numerico; digits: numero de cifras significativas (default 3).",
  "Valor redondeado.",
  NA,
  "Funcion interna de run_algorithm_a; no se exporta.", "ISO 13528:2022, Annex C",

  "format_convergence_method", "app.R", "Formateo",
  "Traduce el metodo de convergencia del Algoritmo A a una etiqueta legible en espanol.",
  "method: cadena ('signif3', 'numerical_guard', NA).",
  "Cadena descriptiva.",
  'format_convergence_method("signif3")',
  "Usado en tablas de resultados del Algoritmo A.", NA,

  # --- Algoritmo A / estadisticos robustos (wrappers app.R) ---
  "get_algo_a_stabilization_iter", "app.R", "Estadisticos Robustos",
  "Extrae el numero de iteracion en la que el Algoritmo A alcanzo la convergencia, a partir del data frame de iteraciones.",
  "res: lista de resultado de run_algorithm_a.",
  "Entero con la iteracion de convergencia o NA.",
  NA,
  "Wrapper utilitario para reportes.", "ISO 13528:2022, Annex C",

  # --- Homogeneidad y estabilidad (wrappers app.R) ---
  "compute_homogeneity_metrics", "app.R", "Homogeneidad y Estabilidad",
  "Calcula metricas completas de homogeneidad para un analito y nivel: estadisticos descriptivos, ANOVA, sigma_pt (MADe y nIQR), criterios ISO y conclusiones.",
  "target_pollutant: analito; target_level: nivel.",
  "Lista extensa con tablas, valores, criterios, conclusiones y clase CSS para la UI.",
  NA,
  "Depende de hom_data_full() y funciones de ptcalc. Devuelve la informacion necesaria para llenar la pestana de homogeneidad y para los calculos de puntajes.", "ISO 13528:2022, Section 9.2",

  "compute_stability_metrics", "app.R", "Homogeneidad y Estabilidad",
  "Calcula metricas de estabilidad comparando datos de estabilidad con los resultados de homogeneidad para un analito y nivel.",
  "target_pollutant: analito; target_level: nivel; hom_results: resultado de compute_homogeneity_metrics().",
  "Lista con estadisticos de estabilidad, criterios, conclusiones y contribucion u_stab.",
  NA,
  "Depende de stab_data_full() y hom_results.", "ISO 13528:2022, Section 9.3",

  "build_homogeneity_export_df", "app.R", "Homogeneidad y Estabilidad",
  "Construye un data frame limpio con los resultados de homogeneidad para descarga.",
  "Ninguno (usa reactives internos).",
  "Data frame exportable.",
  NA,
  "Vinculado al boton de descarga de resultados de homogeneidad.", "ISO 13528:2022, Section 9.2",

  "build_stability_export_df", "app.R", "Homogeneidad y Estabilidad",
  "Construye un data frame limpio con los resultados de estabilidad para descarga.",
  "Ninguno (usa reactives internos).",
  "Data frame exportable.",
  NA,
  "Vinculado al boton de descarga de resultados de estabilidad.", "ISO 13528:2022, Section 9.3",

  # --- Calculo de puntajes (wrappers app.R) ---
  "compute_scores_metrics", "app.R", "Puntajes PT",
  "Calcula puntajes z, z', zeta y En para un conjunto de participantes dados x_pt, sigma_pt y u_xpt, incluyendo contribuciones de homogeneidad y estabilidad.",
  "summary_df: datos resumidos; target_pollutant, target_n_lab, target_level: seleccion; sigma_pt, u_xpt, k: parametros; m: replicados; u_hom, u_stab: contribuciones adicionales.",
  "Lista con data frame de puntajes, resumenes y metadata de la combinacion.",
  NA,
  "Version vectorizada/orquestadora usada por los reportes globales.", "ISO 13528:2022, Section 10",

  "compute_combo_scores", "app.R", "Puntajes PT",
  "Calcula los cuatro puntajes (z, z', zeta, En) para un grupo de participantes y una combinacion analito/nivel/n_lab, usando u_xpt definida que incluye u_hom y u_stab.",
  "participants_df: data frame de participantes; x_pt, sigma_pt, u_xpt: parametros de referencia; combo_meta: lista con title y label; k: factor de cobertura; u_hom, u_stab: incertidumbres adicionales.",
  "Lista con data frame ampliado (incluyendo columnas *_score y *_eval) o mensaje de error.",
  NA,
  "Funcion nuclear del calculo de puntajes en app.R.", "ISO 13528:2022, Section 10",

  "compute_scores_for_selection", "app.R", "Puntajes PT",
  "Orquesta el flujo completo de puntajes para una seleccion de analito, n_lab y nivel: obtiene parametros de homogeneidad, carga datos de participantes, deriva incertidumbres y calcula puntajes.",
  "target_pollutant, target_n_lab, target_level: seleccion; summary_data: datos consolidados; max_iter, k_factor: parametros.",
  "Lista con resultados de puntajes, resumenes, graficos y errores si los hay.",
  NA,
  "Punto de entrada principal para la pestana de puntajes.", "ISO 13528:2022, Section 10",

  "calculate_expert_sigma_pt", "app.R", "Puntajes PT",
  "Calcula sigma_pt a partir de parametros expertos (modelo lineal a*x_pt + b) por analito, segun tabla interna de CALAIRE.",
  "pollutant: codigo del analito; x_pt: valor asignado.",
  "Valor numerico de sigma_pt o NA.",
  NA,
  "Metodo 'Expertos' (codigo 4) en build_xpt_summary_row().", NA,

  "calculate_expert_u_xpt", "app.R", "Puntajes PT",
  "Calcula la incertidumbre estandar del valor asignado como 0.3% del valor asignado (0.003 * x_pt).",
  "x_pt: valor asignado.",
  "Incertidumbre estandar u_xpt.",
  NA,
  "Usado por el metodo 'Expertos'.", NA,

  "evaluate_u_xpt_sigma_criterion", "app.R", "Puntajes PT",
  "Evalua si la incertidumbre del valor asignado cumple el criterio ISO u(x_pt) <= 0.3 * sigma_pt.",
  "u_xpt_def: incertidumbre definida; sigma_pt: desviacion estandar de evaluacion.",
  "Cadena con la conclusion ('Cumple' / 'No cumple' / 'No evaluable').",
  NA,
  "Determina si se debe usar z' o zeta/En en lugar de z.", "ISO 13528:2022, Section 10",

  "ensure_classification_columns", "app.R", "Puntajes PT",
  "Garantiza que un data frame contenga las columnas de clasificacion usadas por los reportes; las crea con NA si no existen.",
  "df: data frame.",
  "Data frame con columnas classification_z_en, classification_z_en_code, classification_zprime_en, classification_zprime_en_code.",
  NA,
  "Defensa contra data frames antiguos o incompletos.", NA,

  # --- Visualizacion ---
  "plot_scores", "app.R", "Visualizacion",
  "Genera un grafico ggplot de puntajes por participante con lineas de advertencia y accion opcionales.",
  "df: data frame; score_col: columna de puntaje; title, subtitle, ylab: etiquetas; warn_limits, action_limits: vectores de limites.",
  "Objeto ggplot.",
  NA,
  "Usado en la pestana de puntajes y en reportes.", NA,

  "create_combo_plot", "app.R", "Visualizacion",
  "Crea un grafico combinado (valores del participante vs referencia + evolucion del puntaje) por nivel, usando patchwork.",
  "df: data frame; score_col: columna de puntaje; title_suffix: sufijo del titulo; limit_lines, limit_colors, show_legend: opciones graficas.",
  "Objeto ggplot combinado.",
  NA,
  "Usado en el anexo C del reporte por participante.", NA,

  "render_global_score_heatmap", "app.R", "Visualizacion",
  "Renderiza un heatmap interactivo de puntajes por participante y nivel usando plotly.",
  "output_id: id del output Shiny; combo_key, score_col, eval_col: columnas a visualizar; palette: paleta de colores; title_prefix: prefijo del titulo.",
  "Efecto secundario: asigna output[[output_id]].",
  NA,
  "Usado en la seccion de reportes globales.", NA,

  # --- Reportes y resumenes ---
  "get_scores_result", "app.R", "Reportes",
  "Obtiene el resultado de puntajes almacenado en reactiveValues para una combinacion analito/n_lab/nivel.",
  "pollutant, n_lab, level: identificadores de la combinacion.",
  "Lista con resultados o NULL.",
  NA,
  "Usado para evitar recalcular puntajes en multiples outputs.", NA,

  "combine_scores_result", "app.R", "Reportes",
  "Combina multiples resultados de puntajes (lista) en un unico data frame, anadiendo metadatos de combinacion.",
  "res: lista de resultados de compute_scores_metrics() o similares.",
  "Data frame combinado o mensaje de error.",
  NA,
  "Usado en reportes globales que agregan varias combinaciones.", NA,

  "get_global_summary_row", "app.R", "Reportes",
  "Filtra la tabla global_report_summary() para la combinacion y etiqueta seleccionadas en la UI.",
  "spec: lista con label de la combinacion.",
  "Tibble filtrado.",
  NA,
  "Helper para reportes globales.", NA,

  "get_global_overview_data", "app.R", "Reportes",
  "Filtra la tabla global_report_overview() para la combinacion seleccionada en la UI.",
  "spec: lista con title de la combinacion.",
  "Tibble filtrado.",
  NA,
  "Helper para reportes globales.", NA,

  "get_combo_levels_order", "app.R", "Reportes",
  "Devuelve los niveles de un conjunto de combinaciones ordenados numericamente.",
  "combos_filtered: data frame con columna level.",
  "Vector de niveles ordenados.",
  NA,
  "Usado para ordenar ejes y tablas de reportes.", NA,

  "build_xpt_summary_row", "app.R", "Reportes",
  "Construye una fila del resumen de valor asignado para una combinacion analito/n_lab/nivel y un metodo dado. Los metodos son: 1=Referencia, 2a=Consenso MADe, 2b=Consenso nIQR, 3=Algoritmo A, 4=Expertos.",
  "pol, n, lev: identificadores; subset_data: datos filtrados; method_code: codigo de metodo.",
  "Data frame de una fila con Contaminante, Nivel, Metodo, x_pt, u_xpt, sigma_pt, etc.",
  NA,
  "Funcion central para el modulo de valor asignado.", "ISO 13528:2022, Sections 8-9",

  "calculate_method_scores_df", "app.R", "Reportes",
  "Calcula el resumen de valor asignado aplicando build_xpt_summary_row() a todas las combinaciones de un data frame para un metodo dado (y el metodo experto como comparacion si aplica).",
  "method_code: codigo de metodo.",
  "Data frame con resultados por combinacion.",
  NA,
  "Reactive que alimenta la tabla de valor asignado.", "ISO 13528:2022, Sections 8-9",

  "summarize_scores", "app.R", "Reportes",
  "Resume un data frame de puntajes calculando totales y porcentajes de cada categoria de evaluacion.",
  "df: data frame con columnas de evaluacion.",
  "Data frame resumen.",
  NA,
  "Usado en reportes y tablas de resumen.", NA,

  "count_eval", "app.R", "Reportes",
  "Cuenta el numero de ocurrencias de una categoria de evaluacion en una columna.",
  "eval_col: vector de categorias; eval_type: categoria a contar.",
  "Entero con el conteo.",
  NA,
  "Helper de summarize_scores().", NA,

  "scalar_or_default", "app.R", "Reportes",
  "Devuelve el valor de una columna si es escalar unico, o un valor por defecto.",
  "x: valor; default: valor por defecto.",
  "Valor escalar o default.",
  NA,
  "Usado en la generacion de reportes parametrizados.", NA,

  # --- Claves y hashing ---
  "algo_key", "app.R", "UI / Utilidades",
  "Genera una clave unica para una combinacion analito/n_lab/nivel usando '||' como separador.",
  "pollutant, n_lab, level: identificadores.",
  "Cadena de texto.",
  'algo_key("O3", 12, "Nivel 1")',
  "Usada para indexar resultados en reactiveValues.", NA,

  # --- Report template helpers ---
  "is_nonempty_df", "report_template.Rmd", "Reportes",
  "Verifica si un objeto es un data frame no vacio.",
  "x: objeto.",
  "Logical TRUE/FALSE.",
  'is_nonempty_df(data.frame(a = 1))',
  "Helper del reporte Rmd.", NA,

  "safe_param_df", "report_template.Rmd", "Reportes",
  "Devuelve un data frame pasado por params o un data frame vacio si no es valido.",
  "x: objeto (params$...).",
  "Data frame.",
  NA,
  "Defensa contra parametros nulos en Rmd.", NA,

  "safe_rename_by_position", "report_template.Rmd", "Reportes",
  "Renombra las primeras columnas de un data frame segun un vector de etiquetas, si el data frame no esta vacio.",
  "df: data frame; labels: vector de nombres.",
  "Data frame renombrado.",
  NA,
  "Usado para formatear tablas de reportes.", NA,

  "selected_summary_data", "report_template.Rmd", "Reportes",
  "Filtra params$summary_data por n_lab y level si estan definidos.",
  "Ninguno (usa params del Rmd).",
  "Data frame filtrado.",
  NA,
  "Helper del reporte Rmd.", NA,

  "round_summary_data", "report_template.Rmd", "Reportes",
  "Filtra params$summary_data por n_lab si esta definido (alias de selected_summary_data sin filtro de level).",
  "Ninguno (usa params del Rmd).",
  "Data frame filtrado.",
  NA,
  "Helper del reporte Rmd.", NA,

  "participant_count", "report_template.Rmd", "Reportes",
  "Cuenta el numero de participantes unicos (excluyendo 'ref' y NA) en un data frame.",
  "df: data frame con columna participant_id.",
  "Entero.",
  NA,
  "Usado para mostrar el numero de participantes en el reporte.", NA,

  "run_algorithm_a_report", "report_template.Rmd", "Estadisticos Robustos",
  "Wrapper del Algoritmo A para el reporte Rmd. Llama a run_algorithm_a de ptcalc con tolerancia 1e-03 y devuelve una lista simplificada (mean, sd, error).",
  "values: vector numerico; max_iter: iteraciones maximas.",
  "Lista con mean (valor asignado robusto), sd (desviacion robusta) y error.",
  'run_algorithm_a_report(c(10, 10.1, 9.9, 50))',
  "Asegura consistencia de tolerancia con app.R.", "ISO 13528:2022, Annex C",

  "compute_homogeneity", "report_template.Rmd", "Homogeneidad y Estabilidad",
  "Wrapper del calculo de homogeneidad para el reporte Rmd. Pasa datos en formato largo a ancho y llama a calculate_homogeneity_stats de ptcalc.",
  "data_full: datos largos; pol: analito; lev: nivel.",
  "Lista de estadisticos de homogeneidad o NULL si no hay datos/error.",
  NA,
  "Usado en secciones de homogeneidad del informe.", "ISO 13528:2022, Section 9.2",

  # --- Funciones obsoletas ---
  "algorithm_A", "utils.R", "Obsoleto",
  "Version anterior del Algoritmo A (ISO 13528). Deprecada: usar run_algorithm_a().",
  "x: vector numerico; max_iter: iteraciones maximas.",
  "Lista con robust_mean y robust_sd.",
  NA,
  "Se mantiene solo por compatibilidad hacia atras.", "ISO 13528:2022, Annex C",

  "mad_e_manual", "utils.R", "Obsoleto",
  "Version manual de calculate_mad_e(). Deprecada.",
  "x: vector numerico.",
  "Valor MADe.",
  NA,
  "Se mantiene solo por compatibilidad hacia atras.", "ISO 13528:2022, Section 9.4",

  "nIQR_manual", "utils.R", "Obsoleto",
  "Version manual de calculate_niqr(). Deprecada.",
  "x: vector numerico.",
  "Valor nIQR.",
  NA,
  "Se mantiene solo por compatibilidad hacia atras.", "ISO 13528:2022, Section 9.4"
)

# -------------------------------------------------------------------
# 2. Configuracion de archivos fuente
# -------------------------------------------------------------------
# Fuentes canonicas del entregable 02: app.R, funciones de calculo en ptcalc/R,
# wrappers en R/ (utils.R es obsoleto) y helpers del reporte Rmd.
# Se EXCLUYEN scripts de preprocessing (R/preprocessing/) y use-cases secundarios.
app_file <- "app.R"
ptcalc_r_files <- c(
  "ptcalc/R/pt_homogeneity.R",
  "ptcalc/R/pt_robust_stats.R",
  "ptcalc/R/pt_scores.R"
)
r_files <- c(
  "R/pt_homogeneity.R",
  "R/pt_robust_stats.R",
  "R/pt_scores.R",
  "R/utils.R"
)
report_template <- "reports/report_template.Rmd"

# Orden de preferencia para deduplicar: ptcalc/R > R/ > app.R > reports/
archivo_orden <- c(ptcalc_r_files, r_files, app_file, report_template)

# -------------------------------------------------------------------
# 3. Funciones de extraccion
# -------------------------------------------------------------------

# Detecta badges de lifecycle en texto roxygen
extraer_lifecycle <- function(bloque) {
  linea <- stringr::str_subset(bloque, "lifecycle::badge")
  if (length(linea) == 0) return(NA_character_)
  badge <- stringr::str_match(linea, 'badge\\("([^"]+)"\\)')[, 2]
  badge[!is.na(badge)][1]
}

# Extrae referencia ISO de un bloque roxygen (lineas con 'Reference:' o '@references')
extraer_referencia <- function(bloque) {
  ref_lines <- stringr::str_subset(bloque, "^(#'[[:space:]]*)?(Reference:|@references)")
  if (length(ref_lines) == 0) return(NA_character_)
  refs <- stringr::str_replace(ref_lines, "^(#'[[:space:]]*)?(Reference:|@references)[[:space:]]*", "")
  paste(stringr::str_trim(refs), collapse = "; ")
}

# Extrae tags @param, @return, @examples, @seealso, @export de un bloque
parse_roxygen_bloque <- function(bloque) {
  # Limpiar prefijo #'
  lineas <- stringr::str_replace(bloque, "^#'[[:space:]]?", "")

  # Titulo y descripcion: primeras lineas antes de cualquier @
  es_tag <- stringr::str_detect(lineas, "^@")
  idx_first_tag <- which(es_tag)[1]
  if (is.na(idx_first_tag)) idx_first_tag <- length(lineas) + 1

  header_lines <- lineas[seq_len(idx_first_tag - 1)]
  header_lines <- header_lines[header_lines != ""]
  # Separar lineas de referencia del header para no incluirlas en descripcion
  ref_mask <- stringr::str_detect(header_lines, "^(Reference:|@references)")
  header_lines <- header_lines[!ref_mask]

  titulo <- NA_character_
  descripcion <- NA_character_
  detalles <- NA_character_

  if (length(header_lines) > 0) {
    titulo <- header_lines[1]
    desc_lines <- header_lines[-1]
    # Separar descripcion de detalles si aparece @details
    if (any(stringr::str_detect(desc_lines, "^@details"))) {
      det_idx <- which(stringr::str_detect(desc_lines, "^@details"))[1]
      descripcion <- paste(desc_lines[seq_len(det_idx - 1)], collapse = " ")
      detalles <- paste(stringr::str_replace(desc_lines[-seq_len(det_idx)], "^@details[[:space:]]*", ""), collapse = " ")
    } else {
      descripcion <- paste(desc_lines, collapse = " ")
    }
  }

  # Tags
  tag_names <- c("param", "return", "examples", "seealso", "references", "export", "description", "details")
  tags <- list()
  for (tag in tag_names) tags[[tag]] <- NA_character_

  current_tag <- NULL
  current_lines <- character()

  for (line in lineas) {
    tag_match <- stringr::str_match(line, "^@([a-zA-Z_]+)")
    if (!is.na(tag_match[1, 1])) {
      if (!is.null(current_tag)) {
        val <- paste(current_lines, collapse = "\n")
        if (is.na(tags[[current_tag]])) {
          tags[[current_tag]] <- val
        } else {
          tags[[current_tag]] <- paste(tags[[current_tag]], val, sep = "\n")
        }
      }
      current_tag <- tag_match[1, 2]
      rest <- stringr::str_trim(stringr::str_replace(line, "^@[a-zA-Z_]+[[:space:]]*", ""))
      current_lines <- if (rest == "") character() else rest
    } else if (!is.null(current_tag)) {
      current_lines <- c(current_lines, line)
    }
  }
  if (!is.null(current_tag)) {
    val <- paste(current_lines, collapse = "\n")
    if (is.na(tags[[current_tag]])) {
      tags[[current_tag]] <- val
    } else {
      tags[[current_tag]] <- paste(tags[[current_tag]], val, sep = "\n")
    }
  }

  # Sobrescribir descripcion si existe @description
  if (!is.na(tags$description) && nzchar(tags$description)) {
    descripcion <- tags$description
  }
  if (!is.na(tags$details) && nzchar(tags$details)) {
    detalles <- tags$details
  }

  limpiar_links <- function(x) {
    if (is.na(x)) return(x)
    x <- stringr::str_replace_all(x, "\\\\code\\{\\\\link\\{([^}]+)\\}\\}", "`\\1()`")
    x <- stringr::str_replace_all(x, "\\\\link\\{([^}]+)\\}", "`\\1()`")
    stringr::str_trim(x)
  }

  list(
    titulo = stringr::str_trim(titulo),
    descripcion = limpiar_links(stringr::str_trim(descripcion)),
    detalles = limpiar_links(stringr::str_trim(detalles)),
    parametros = tags$param,
    retorno = tags$return,
    ejemplos = tags$examples,
    seealso = limpiar_links(tags$seealso),
    exportada = !is.na(tags$export),
    referencia_iso = extraer_referencia(bloque)
  )
}

# Extrae firma raw de una funcion (contenido entre parentesis)
extraer_parametros_raw <- function(contenido, linea_idx) {
  k <- linea_idx
  abierto <- 0
  cerrado <- 0
  partes <- character()

  while (k <= length(contenido)) {
    linea_actual <- contenido[k]
    abierto <- abierto + stringr::str_count(linea_actual, "\\(")
    cerrado <- cerrado + stringr::str_count(linea_actual, "\\)")
    partes <- c(partes, linea_actual)
    if (abierto > 0 && abierto == cerrado) break
    k <- k + 1
  }

  texto <- paste(partes, collapse = " ")
  m <- stringr::str_match(texto, "function\\s*\\((.*)\\)")
  if (is.na(m[1, 1])) return(NA_character_)
  stringr::str_trim(m[1, 2])
}

# Extrae todas las funciones de un archivo
extraer_firmas <- function(ruta_archivo) {
  if (!file.exists(ruta_archivo)) {
    return(tibble(
      archivo_ruta = character(),
      archivo = character(),
      nombre_funcion = character(),
      parametros_raw = character(),
      titulo = character(),
      descripcion = character(),
      detalles = character(),
      parametros = character(),
      retorno = character(),
      ejemplos = character(),
      seealso = character(),
      exportada = logical(),
      referencia_iso = character(),
      lifecycle = character()
    ))
  }

  contenido <- readLines(ruta_archivo)
  n <- length(contenido)

  # Detectar lineas de definicion de funcion
  patron <- "^([[:space:]]*)([a-zA-Z_][a-zA-Z0-9_.]*)[[:space:]]*<-[[:space:]]*function"
  matches <- stringr::str_match(contenido, patron)
  idx_func <- which(!is.na(matches[, 1]))
  nombres <- matches[idx_func, 3]

  if (length(nombres) == 0) {
    return(tibble(
      archivo_ruta = character(),
      archivo = character(),
      nombre_funcion = character(),
      parametros_raw = character(),
      titulo = character(),
      descripcion = character(),
      detalles = character(),
      parametros = character(),
      retorno = character(),
      ejemplos = character(),
      seealso = character(),
      exportada = logical(),
      referencia_iso = character(),
      lifecycle = character()
    ))
  }

  out <- vector("list", length(nombres))

  for (i in seq_along(nombres)) {
    nombre <- nombres[i]
    linea_idx <- idx_func[i]

    # Buscar bloque roxygen hacia atras
    bloque <- character()
    j <- linea_idx - 1
    while (j >= 1 && stringr::str_detect(contenido[j], "^#'")) {
      bloque <- c(contenido[j], bloque)
      j <- j - 1
    }

    # Extraer parametros raw
    params_raw <- extraer_parametros_raw(contenido, linea_idx)

    if (length(bloque) > 0) {
      parsed <- parse_roxygen_bloque(bloque)
      lifecycle <- extraer_lifecycle(bloque)
      if (is.na(parsed$parametros)) parsed$parametros <- NA_character_
    } else {
      parsed <- list(
        titulo = NA_character_,
        descripcion = NA_character_,
        detalles = NA_character_,
        parametros = NA_character_,
        retorno = NA_character_,
        ejemplos = NA_character_,
        seealso = NA_character_,
        exportada = FALSE,
        referencia_iso = NA_character_
      )
      lifecycle <- NA_character_
    }

    out[[i]] <- tibble(
      archivo_ruta = ruta_archivo,
      archivo = basename(ruta_archivo),
      nombre_funcion = nombre,
      parametros_raw = params_raw,
      titulo = parsed$titulo,
      descripcion = parsed$descripcion,
      detalles = parsed$detalles,
      parametros = parsed$parametros,
      retorno = parsed$retorno,
      ejemplos = parsed$ejemplos,
      seealso = parsed$seealso,
      exportada = parsed$exportada,
      referencia_iso = parsed$referencia_iso,
      lifecycle = lifecycle
    )
  }

  bind_rows(out)
}

# -------------------------------------------------------------------
# 4. Procesar archivos
# -------------------------------------------------------------------
cat("Directorio de trabajo actual:", getwd(), "\n")

todas <- tibble(
  archivo_ruta = character(),
  archivo = character(),
  nombre_funcion = character(),
  parametros_raw = character(),
  titulo = character(),
  descripcion = character(),
  detalles = character(),
  parametros = character(),
  retorno = character(),
  ejemplos = character(),
  seealso = character(),
  exportada = logical(),
  referencia_iso = character(),
  lifecycle = character()
)

for (f in ptcalc_r_files) {
  todas <- bind_rows(todas, extraer_firmas(f))
  cat("Procesado ", f, "\n")
}

for (f in r_files) {
  todas <- bind_rows(todas, extraer_firmas(f))
  cat("Procesado ", f, "\n")
}

# app.R
todas <- bind_rows(todas, extraer_firmas(app_file))
cat("Procesado app.R\n")

# report_template.Rmd
if (file.exists(report_template)) {
  todas <- bind_rows(todas, extraer_firmas(report_template))
  cat("Procesado ", report_template, "\n")
}

cat("\nTotal funciones encontradas (antes de deduplicar):", nrow(todas), "\n")

# -------------------------------------------------------------------
# 5. Deduplicar por nombre, respetando preferencia de fuente
# -------------------------------------------------------------------
todas <- todas %>%
  mutate(prioridad = match(archivo_ruta, archivo_orden, nomatch = 999)) %>%
  arrange(prioridad) %>%
  group_by(nombre_funcion) %>%
  slice(1) %>%
  ungroup() %>%
  select(-prioridad)

cat("Total funciones unicas:", nrow(todas), "\n")

# -------------------------------------------------------------------
# 6. Fusionar con anotaciones manuales
# -------------------------------------------------------------------
todas <- todas %>%
  left_join(
    anotaciones_manuales %>%
      select(nombre_funcion, archivo = archivo, categoria_manual = categoria,
             descripcion_manual = descripcion, parametros_manual = parametros_desc,
             retorno_manual = retorno, ejemplos_manual = ejemplos, notas_manual = notas,
             referencia_manual = referencia_iso),
    by = c("nombre_funcion", "archivo")
  ) %>%
  mutate(
    categoria = coalesce(categoria_manual, "General"),
    descripcion = coalesce(descripcion_manual, descripcion, titulo, "Sin descripcion disponible."),
    parametros = coalesce(parametros_manual, parametros),
    retorno = coalesce(retorno_manual, retorno),
    ejemplos = coalesce(ejemplos_manual, ejemplos),
    notas = coalesce(notas_manual, ""),
    referencia_iso = coalesce(referencia_manual, referencia_iso)
  ) %>%
  select(-categoria_manual, -descripcion_manual, -parametros_manual,
         -retorno_manual, -ejemplos_manual, -notas_manual, -referencia_manual)

# Categorias por defecto para funciones con roxygen de ptcalc
mapa_categorias <- tibble(
  nombre_funcion = c(
    "calculate_niqr", "calculate_mad_e", "run_algorithm_a",
    "calculate_homogeneity_stats", "calculate_homogeneity_criterion",
    "calculate_homogeneity_criterion_expanded", "evaluate_homogeneity",
    "calculate_stability_stats", "calculate_stability_criterion",
    "calculate_stability_criterion_expanded", "evaluate_stability",
    "calculate_u_hom", "calculate_u_stab",
    "calculate_z_score", "calculate_z_prime_score", "calculate_zeta_score",
    "calculate_en_score", "evaluate_z_score", "evaluate_z_score_vec",
    "evaluate_en_score", "evaluate_en_score_vec"
  ),
  categoria = c(
    rep("Estadisticos Robustos", 3),
    rep("Homogeneidad y Estabilidad", 10),
    rep("Puntajes PT", 8)
  )
)

todas <- todas %>%
  left_join(mapa_categorias, by = "nombre_funcion") %>%
  mutate(categoria = coalesce(categoria.y, categoria.x, "General")) %>%
  select(-categoria.x, -categoria.y)

# Orden de categorias para el reporte
orden_categorias <- c(
  "Estadisticos Robustos",
  "Homogeneidad y Estabilidad",
  "Puntajes PT",
  "Carga y Normalizacion",
  "Formateo",
  "Visualizacion",
  "Reportes",
  "Servidor Shiny",
  "UI / Utilidades",
  "Obsoleto",
  "General"
)

todas <- todas %>%
  mutate(categoria = factor(categoria, levels = orden_categorias)) %>%
  arrange(categoria, nombre_funcion)

# La firma vigente ofrece dos ramas, pero su roxygen solo describe la primera.
# Se completa aquí para que el catálogo refleje también la rama sw/g usada por
# la aplicación, sin alterar el paquete ignorado que actúa como fuente funcional.
todas <- todas %>%
  mutate(
    descripcion = if_else(
      nombre_funcion == "calculate_homogeneity_criterion_expanded",
      paste(
        "Admite una rama con u_sigma_pt y otra con sw/g. La segunda retorna",
        "F1 * (0.3 * sigma_pt)^2 + F2 * sw^2; ambas ramas no tienen la misma",
        "forma dimensional."
      ),
      descripcion
    ),
    parametros = if_else(
      nombre_funcion == "calculate_homogeneity_criterion_expanded",
      paste(
        "sigma_pt Desviacion para evaluacion;\n",
        "u_sigma_pt Incertidumbre de sigma_pt para la primera rama;\n",
        "sw Desviacion dentro del item para la rama de tabla;\n",
        "g Numero de items, limitado al intervalo 7--20."
      ),
      parametros
    ),
    retorno = if_else(
      nombre_funcion == "calculate_homogeneity_criterion_expanded",
      paste(
        "Criterio expandido para la rama u_sigma_pt o expresion cuadratica",
        "para la rama sw/g."
      ),
      retorno
    )
  )

# -------------------------------------------------------------------
# 7. Guardar CSV ampliado
# -------------------------------------------------------------------
out_csv <- "Entregables_pt_app/02_funciones_usadas/funciones_extraidas.csv"
write.csv(
  todas %>%
    select(
      archivo, nombre_funcion, categoria, descripcion, parametros, retorno,
      ejemplos, referencia_iso, exportada, lifecycle, archivo_ruta
    ),
  out_csv,
  row.names = FALSE
)
cat("\nCSV guardado en:", out_csv, "\n")

# -------------------------------------------------------------------
# 8. Generar Markdown enriquecido
# -------------------------------------------------------------------
escapar_md <- function(x) {
  if (is.na(x) || !nzchar(x)) return("")
  # No escapamos todo para preservar LaTeX; solo evitamos problemas menores
  x
}

format_bloque <- function(titulo, contenido) {
  if (is.na(contenido) || !nzchar(contenido)) return("")
  paste0("**", titulo, "**\n\n", escapar_md(contenido), "\n\n")
}

format_code_block <- function(lang, contenido) {
  if (is.na(contenido) || !nzchar(contenido)) return("")
  paste0("```", lang, "\n", stringr::str_trim(contenido), "\n```\n\n")
}

format_param_list <- function(texto) {
  if (is.na(texto) || !nzchar(texto)) return("")
  lineas <- stringr::str_split(texto, "\n")[[1]]
  lineas <- lineas[lineas != ""]

  # Unir lineas continuas: en roxygen, las lineas de continuacion mantienen
  # sangria al quitar #' ; las nuevas entradas @param comienzan al inicio.
  unidas <- character()
  for (linea in lineas) {
    if (length(unidas) == 0 || !stringr::str_detect(linea, "^[[:space:]]")) {
      unidas <- c(unidas, stringr::str_trim(linea))
    } else {
      unidas[length(unidas)] <- paste(unidas[length(unidas)], stringr::str_trim(linea))
    }
  }

  items <- paste0("- ", unidas, collapse = "\n")
  paste0(items, "\n\n")
}

# Conteos
resumen_cat <- todas %>%
  group_by(categoria) %>%
  summarise(n = n(), .groups = "drop") %>%
  arrange(match(categoria, orden_categorias))

n_exportadas <- sum(todas$exportada, na.rm = TRUE)
n_obsoletas <- sum(todas$lifecycle == "deprecated", na.rm = TRUE)

contenido_md <- character()
contenido_md <- c(contenido_md, "# Documentacion de Funciones\n\n")
contenido_md <- c(contenido_md, "**Fecha de generacion:** ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n\n")
contenido_md <- c(contenido_md, "**Total funciones documentadas:** ", as.character(nrow(todas)), "\n\n")
contenido_md <- c(contenido_md, "**Funciones exportadas (`@export`):** ", as.character(n_exportadas), "\n\n")
contenido_md <- c(contenido_md, "**Funciones obsoletas (`lifecycle::badge('deprecated')`):** ", as.character(n_obsoletas), "\n\n")

contenido_md <- c(contenido_md, "## Convenciones\n\n")
contenido_md <- c(contenido_md, "- Las funciones del paquete `ptcalc` son calculos puros sin dependencias de Shiny.\n")
contenido_md <- c(contenido_md, "- Las funciones de `app.R` son helpers reactivos y de orquestacion de la interfaz.\n")
contenido_md <- c(contenido_md, "- Las funciones de `reports/report_template.Rmd` son helpers para la generacion de informes.\n")
contenido_md <- c(contenido_md, "- Las funciones de `R/utils.R` estan **obsoletas**; usen sus equivalentes en `ptcalc`.\n")
contenido_md <- c(contenido_md, "- Las referencias ISO siguen la nomenclatura `ISO 13528:2022, Seccion X.X`.\n\n")

contenido_md <- c(contenido_md, "## Resumen por Categoria\n\n")
contenido_md <- c(contenido_md, "| Categoria | Funciones |\n")
contenido_md <- c(contenido_md, "|-----------|-----------:|\n")
for (i in seq_len(nrow(resumen_cat))) {
  contenido_md <- c(contenido_md, "| ", as.character(resumen_cat$categoria[i]), " | ", as.character(resumen_cat$n[i]), " |\n")
}
contenido_md <- c(contenido_md, "\n---\n\n")

# Funciones por categoria
for (cat in levels(todas$categoria)) {
  cat_funcs <- todas %>% filter(categoria == cat)
  if (nrow(cat_funcs) == 0) next

  contenido_md <- c(contenido_md, "## Categoria: ", cat, "\n\n")

  for (i in seq_len(nrow(cat_funcs))) {
    f <- cat_funcs[i, ]

    badge <- ""
    if (!is.na(f$lifecycle) && f$lifecycle == "deprecated") {
      badge <- " `[OBSOLETO]`"
    }
    if (isTRUE(f$exportada)) {
      badge <- paste0(badge, " `[EXPORTADA]`")
    }

    contenido_md <- c(contenido_md, "### `", f$nombre_funcion, "`", badge, "\n\n")

    # Descripcion principal
    desc <- f$descripcion
    if (is.na(desc) || !nzchar(desc)) desc <- f$titulo
    if (is.na(desc) || !nzchar(desc)) desc <- "Sin descripcion disponible."
    contenido_md <- c(contenido_md, escapar_md(desc), "\n\n")

    if (!is.na(f$detalles) && nzchar(f$detalles)) {
      det_limpio <- stringr::str_replace_all(f$detalles, "Reference:[[:space:]]*ISO 13528:[^\n]*", "")
      det_limpio <- stringr::str_squish(det_limpio)
      if (nzchar(det_limpio)) {
        contenido_md <- c(contenido_md, format_bloque("Detalles", det_limpio))
      }
    }

    if (!is.na(f$parametros_raw) && nzchar(f$parametros_raw)) {
      contenido_md <- c(contenido_md, "**Firma:** `", f$nombre_funcion, "(", f$parametros_raw, ")`\n\n")
    }

    if (!is.na(f$parametros) && nzchar(f$parametros)) {
      contenido_md <- c(contenido_md, "**Parametros**\n\n", format_param_list(f$parametros))
    }

    if (!is.na(f$retorno) && nzchar(f$retorno)) {
      contenido_md <- c(contenido_md, format_bloque("Valor de retorno", f$retorno))
    }

    if (!is.na(f$ejemplos) && nzchar(f$ejemplos)) {
      contenido_md <- c(contenido_md, "**Ejemplo**\n\n", format_code_block("r", f$ejemplos))
    }

    if (!is.na(f$seealso) && nzchar(f$seealso)) {
      contenido_md <- c(contenido_md, format_bloque("Vease tambien", f$seealso))
    }

    if (!is.na(f$notas) && nzchar(f$notas)) {
      contenido_md <- c(contenido_md, format_bloque("Notas", f$notas))
    }

    contenido_md <- c(contenido_md, "**Archivo fuente:** `", f$archivo_ruta, "`\n\n")

    if (!is.na(f$referencia_iso) && nzchar(f$referencia_iso)) {
      contenido_md <- c(contenido_md, "**Referencia ISO:** ", f$referencia_iso, "\n\n")
    }

    contenido_md <- c(contenido_md, "---\n\n")
  }
}

out_md <- "Entregables_pt_app/02_funciones_usadas/md/documentacion_funciones.md"
contenido_md <- c(
  contenido_md,
  "## Evidencia visual\n\n",
  "La ejecución del Algoritmo A documentado en este catálogo se observa en ",
  "**CAP-09**. Consulte `../../00_evidencia_visual/indice_capturas.md` para ",
  "acción previa, datos, commit, resolución y SHA-256.\n"
)
documento_md <- stringr::str_replace(
  paste(contenido_md, collapse = ""),
  "\\n+$",
  "\\n"
)
writeLines(documento_md, out_md, sep = "")
cat("Documentacion Markdown guardada en:", out_md, "\n")

cat("\n=== RESUMEN POR CATEGORIA ===\n")
print(resumen_cat, n = Inf)
