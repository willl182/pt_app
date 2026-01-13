# ===================================================================
# Titulo: crea_reporte.R
# Entregable: 04 - Modulo de Calculo de Puntajes
# Descripcion: Carga summary_n4.csv, calcula puntajes y genera
#              reporte en HTML y Word mediante rmarkdown.
# Entrada: data/summary_n4.csv
# Salida: reporte_puntajes.html y reporte_puntajes.docx
# Autor: [PT App Team]
# Fecha: 2026-01-11
# Referencia: ISO 13528:2022 §10.2-10.5
# ===================================================================

# -------------------------------------------------------------------
# Funciones locales (sin dependencias externas)
# -------------------------------------------------------------------

calculate_z_score <- function(x, x_pt, sigma_pt) {
  if (!is.finite(sigma_pt) || sigma_pt <= 0) {
    return(rep(NA_real_, length(x)))
  }
  (x - x_pt) / sigma_pt
}

calculate_z_prime_score <- function(x, x_pt, sigma_pt, u_xpt) {
  denominador <- sqrt(sigma_pt^2 + u_xpt^2)
  if (!is.finite(denominador) || denominador <= 0) {
    return(rep(NA_real_, length(x)))
  }
  (x - x_pt) / denominador
}

calculate_zeta_score <- function(x, x_pt, u_x, u_xpt) {
  denominador <- sqrt(u_x^2 + u_xpt^2)
  if (!is.finite(denominador) || denominador <= 0) {
    return(rep(NA_real_, length(x)))
  }
  (x - x_pt) / denominador
}

calculate_en_score <- function(x, x_pt, U_x, U_xpt) {
  denominador <- sqrt(U_x^2 + U_xpt^2)
  if (!is.finite(denominador) || denominador <= 0) {
    return(rep(NA_real_, length(x)))
  }
  (x - x_pt) / denominador
}

evaluate_z_score <- function(z) {
  ifelse(
    !is.finite(z),
    "N/A",
    ifelse(
      abs(z) <= 2,
      "Satisfactorio",
      ifelse(abs(z) < 3, "Cuestionable", "No satisfactorio")
    )
  )
}

evaluate_en_score <- function(en) {
  ifelse(
    !is.finite(en),
    "N/A",
    ifelse(abs(en) <= 1, "Satisfactorio", "No satisfactorio")
  )
}

calculate_scores_table <- function(summary_df, m = NULL, k = 2) {
  columnas_requeridas <- c(
    "pollutant", "level", "participant_id", "sample_group",
    "mean_value", "sd_value"
  )
  columnas_faltantes <- setdiff(columnas_requeridas, names(summary_df))
  if (length(columnas_faltantes) > 0) {
    stop(
      sprintf("Faltan columnas requeridas: %s", paste(columnas_faltantes, collapse = ", "))
    )
  }

  grupos <- split(summary_df, list(summary_df$pollutant, summary_df$level), drop = TRUE)

  resultados <- lapply(grupos, function(datos_grupo) {
    valores <- datos_grupo$mean_value
    valores <- valores[is.finite(valores)]

    ref_data <- datos_grupo[datos_grupo$participant_id == "ref", , drop = FALSE]
    if (nrow(ref_data) == 0) {
      x_pt <- NA_real_
    } else {
      x_pt <- mean(ref_data$mean_value, na.rm = TRUE)
    }

    mediana_val <- median(valores, na.rm = TRUE)
    sigma_pt <- 1.483 * median(abs(valores - mediana_val), na.rm = TRUE)

    n_valores <- length(valores)
    if (!is.finite(sigma_pt) || n_valores == 0) {
      u_xpt <- NA_real_
    } else {
      u_xpt <- 1.25 * sigma_pt / sqrt(n_valores)
    }

    m_local <- if (is.null(m)) length(unique(datos_grupo$sample_group)) else m
    u_x <- datos_grupo$sd_value / sqrt(m_local)
    U_x <- k * u_x
    U_xpt <- k * u_xpt

    z_score <- calculate_z_score(datos_grupo$mean_value, x_pt, sigma_pt)
    z_prime_score <- calculate_z_prime_score(datos_grupo$mean_value, x_pt, sigma_pt, u_xpt)
    zeta_score <- calculate_zeta_score(datos_grupo$mean_value, x_pt, u_x, u_xpt)
    en_score <- calculate_en_score(datos_grupo$mean_value, x_pt, U_x, U_xpt)

    data.frame(
      datos_grupo,
      x_pt = x_pt,
      sigma_pt = sigma_pt,
      u_xpt = u_xpt,
      u_x = u_x,
      U_x = U_x,
      U_xpt = U_xpt,
      z_score = z_score,
      z_eval = evaluate_z_score(z_score),
      z_prime_score = z_prime_score,
      z_prime_eval = evaluate_z_score(z_prime_score),
      zeta_score = zeta_score,
      zeta_eval = evaluate_z_score(zeta_score),
      En_score = en_score,
      En_eval = evaluate_en_score(en_score),
      stringsAsFactors = FALSE
    )
  })

  tabla_final <- do.call(rbind, resultados)
  rownames(tabla_final) <- NULL
  tabla_final
}

