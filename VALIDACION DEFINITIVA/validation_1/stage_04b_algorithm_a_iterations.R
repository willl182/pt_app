# ===================================================================
# Etapa 4b: Algoritmo A detallado
# Validacion de iteraciones paso a paso del Algoritmo A
#
# Referencia: ISO 13528:2022, Annex C
# Fuente: data/for_validation/summary_n4.csv
# ===================================================================

source("helpers.R")

DATA_SUMMARY <- "../data/for_validation/summary_n4.csv"
OUTPUT_R_CSV <- "outputs/stage_04b_algorithm_a_iterations_r.csv"
OUTPUT_CSV <- "outputs/stage_04b_algorithm_a_iterations.csv"
OUTPUT_REPORT <- "outputs/stage_04b_algorithm_a_iterations_report.md"
TOL_DEFAULT <- 1e-9
MAX_ITER <- 50
TOL_REL <- 0.5
SIGMA_EPS <- .Machine$double.eps

format_num <- function(x) {
  ifelse(is.finite(x), format(x, digits = 17, scientific = TRUE, trim = TRUE), "NA")
}

quantile_type7 <- function(values, prob) {
  stats::quantile(values, probs = prob, type = 7, names = FALSE)
}

run_algorithm_a_trace <- function(values, max_iter = MAX_ITER, tol = TOL_REL) {
  values <- sort(values[is.finite(values)])
  n <- length(values)
  if (n < 4) {
    return(list(error = "Algoritmo A requiere al menos 4 valores"))
  }

  x_median <- stats::median(values)
  x_mad <- stats::median(abs(values - x_median))
  sigma <- 1.483 * x_mad

  trace <- list()
  trace[[1]] <- data.frame(
    iteration = 0,
    step = "initial",
    n = n,
    x_median = x_median,
    x_mad = x_mad,
    sigma = sigma,
    x_w_median = x_median,
    x_w_mad = x_mad,
    sigma_w = sigma,
    max_abs_z = 0,
    converged = FALSE,
    stringsAsFactors = FALSE
  )

  if (sigma < SIGMA_EPS) {
    trace[[2]] <- transform(trace[[1]], converged = TRUE)
    return(list(
      assigned_value = x_median,
      robust_sd = sigma,
      iterations = 0,
      converged = TRUE,
      trace = do.call(rbind, trace),
      winsorized_values = values
    ))
  }

  for (iter in seq_len(max_iter)) {
    z <- (values - x_median) / (1.5 * sigma)
    x_w <- values
    x_w[z < -1] <- x_median - 1.5 * sigma
    x_w[z > 1] <- x_median + 1.5 * sigma

    x_w_median <- stats::median(x_w)
    x_w_mad <- stats::median(abs(x_w - x_w_median))
    sigma_w <- 1.06 * x_w_mad
    max_abs_z <- max(abs(z), na.rm = TRUE)
    converged <- abs(sigma_w - sigma) <= tol * sigma

    trace[[length(trace) + 1]] <- data.frame(
      iteration = iter,
      step = "update",
      n = n,
      x_median = x_median,
      x_mad = x_mad,
      sigma = sigma,
      x_w_median = x_w_median,
      x_w_mad = x_w_mad,
      sigma_w = sigma_w,
      max_abs_z = max_abs_z,
      converged = converged,
      stringsAsFactors = FALSE
    )

    if (converged) {
      return(list(
        assigned_value = x_median,
        robust_sd = sigma_w,
        iterations = iter,
        converged = TRUE,
        trace = do.call(rbind, trace),
        winsorized_values = x_w
      ))
    }

    sigma <- sigma_w
  }

  list(
    assigned_value = x_median,
    robust_sd = sigma,
    iterations = max_iter,
    converged = FALSE,
    trace = do.call(rbind, trace),
    winsorized_values = x_w
  )
}

load_combo_values <- function(filepath, pollutant, level) {
  df <- read.csv(filepath, stringsAsFactors = FALSE)
  df <- df[df$pollutant == pollutant & df$level == level, ]
  df <- df[df$participant_id != "ref", ]
  agg <- aggregate(mean_value ~ participant_id, data = df, FUN = mean, na.rm = TRUE)
  sort(agg$mean_value[is.finite(agg$mean_value)])
}

build_trace_rows <- function(combo, values) {
  algo <- run_algorithm_a_trace(values)
  if (!is.null(algo$error)) {
    return(list(error = algo$error))
  }

  rows <- list()
  trace <- algo$trace
  for (i in seq_len(nrow(trace))) {
    row <- trace[i, ]
    rows[[length(rows) + 1]] <- data.frame(
      combo_id = make_combo_id(combo$pollutant, combo$level),
      pollutant = combo$pollutant,
      level = combo$level,
      stage = "stage_04b_algorithm_a_iterations",
      section = "Algoritmo A",
      iteration = row$iteration,
      step = row$step,
      n = row$n,
      x_median = row$x_median,
      x_mad = row$x_mad,
      sigma = row$sigma,
      x_w_median = row$x_w_median,
      x_w_mad = row$x_w_mad,
      sigma_w = row$sigma_w,
      max_abs_z = row$max_abs_z,
      converged = row$converged,
      assigned_value = algo$assigned_value,
      robust_sd = algo$robust_sd,
      value_count = length(values),
      values = paste(format_num(values), collapse = ";"),
      winsorized_values = paste(format_num(algo$winsorized_values), collapse = ";"),
      stringsAsFactors = FALSE
    )
  }

  rows
}

run_stage_04b <- function() {
  cat("Etapa 4b: Algoritmo A detallado — INICIO\n")
  all_rows <- list()
  combos_processed <- character()

  for (combo in COMBOS) {
    values <- load_combo_values(DATA_SUMMARY, combo$pollutant, combo$level)
    if (length(values) < 4) {
      cat("  ADVERTENCIA:", combo$label, "requiere al menos 4 valores\n")
      next
    }

    trace_rows <- build_trace_rows(combo, values)
    if (length(trace_rows) == 1 && !is.data.frame(trace_rows[[1]])) {
      cat("  ADVERTENCIA:", combo$label, trace_rows[[1]]$error, "\n")
      next
    }

    all_rows <- c(all_rows, trace_rows)
    combos_processed <- c(combos_processed, combo$label)
    cat("  Procesado:", combo$label, "\n")
  }

  if (length(all_rows) == 0) {
    stop("No se generaron filas para la etapa 4b")
  }

  r_df <- do.call(rbind, all_rows)
  write.csv(r_df, OUTPUT_R_CSV, row.names = FALSE)
  cat("  CSV R guardado:", OUTPUT_R_CSV, "\n")

  if (file.exists(OUTPUT_CSV)) {
    file.remove(OUTPUT_CSV)
  }
  write.csv(r_df, OUTPUT_CSV, row.names = FALSE)
  cat("  CSV comparacion guardado:", OUTPUT_CSV, "\n")

  report_lines <- c(
    "# Reporte: Etapa 4b: Algoritmo A detallado",
    "",
    paste0("**Combos procesados**: ", paste(combos_processed, collapse = ", ")),
    paste0("**Filas**: ", nrow(r_df)),
    "",
    "## Resumen",
    paste0("- Iteraciones maximas: ", MAX_ITER),
    paste0("- Tolerancia relativa: ", TOL_REL),
    "",
    "## Conclusion",
    "Etapa completada"
  )
  writeLines(report_lines, OUTPUT_REPORT)
  cat("  Reporte guardado:", OUTPUT_REPORT, "\n")
  cat("Etapa 4b: Algoritmo A detallado — FIN\n")
}

run_stage_04b()
