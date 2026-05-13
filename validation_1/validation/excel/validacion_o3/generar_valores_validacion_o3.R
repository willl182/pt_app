# ===================================================================
# Generador de validacion Excel O3
# Valores esperados hardcodeados desde la logica de app.R
# ===================================================================

suppressPackageStartupMessages({
  library(openxlsx)
})

find_project_root <- function() {
  cwd <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
  candidates <- c(cwd, normalizePath(file.path(cwd, ".."), winslash = "/", mustWork = FALSE))
  for (candidate in candidates) {
    if (file.exists(file.path(candidate, "app.R")) &&
        file.exists(file.path(candidate, "data", "summary_n13.csv"))) {
      return(candidate)
    }
  }
  stop("No se pudo localizar la raiz del proyecto desde: ", cwd)
}

root_dir <- find_project_root()
setwd(root_dir)

source(file.path("R", "pt_robust_stats.R"))
source(file.path("R", "pt_homogeneity.R"))
source(file.path("R", "pt_scores.R"))

HOMOGENEITY_FILE <- file.path("data", "homogeneity - homogeneity.csv")
STABILITY_FILE <- file.path("data", "stability - stability.csv")
SUMMARY_FILE <- file.path("data", "summary_n13.csv")
PT_DATA_FILE <- file.path("data", "pt_data_n13.csv")

output_dir <- file.path("validation_1", "validation", "excel", "validacion_o3")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

target_combos <- data.frame(
  pollutant = "o3",
  n_lab = 13,
  level = c("0-nmol/mol", "80-nmol/mol", "180-nmol/mol"),
  suffix = c("0", "80", "180"),
  combo_id = c("O3_0", "O3_80", "O3_180"),
  stringsAsFactors = FALSE
)

score_combo_info <- list(
  ref = list(title = "Referencia (1)", label = "1"),
  consensus_ma = list(title = "Consenso MADe (2a)", label = "2a"),
  consensus_niqr = list(title = "Consenso nIQR (2b)", label = "2b"),
  algo = list(title = "Algoritmo A (3)", label = "3"),
  expert = list(title = "Expertos (4)", label = "4")
)

expert_sigma_params <- data.frame(
  pollutant = c("SO2", "CO", "O3", "NO", "NO2"),
  a = c(0.022, 0.024, 0.020, 0.024, 0.028),
  b = c(1.0, 0.100, 1.0, 1.0, 1.4),
  stringsAsFactors = FALSE
)

normalize_pollutant_code <- function(pollutant) {
  code <- toupper(as.character(pollutant))
  code <- chartr("\u2080\u2081\u2082\u2083\u2084\u2085\u2086\u2087\u2088\u2089", "0123456789", code)
  gsub("[^A-Z0-9]", "", code)
}

calculate_expert_sigma_pt <- function(pollutant, x_pt) {
  if (!is.finite(x_pt)) {
    return(NA_real_)
  }
  code <- normalize_pollutant_code(pollutant)
  params <- expert_sigma_params[expert_sigma_params$pollutant == code, , drop = FALSE]
  if (nrow(params) == 0) {
    return(NA_real_)
  }
  params$a[[1]] * x_pt + params$b[[1]]
}

safe_read <- function(path) {
  if (!file.exists(path)) {
    stop("No existe el archivo requerido: ", path)
  }
  read.csv(path, stringsAsFactors = FALSE)
}

wide_data <- function(path, pollutant, level) {
  df <- safe_read(path)
  df <- df[df$pollutant == pollutant & df$level == level, , drop = FALSE]
  if (nrow(df) == 0) {
    stop("Sin datos para ", pollutant, " / ", level, " en ", path)
  }
  wide <- reshape(
    df,
    idvar = "sample_id",
    timevar = "replicate",
    direction = "wide",
    v.names = "value"
  )
  names(wide) <- gsub("^value\\.", "sample_", names(wide))
  sample_cols <- grep("^sample_\\d+$", names(wide), value = TRUE)
  wide <- wide[, c("sample_id", sample_cols), drop = FALSE]
  wide <- wide[order(wide$sample_id), , drop = FALSE]
  rownames(wide) <- NULL
  wide
}

summary_data <- function(pollutant, level) {
  df <- safe_read(SUMMARY_FILE)
  df[df$pollutant == pollutant & df$level == level, , drop = FALSE]
}