# -------------------------------------------------------------------
# Preparar datos y generar reporte
# -------------------------------------------------------------------

ruta_script <- sys.frame(1)$ofile
if (is.null(ruta_script)) {
  ruta_script <- "crea_reporte.R"
}

ruta_script <- normalizePath(ruta_script, mustWork = FALSE)
carpeta_r <- dirname(ruta_script)
carpeta_entregable <- dirname(carpeta_r)
base_dir <- dirname(dirname(carpeta_entregable))

ruta_summary <- file.path(base_dir, "data", "summary_n4.csv")
if (!file.exists(ruta_summary)) {
  stop("No se encontro el archivo summary_n4.csv en data/.")
}

summary_df <- read.csv(ruta_summary, stringsAsFactors = FALSE)

scores_df <- calculate_scores_table(summary_df)

resumen_z <- as.data.frame(table(scores_df$z_eval), stringsAsFactors = FALSE)
colnames(resumen_z) <- c("evaluacion", "conteo")

resumen_en <- as.data.frame(table(scores_df$En_eval), stringsAsFactors = FALSE)
colnames(resumen_en) <- c("evaluacion", "conteo")

if (!requireNamespace("rmarkdown", quietly = TRUE)) {
  stop("El paquete rmarkdown es necesario para generar el reporte.")
}

ruta_rmd <- tempfile(fileext = ".Rmd")

contenido_rmd <- c(
  "---",
  "title: \"Reporte de Puntajes de Desempeño\"",
  "output:",
  "  html_document:",
  "    number_sections: true",
  "  word_document:",
  "    toc: true",
  "params:",
  "  scores: NULL",
  "  resumen_z: NULL",
  "  resumen_en: NULL",
  "  fecha: NULL",
  "---",
  "",
  "# Introduccion",
  "Este reporte resume los puntajes de desempeño calculados segun ISO 13528:2022",
  "(secciones 10.2 a 10.5). Se incluyen z, z', zeta y En, junto con los",
  "criterios de evaluacion acordes al esquema PT.",
  "",
  "# Resumen de evaluaciones",
  "",
  "## Evaluaciones para z, z' y zeta",
  "```{r}",
  "knitr::kable(params$resumen_z)",
  "```",
  "",
  "## Evaluaciones para En",
  "```{r}",
  "knitr::kable(params$resumen_en)",
  "```",
  "",
  "# Tabla de puntajes (primeras 15 filas)",
  "```{r}",
  "knitr::kable(utils::head(params$scores, 15))",
  "```",
  "",
  "# Formulas usadas",
  "- z = (x - x_pt) / sigma_pt",
  "- z' = (x - x_pt) / sqrt(sigma_pt^2 + u_xpt^2)",
  "- zeta = (x - x_pt) / sqrt(u_x^2 + u_xpt^2)",
  "- En = (x - x_pt) / sqrt(U_x^2 + U_xpt^2)",
  "",
  "# Criterios de evaluacion",
  "- |z|, |z'| y |zeta| <= 2: Satisfactorio",
  "- 2 < |z|, |z'| y |zeta| < 3: Cuestionable",
  "- |z|, |z'| y |zeta| >= 3: No satisfactorio",
  "- |En| <= 1: Satisfactorio",
  "- |En| > 1: No satisfactorio"
)

writeLines(contenido_rmd, ruta_rmd)

ruta_html <- file.path(carpeta_entregable, "reporte_puntajes.html")
ruta_docx <- file.path(carpeta_entregable, "reporte_puntajes.docx")

rmarkdown::render(
  input = ruta_rmd,
  output_format = "html_document",
  output_file = "reporte_puntajes.html",
  output_dir = carpeta_entregable,
  params = list(
    scores = scores_df,
    resumen_z = resumen_z,
    resumen_en = resumen_en,
    fecha = Sys.Date()
  ),
  envir = new.env(parent = globalenv()),
  quiet = TRUE
)

rmarkdown::render(
  input = ruta_rmd,
  output_format = "word_document",
  output_file = "reporte_puntajes.docx",
  output_dir = carpeta_entregable,
  params = list(
    scores = scores_df,
    resumen_z = resumen_z,
    resumen_en = resumen_en,
    fecha = Sys.Date()
  ),
  envir = new.env(parent = globalenv()),
  quiet = TRUE
)

message("Reportes generados en: ", carpeta_entregable)
