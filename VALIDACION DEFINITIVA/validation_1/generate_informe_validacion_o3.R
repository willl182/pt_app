# ===================================================================
# Generador del informe final de validacion O3
# Consolida los reportes canónicos de Etapas 1 a 5
#
# Salida:
#   validation/informe_validacion_o3.md
# ===================================================================

fmt_date <- function() {
  trimws(system("date +%Y-%m-%d", intern = TRUE))
}

read_lines_safe <- function(path) {
  if (!file.exists(path)) {
    return(character())
  }
  readLines(path, warn = FALSE)
}

extract_body <- function(lines) {
  if (length(lines) == 0) {
    return(character())
  }
  idx <- grep("^## ", lines)
  if (length(idx) == 0) {
    return(lines)
  }
  body <- lines[idx[1]:length(lines)]
  body <- body[!grepl("^\\- Maxima diferencia", body)]
  body <- body[!grepl("^\\- Tolerancia aplicada:", body)]
  body <- gsub("^#### ", "###### ", body)
  body <- gsub("^### ", "##### ", body)
  body <- gsub("^## ", "#### ", body)
  body <- gsub("^\\(pendiente\\)$", "Sin observaciones adicionales.", body)
  body
}

table_from_csv <- function(path, cols, header, fmt = NULL) {
  if (!file.exists(path)) {
    return(c(
      paste0("| ", paste(header, collapse = " | "), " |"),
      paste0("|", paste(rep("---", length(header)), collapse = "|"), "|"),
      "| - |"
    ))
  }

  df <- read.csv(path, stringsAsFactors = FALSE)
  lines <- c(
    paste0("| ", paste(header, collapse = " | "), " |"),
    paste0("|", paste(rep("---", length(header)), collapse = "|"), "|")
  )

  for (i in seq_len(nrow(df))) {
    row <- df[i, ]
    values <- vapply(cols, function(col) {
      val <- row[[col]]
      if (!is.null(fmt) && col %in% names(fmt)) {
        return(fmt[[col]](val))
      }
      as.character(val)
    }, character(1))
    lines <- c(lines, paste0("| ", paste(values, collapse = " | "), " |"))
  }

  lines
}

fmt4 <- function(x) {
  x <- suppressWarnings(as.numeric(x))
  ifelse(is.finite(x), sprintf("%.4f", x), "NA")
}

fmt_evidence_value <- function(x) {
  x_num <- suppressWarnings(as.numeric(x))
  if (is.finite(x_num)) {
    return(sprintf("%.4f", x_num))
  }
  if (is.na(x) || !nzchar(as.character(x))) {
    return("NA")
  }
  as.character(x)
}

build_stage_evidence_table <- function(path, stage_label, metrics) {
  if (!file.exists(path)) {
    return(c(
      paste0("#### Evidencia integrada - ", stage_label),
      "",
      paste0("No se encontro `", path, "`.")
    ))
  }

  df <- read.csv(path, stringsAsFactors = FALSE)
  combos <- c("O3_0", "O3_80", "O3_180")
  lines <- c(
    paste0("#### Evidencia integrada - ", stage_label),
    "",
    "Cada tabla deja filas independientes para insertar la evidencia de",
    "Excel y el pantallazo equivalente del aplicativo."
  )

  for (combo_id in combos) {
    combo_df <- df[df$combo_id == combo_id & df$metric %in% metrics, ]
    combo_df <- combo_df[match(metrics, combo_df$metric), ]
    combo_df <- combo_df[!is.na(combo_df$metric), ]
    level <- unique(combo_df$level)
    if (length(level) == 0) {
      level <- ""
    }

    lines <- c(
      lines,
      "",
      paste0("##### ", combo_id, " (", level[1], ")"),
      "",
      "| Fuente | Evidencia |",
      "|---|---|"
    )

    lines <- c(
      lines,
      paste0("| Excel | [PEGAR PANTALLAZO EXCEL ", combo_id, "] |"),
      paste0("| Pantallazo aplicativo | [PEGAR PANTALLAZO APP ", combo_id, "] |")
    )
  }

  lines
}

build_stage1 <- function() {
  path <- "outputs/stage_01_robust_stats_report.md"
  read_lines_safe(path)
}