participant_data <- function(pollutant, level) {
  df <- summary_data(pollutant, level)
  df <- df[df$participant_id != "ref", , drop = FALSE]
  result <- aggregate(mean_value ~ participant_id, df, mean, na.rm = TRUE)
  sd_value <- aggregate(sd_value ~ participant_id, df, mean, na.rm = TRUE)
  out <- merge(result, sd_value, by = "participant_id", sort = FALSE)
  names(out)[names(out) == "mean_value"] <- "result"
  out$pollutant <- pollutant
  out$level <- level

  if (file.exists(PT_DATA_FILE)) {
    u_df <- safe_read(PT_DATA_FILE)
    keep <- intersect(c("participant_id", "pollutant", "level", "u_i"), names(u_df))
    if (all(c("participant_id", "pollutant", "level", "u_i") %in% keep)) {
      out <- merge(
        out,
        u_df[, keep, drop = FALSE],
        by = c("participant_id", "pollutant", "level"),
        all.x = TRUE,
        sort = FALSE
      )
    }
  }
  if (!"u_i" %in% names(out)) {
    out$u_i <- NA_real_
  }
  out$uncertainty_std <- out$u_i
  out$u_i_check <- out$sd_value / sqrt(3)
  out
}

compute_homogeneity_app <- function(pollutant, level) {
  wide <- wide_data(HOMOGENEITY_FILE, pollutant, level)
  sample_cols <- grep("^sample_\\d+$", names(wide), value = TRUE)
  sample_data <- wide[, sample_cols, drop = FALSE]
  stats <- calculate_homogeneity_stats(as.matrix(sample_data))
  if (!is.null(stats$error)) {
    stop(stats$error)
  }
  g <- nrow(sample_data)
  first_sample <- sample_data$sample_1
  n_iqr <- calculate_niqr(first_sample)
  q1 <- as.numeric(stats::quantile(first_sample, probs = 0.25, na.rm = TRUE, names = FALSE))
  q3 <- as.numeric(stats::quantile(first_sample, probs = 0.75, na.rm = TRUE, names = FALSE))
  iqr_val <- q3 - q1
  u_sigma_pt_niqr <- 1.25 * n_iqr / sqrt(g)
  criterion_made <- calculate_homogeneity_criterion(stats$MADe)
  criterion_exp_made <- calculate_homogeneity_criterion_expanded(stats$MADe, stats$sw, g)
  criterion_niqr <- calculate_homogeneity_criterion(n_iqr)
  criterion_exp_niqr <- calculate_homogeneity_criterion_expanded(n_iqr, stats$sw, g)
  data.frame(
    metric = c(
      "g", "m", "general_mean", "x_pt", "sw", "ss", "sigma_pt",
      "MADe", "q1", "q3", "iqr", "nIQR", "u_xpt", "u_sigma_pt",
      "u_sigma_pt_niqr",
      "criterio_c_MADe", "criterio_expandido_MADe",
      "criterio_c_nIQR", "criterio_expandido_nIQR",
      "resultado_MADe", "resultado_nIQR"
    ),
    app_value = c(
      g, ncol(sample_data), stats$general_mean_homog, stats$x_pt,
      stats$sw, stats$ss, stats$sigma_pt, stats$MADe,
      q1, q3, iqr_val, n_iqr,
      1.25 * stats$sigma_pt / sqrt(g), stats$u_sigma_pt,
      u_sigma_pt_niqr,
      criterion_made, criterion_exp_made, criterion_niqr, criterion_exp_niqr,
      ifelse(stats$ss <= criterion_made, "Cumple", "No cumple"),
      ifelse(stats$ss <= criterion_niqr, "Cumple", "No cumple")
    ),
    stringsAsFactors = FALSE
  )
}

compute_stability_app <- function(pollutant, level, hom) {
  wide <- wide_data(STABILITY_FILE, pollutant, level)
  sample_cols <- grep("^sample_\\d+$", names(wide), value = TRUE)
  sample_data <- wide[, sample_cols, drop = FALSE]
  hom_mean <- as.numeric(hom$app_value[hom$metric == "general_mean"])
  x_pt <- as.numeric(hom$app_value[hom$metric == "x_pt"])
  sigma_pt <- as.numeric(hom$app_value[hom$metric == "sigma_pt"])
  made <- as.numeric(hom$app_value[hom$metric == "MADe"])
  n_iqr <- as.numeric(hom$app_value[hom$metric == "nIQR"])
  stats <- calculate_stability_stats(sample_data, hom_mean, x_pt, sigma_pt)
  if (!is.null(stats$error)) {
    stop(stats$error)
  }
  values <- as.numeric(unlist(sample_data))
  u_stab_mean <- stats::sd(values, na.rm = TRUE) / sqrt(length(values[is.finite(values)]))
  hom_values <- as.numeric(unlist(wide_data(HOMOGENEITY_FILE, pollutant, level)[, sample_cols]))
  u_hom_mean <- stats::sd(hom_values, na.rm = TRUE) / sqrt(length(hom_values[is.finite(hom_values)]))
  diff_hom_stab <- abs(hom_mean - stats$general_mean)
  criterion_made <- calculate_stability_criterion(made)
  criterion_exp_made <- calculate_stability_criterion_expanded(criterion_made, u_hom_mean, u_stab_mean)
  criterion_niqr <- calculate_stability_criterion(n_iqr)
  criterion_exp_niqr <- calculate_stability_criterion_expanded(criterion_niqr, u_hom_mean, u_stab_mean)
  data.frame(
    metric = c(
      "g", "m", "general_mean_stab", "x_pt_stab", "sw_stab", "ss_stab",
      "diff_hom_stab", "u_hom_mean", "u_stab_mean",
      "criterio_simple_MADe", "criterio_expandido_MADe",
      "criterio_simple_nIQR", "criterio_expandido_nIQR",
      "resultado_MADe", "resultado_nIQR"
    ),
    app_value = c(
      nrow(sample_data), ncol(sample_data), stats$general_mean, stats$x_pt,
      stats$sw, stats$ss, diff_hom_stab, u_hom_mean, u_stab_mean,
      criterion_made, criterion_exp_made, criterion_niqr, criterion_exp_niqr,
      ifelse(diff_hom_stab <= criterion_made, "Cumple", "No cumple"),
      ifelse(diff_hom_stab <= criterion_niqr, "Cumple", "No cumple")
    ),
    stringsAsFactors = FALSE
  )
}

method_parameters_app <- function(pollutant, level, hom, stab, k = 2) {
  participants <- participant_data(pollutant, level)
  refs <- summary_data(pollutant, level)
  refs <- refs[refs$participant_id == "ref", , drop = FALSE]
  values <- participants$result
  n_part <- length(values)
  median_val <- stats::median(values, na.rm = TRUE)
  made <- calculate_mad_e(values)
  niqr <- calculate_niqr(values)
  algo <- run_algorithm_a(values = values, ids = participants$participant_id, max_iter = 50, tol = 1e-10)
  u_hom <- as.numeric(hom$app_value[hom$metric == "ss"])
  u_stab <- as.numeric(stab$app_value[stab$metric == "diff_hom_stab"]) / sqrt(3)
  ref_x_pt <- mean(refs$mean_value, na.rm = TRUE)
  ref_u_xpt <- mean(refs$sd_value, na.rm = TRUE)
  ref_sigma_pt <- calculate_expert_sigma_pt(pollutant, ref_x_pt)

  params <- data.frame(
    method_key = c("ref", "consensus_ma", "consensus_niqr", "algo", "expert"),
    method = c(
      "Referencia (1)",
      "Consenso MADe (2a)",
      "Consenso nIQR (2b)",
      "Algoritmo A (3)",
      "Expertos (4)"
    ),
    x_pt = c(ref_x_pt, median_val, median_val, algo$assigned_value, ref_x_pt),
    sigma_pt = c(
      ref_sigma_pt,
      made,
      niqr,
      algo$robust_sd,
      ref_sigma_pt
    ),
    stringsAsFactors = FALSE
  )
  params$u_xpt <- c(
    ref_u_xpt,
    1.25 * made / sqrt(n_part),
    1.25 * niqr / sqrt(n_part),
    1.25 * algo$robust_sd / sqrt(n_part),
    ref_u_xpt
  )
  params$u_hom <- u_hom
  params$u_stab <- u_stab
  params$u_xpt_def <- sqrt(params$u_xpt^2 + u_hom^2 + u_stab^2)
  params$U_xpt <- k * params$u_xpt_def
  params$n_participants <- n_part
  params
}