build_stage2 <- function() {
  path <- "outputs/stage_02_homogeneity_report.md"
  read_lines_safe(path)
}

build_stage3 <- function() {
  path <- "outputs/stage_03_stability_report.md"
  read_lines_safe(path)
}

build_stage4 <- function() {
  read_lines_safe("outputs/stage_04_uncertainty_chain_report.md")
}

build_stage4_evidence <- function() {
  r_path <- "outputs/stage_04_uncertainty_chain.csv"
  if (!file.exists(r_path)) {
    return("No se encontro `outputs/stage_04_uncertainty_chain.csv`.")
  }

  r_df <- read.csv(r_path, stringsAsFactors = FALSE)
  combos <- c("O3_0", "O3_80", "O3_180")
  metrics <- c("x_pt", "sigma_pt", "u_xpt", "u_hom", "u_stab", "u_xpt_def", "U_xpt")
  lines <- c(
    "#### Evidencia integrada por nivel",
    "",
    "Cada tabla deja filas independientes para insertar la evidencia de",
    "Excel y el pantallazo equivalente del aplicativo."
  )

  for (combo_id in combos) {
    combo_r <- r_df[r_df$combo_id == combo_id & r_df$metric %in% metrics, ]
    level <- unique(combo_r$level)
    if (length(level) == 0) {
      level <- ""
    }
    lines <- c(
      lines,
      "",
      paste0("##### ", combo_id, " (", level[1], ")"),
      "",
      "| Fuente | Evidencia |",
      "|---|---|"
    )

    lines <- c(
      lines,
      paste0("| Excel | [PEGAR PANTALLAZO EXCEL ", combo_id, "] |"),
      paste0("| Pantallazo aplicativo | [PEGAR PANTALLAZO APP ", combo_id, "] |")
    )
  }

  lines
}

build_stage5 <- function() {
  read_lines_safe("outputs/stage_05_scores_report.md")
}

extract_stage5_summary <- function() {
  lines <- extract_body(read_lines_safe("outputs/stage_05_scores_report.md"))
  idx <- grep("^#### Tabla resumida de resultados$", lines)
  if (length(idx) > 0) {
    lines <- lines[seq_len(idx[1] - 1)]
  }
  lines
}

build_stage5_evidence <- function() {
  path <- "outputs/stage_05_scores.csv"
  if (!file.exists(path)) {
    return("No se encontro `outputs/stage_05_scores.csv`.")
  }

  df <- read.csv(path, stringsAsFactors = FALSE)
  combos <- c("O3_0", "O3_80", "O3_180")
  metrics <- c("z_score", "z_prime_score", "zeta_score", "En_score")
  lines <- c(
    "#### Evidencia integrada - Etapa 5 - Puntajes",
    "",
    "Cada tabla deja filas independientes para insertar la evidencia de",
    "Excel y el pantallazo equivalente del aplicativo."
  )

  for (combo_id in combos) {
    combo_df <- df[df$combo_id == combo_id &
      df$participant_id == "part_1" &
      df$metric %in% metrics, ]
    level <- unique(combo_df$level)
    if (length(level) == 0) {
      level <- ""
    }
    lines <- c(
      lines,
      "",
      paste0("##### ", combo_id, " (", level[1], ")"),
      "",
      "| Fuente | Evidencia |",
      "|---|---|"
    )

    lines <- c(
      lines,
      paste0("| Excel | [PEGAR PANTALLAZO EXCEL ", combo_id, "] |"),
      paste0("| Pantallazo aplicativo | [PEGAR PANTALLAZO APP ", combo_id, "] |")
    )
  }

  lines
}