score_rows_app <- function(pollutant, level, params, k = 2) {
  participants <- participant_data(pollutant, level)
  rows <- list()
  for (i in seq_len(nrow(params))) {
    p <- params[i, , drop = FALSE]
    z_score <- (participants$result - p$x_pt) / p$sigma_pt
    z_prime <- (participants$result - p$x_pt) / sqrt(p$sigma_pt^2 + p$u_xpt_def^2)
    zeta <- (participants$result - p$x_pt) /
      sqrt(participants$uncertainty_std^2 + p$u_xpt_def^2)
    en_score <- (participants$result - p$x_pt) /
      sqrt((k * participants$uncertainty_std)^2 + (k * p$u_xpt_def)^2)
    rows[[length(rows) + 1]] <- data.frame(
      method = p$method,
      participant_id = participants$participant_id,
      result = participants$result,
      u_xi = participants$uncertainty_std,
      z_score = z_score,
      z_score_eval = evaluate_z_score_vec(z_score),
      z_prime_score = z_prime,
      z_prime_score_eval = evaluate_z_score_vec(z_prime),
      zeta_score = zeta,
      zeta_score_eval = evaluate_z_score_vec(zeta),
      En_score = en_score,
      En_score_eval = evaluate_en_score_vec(en_score),
      stringsAsFactors = FALSE
    )
  }
  do.call(rbind, rows)
}

global_summary_app <- function(scores, params) {
  eval_cols <- c(
    z = "z_score_eval",
    z_prime = "z_prime_score_eval",
    zeta = "zeta_score_eval",
    En = "En_score_eval"
  )
  eval_levels <- c("N/A", "Satisfactorio", "Cuestionable", "No satisfactorio")
  assigned_values <- params
  assigned_values$tabla <- "Valores asignados e incertidumbre"
  assigned_values$bloque <- "Parámetros por método"
  rows <- list(
    assigned_values
  )
  for (score_name in names(eval_cols)) {
    col <- eval_cols[[score_name]]
    eval_values <- factor(scores[[col]], levels = eval_levels)
    tab <- as.data.frame.matrix(
      table(scores$method, eval_values),
      stringsAsFactors = FALSE
    )
    tab$method <- rownames(tab)
    tab$score <- score_name
    rownames(tab) <- NULL
    tab <- tab[, c("score", "method", eval_levels), drop = FALSE]
    tab$tabla <- "Resumen global de evaluaciones"
    tab$bloque <- "Conteos por método y categoría"
    rows[[length(rows) + 1]] <- tab
  }
  do.call(rbind.fill.local, rows)
}

rbind.fill.local <- function(...) {
  dfs <- list(...)
  cols <- unique(unlist(lapply(dfs, names)))
  dfs <- lapply(dfs, function(df) {
    missing <- setdiff(cols, names(df))
    for (col in missing) df[[col]] <- NA
    df[, cols, drop = FALSE]
  })
  do.call(rbind, dfs)
}

fmt4 <- function(x) {
  sprintf("%.4f", as.numeric(x))
}

tag_section <- function(data, combo, section) {
  data.frame(
    combo_id = combo$combo_id,
    pollutant = combo$pollutant,
    n_lab = combo$n_lab,
    level = combo$level,
    section = section,
    data,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

study_summary_tables <- function(hom) {
  data.frame(
    tabla = c(
      rep("Resumen del Estudio (Método MADe)", 6),
      rep("Resumen del Estudio (Método nIQR)", 8)
    ),
    parametro = c(
      "Muestras (g)",
      "Réplicas (m)",
      "x_pt (hom_stab)",
      "Median |sample_2 - x_pt|",
      "MADe (1.483 × median)",
      "u_sigma_pt",
      "Muestras (g)",
      "Réplicas (m)",
      "x_pt (hom_stab)",
      "Q1 (25%)",
      "Q3 (75%)",
      "IQR (Q3 - Q1)",
      "nIQR (0.7413 × IQR)",
      "u_sigma_pt (nIQR)"
    ),
    app_value = c(
      hom$app_value[hom$metric == "g"],
      hom$app_value[hom$metric == "m"],
      fmt4(hom$app_value[hom$metric == "x_pt"]),
      fmt4(hom$app_value[hom$metric == "sigma_pt"]),
      fmt4(hom$app_value[hom$metric == "MADe"]),
      fmt4(hom$app_value[hom$metric == "u_sigma_pt"]),
      hom$app_value[hom$metric == "g"],
      hom$app_value[hom$metric == "m"],
      fmt4(hom$app_value[hom$metric == "x_pt"]),
      fmt4(hom$app_value[hom$metric == "q1"]),
      fmt4(hom$app_value[hom$metric == "q3"]),
      fmt4(hom$app_value[hom$metric == "iqr"]),
      fmt4(hom$app_value[hom$metric == "nIQR"]),
      fmt4(hom$app_value[hom$metric == "u_sigma_pt_niqr"])
    ),
    stringsAsFactors = FALSE
  )
}

algo_stabilization_iter <- function(algo_detail) {
  if (is.null(algo_detail$iterations) || nrow(algo_detail$iterations) == 0) {
    return(NA_integer_)
  }
  if ("signif3_converged" %in% names(algo_detail$iterations)) {
    hit <- which(algo_detail$iterations$signif3_converged)
  } else {
    hit <- which(algo_detail$iterations$delta_max < algo_detail$tolerance)
  }
  if (length(hit) > 0) hit[[1]] else NA_integer_
}

algorithm_a_table <- function(params, combo) {
  algo <- params[params$method_key == "algo", , drop = FALSE]
  if (nrow(algo) == 0 || combo$suffix == "0") {
    return(data.frame(
      bloque = "Algoritmo A",
      parametro = c(
        "Analito",
        "Esquema (n)",
        "Nivel",
        "n participantes",
        "x*0 = mediana",
        "s*0 = MADe",
        "x* (valor asignado)",
        "s* (desviación robusta)",
        "Observaciones winzorizadas",
        "Observaciones totales",
        "n_iteraciones",
        "criterio",
        "guardia_numérica",
        "primera_iteración_3ra_cifra"
      ),
      app_value = c(rep(0, 14)),
      stringsAsFactors = FALSE
    ))
  }

  participants <- participant_data(combo$pollutant, combo$level)
  algo_detail <- run_algorithm_a(
    values = participants$result,
    ids = participants$participant_id,
    max_iter = 50,
    tol = 1e-10
  )
  n_iteraciones <- if (!is.null(algo_detail$iterations)) {
    nrow(algo_detail$iterations)
  } else {
    NA_integer_
  }
  stabilization_iter <- algo_stabilization_iter(algo_detail)

  data.frame(
    bloque = "Algoritmo A",
    parametro = c(
      "Analito",
      "Esquema (n)",
      "Nivel",
      "n participantes",
      "x*0 = mediana",
      "s*0 = MADe",
      "x* (valor asignado)",
      "s* (desviación robusta)",
      "Observaciones winzorizadas",
      "Observaciones totales",
      "n_iteraciones",
      "criterio",
      "guardia_numérica",
      "primera_iteración_3ra_cifra"
    ),
    app_value = c(
      toupper(combo$pollutant),
      combo$n_lab,
      combo$level,
      algo_detail$n,
      fmt4(algo_detail$initial_median),
      fmt4(algo_detail$initial_mad_e),
      fmt4(algo_detail$assigned_value),
      fmt4(algo_detail$robust_sd),
      algo_detail$n_winsorized,
      algo_detail$n,
      n_iteraciones,
      "3 cifras significativas",
      format(algo_detail$tolerance, scientific = FALSE),
      stabilization_iter
    ),
    stringsAsFactors = FALSE
  )
}

validation_rows <- function(combo) {
  hom <- compute_homogeneity_app(combo$pollutant, combo$level)
  stab <- compute_stability_app(combo$pollutant, combo$level, hom)
  params <- method_parameters_app(combo$pollutant, combo$level, hom, stab)
  scores <- score_rows_app(combo$pollutant, combo$level, params)
  global <- global_summary_app(scores, params)

  rbind.fill.local(
    tag_section(study_summary_tables(hom), combo, "resultado_homogeneidad"),
    tag_section(study_summary_tables(hom), combo, "resultado_estabilidad"),
    tag_section(params, combo, "valor_asignado"),
    tag_section(algorithm_a_table(params, combo), combo, "algoritmo_A"),
    tag_section(scores, combo, "puntajes_EA"),
    tag_section(global, combo, "informe_global")
  )
}

rows <- lapply(seq_len(nrow(target_combos)), function(i) {
  validation_rows(target_combos[i, ])
})
validation_values <- do.call(rbind.fill.local, rows)

out_path <- file.path(output_dir, "valores_validacion_o3.csv")
write.csv(validation_values, out_path, row.names = FALSE, na = "")
message("Wrote ", out_path)