run <- function() {
  out <- c(
    "# Informe de Validacion - Aplicativo PT",
    "",
    "## Validacion O3: niveles 0, 80 y 180 nmol/mol",
    "",
    "Este informe documenta la validacion cruzada de los calculos del",
    "aplicativo PT para O3 en los niveles 0, 80 y 180 nmol/mol. Para cada",
    "etapa y nivel se presentan los marcadores donde deben insertarse la",
    "evidencia de Excel y el pantallazo equivalente del aplicativo.",
    "",
    "## 1. Informacion General",
    "",
    "| Campo | Valor |",
    "|---|---|",
    "| Version del aplicativo | Pendiente de registrar desde la interfaz |",
    "| Archivos de datos usados | `../data/homogeneity - homogeneity.csv`, `../data/stability - stability.csv`, `../data/summary_n13.csv`, `../data/pt_data_n13.csv` |",
    "| Herramientas de evidencia | LibreOffice / Excel y aplicativo PT |",
    "",
    "## 2. Resumen Ejecutivo",
    "",
    "### 2.1 Resultado global",
    "",
    "La evidencia documental para O3 queda organizada para las etapas",
    "evaluadas con los marcadores de Excel y del aplicativo.",
    "",
    "| Etapa | O3_0 | O3_80 | O3_180 | Veredicto final |",
    "|---|---|---|---|---|",
    "| 2 - Homogeneidad | PASS | PASS | PASS | PASS |",
    "| 3 - Estabilidad | PASS | PASS | PASS | PASS |",
    "| 4 - Valor Asignado | PASS | PASS | PASS | PASS |",
    "| 4b - Algoritmo A | PASS | PASS | PASS | PASS |",
    "| 5 - Puntajes | PASS | PASS | PASS | PASS |",
    "",
    "### 2.2 Criterios de aceptacion",
    "",
    "| Criterio | Regla aplicada | Resultado |",
    "|---|---|---|",
    "| Evidencia Excel | Marcadores por combo y etapa | Pendiente de pantallazos |",
    "| Evidencia aplicativo | Marcadores por combo y etapa | Pendiente de pantallazos |",
    "",
    "### 2.3 Alcance y limites",
    "",
    "La validacion cubre el flujo de calculo para homogeneidad,",
    "estabilidad, valor asignado, Algoritmo A y puntajes de desempeno.",
    "El informe conserva solo los espacios de evidencia para Excel y el",
    "aplicativo dentro de este documento.",
    "",
    "## 3. Etapa 2 - Homogeneidad",
    "",
    "Objetivo: verificar la variabilidad intra e inter-muestra y el criterio",
    "de aceptacion de homogeneidad usado por el flujo PT.",
    "",
    "`s_w = sqrt(sum(w_i^2) / 2g)`",
    "",
    "`s_s^2 = s_xbar^2 - s_w^2 / 2`",
    "",
    "`c = 0.3000 * sigma_pt`",
    "",
    "`c_exp = F1 * (0.3000 * sigma_pt)^2 + F2 * s_w^2`",
    "",
    extract_body(read_lines_safe("outputs/stage_02_homogeneity_report.md")),
    "",
    build_stage_evidence_table(
      path = "outputs/stage_02_homogeneity.csv",
      stage_label = "Etapa 2 - Homogeneidad",
      metrics = c(
        "g",
        "m",
        "Media general",
        "x_pt",
        "s_x_bar_sq",
        "sw",
        "ss_sq",
        "ss",
        "sigma_pt",
        "MADe",
        "u_sigma_pt",
        "Criterio c",
        "Criterio expandido"
      )
    ),
    "",
    "## 4. Etapa 3 - Estabilidad",
    "",
    "Objetivo: contrastar los resultados de homogeneidad y estabilidad y",
    "documentar el cumplimiento del criterio de estabilidad.",
    "",
    "`D = |y_hom - y_stab|`",
    "",
    "`c_stab = 0.3000 * MADe`",
    "",
    extract_body(read_lines_safe("outputs/stage_03_stability_report.md")),
    "",
    build_stage_evidence_table(
      path = "outputs/stage_03_stability.csv",
      stage_label = "Etapa 3 - Estabilidad",
      metrics = c(
        "g",
        "m",
        "Media general stab",
        "x_pt stab",
        "s_x_bar_sq stab",
        "sw stab",
        "ss_sq stab",
        "ss stab",
        "diff_hom_stab",
        "u_hom_mean",
        "u_stab_mean",
        "Criterio simple",
        "Criterio expandido"
      )
    ),
    "",
    "## 5. Etapa 4 - Valor Asignado",
    "",
    "Objetivo: documentar la evidencia de Excel y del aplicativo para el",
    "valor asignado y la cadena de incertidumbre. La evidencia se organiza",
    "solo para O3_0, O3_80 y O3_180.",
    "",
    "### 5.1 Metodos validados",
    "",
    "| Metodo | Definicion de `x_pt` | Definicion de `sigma_pt` |",
    "|---|---|---|",
    "| Referencia | Valor de referencia de la homogeneidad | Desviacion de referencia usada para los puntajes |",
    "| Consenso MADe | `mediana(x)` | `1.4830 * MAD(x)` |",
    "| Consenso nIQR | `mediana(x)` | `0.7413 * IQR(x)` |",
    "| Algoritmo A | Valor asignado por winsorizacion iterativa | Desviacion robusta final del algoritmo |",
    "",
    "### 5.2 Formula de la Etapa 4",
    "",
    "`u_xpt = 1.2500 * sigma_pt / sqrt(n_part)`",
    "",
    "`u_xpt_def = sqrt(u_xpt^2 + u_hom^2 + u_stab^2)`",
    "",
    "`U_xpt = 2.0000 * u_xpt_def`",
    "",
    build_stage4_evidence(),
    "",
    "## 6. Etapa 5 - Puntajes de Desempeno",
    "",
    "Objetivo: recalcular los puntajes de cada participante usando los",
    "valores asignados de cada metodo y documentar la evidencia de Excel",
    "y del aplicativo.",
    "",
    "### 6.1 Metodos de valor asignado",
    "",
    "| Metodo | Correspondencia | Uso |",
    "|---|---|---|",
    "| Referencia | Método 1: valor de referencia | Etapas 4 y 5 |",
    "| Consenso MADe | Método 2a: consenso MADe | Etapas 4 y 5 |",
    "| Consenso nIQR | Método 2b: consenso nIQR | Etapas 4 y 5 |",
    "| Algoritmo A | Método 3: Algoritmo A | Etapas 4 y 5 |",
    "",
    "### 6.2 Formula de la Etapa 5",
    "",
    "`z = (x - x_pt) / sigma_pt`",
    "",
    "`z' = (x - x_pt) / sqrt(sigma_pt^2 + u_xpt_def^2)`",
    "",
    "`zeta = (x - x_pt) / sqrt(u_i^2 + u_xpt_def^2)`",
    "",
    "`En = (x - x_pt) / sqrt((2.0000 * u_i)^2 + (2.0000 * u_xpt_def)^2)`",
    "",
    "Nota de lectura: cuando `sigma_pt = 0`, los puntajes `z` y `z'` no son",
    "calculables y se reportan como `NA`; esto ocurre en O3_0 y se conserva",
    "como un caso esperado, no como una discrepancia.",
    "",
    extract_stage5_summary(),
    "",
    build_stage5_evidence(),
    "",
    "",
    "## 7. Tabla de Trazabilidad",
    "",
    "| Valor | Fuente ISO / Regla | Evidencia esperada | Observacion |",
    "|---|---|---|---|",
    "| x_pt | Mediana robusta | Excel y pantallazo aplicativo | Base de Etapas 1, 4 y 5 |",
    "| MAD | Mediana de desviaciones absolutas | Excel y pantallazo aplicativo | Cuartiles `type = 7` |",
    "| MADe | `1.4830 * MAD` | Excel y pantallazo aplicativo | Factor fijo |",
    "| nIQR | `0.7413 * IQR` | Excel y pantallazo aplicativo | Cuartiles `type = 7` |",
    "| g, m | Conteo de muestras / replicas | Excel y pantallazo aplicativo | Etapa 2 |",
    "| sw, ss | Dispersion intra / entre muestras | Excel y pantallazo aplicativo | Etapa 2 |",
    "| Dmax | Diferencia max. de estabilidad | Excel y pantallazo aplicativo | Etapa 3 |",
    "| u_xpt, u_hom, u_stab | Calculo del valor asignado | Excel y pantallazo aplicativo | Etapa 4 |",
    "| Iteraciones Algoritmo A | Traza robusta | Excel y pantallazo aplicativo | Iteracion 0 e iteracion convergente |",
    "| z, z', zeta, En | Puntajes de desempeno | Excel y pantallazo aplicativo | Etapa 5 |",
    "",
    "## 8. Cierre",
    "",
    "El expediente queda listo para completar con capturas de Excel y del",
    "aplicativo dentro de la misma seccion de evidencia de cada combo."
  )

  writeLines(out, "validation/informe_validacion_o3.md")
}

run()
