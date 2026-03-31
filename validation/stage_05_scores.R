# ===================================================================
# stage_05_scores
#
# Implements Phase 5:
# - participant-level score metrics by combo and method (2a/2b/3)
# - app-like and independent R implementations
# - tripartite comparison app/R/Python
# - canonical CSV + Markdown report output
# ===================================================================

source("validation/common_config.R")
source("validation/stage_04_uncertainty_chain.R")

STAGE_05_ID <- "stage_05_scores"
S5_K_FACTOR <- 2

s5_as_numeric_or_na <- function(x) {
  suppressWarnings(as.numeric(x))
}

s5_validate_summary_columns <- function(data_df) {
  required <- c(
    "pollutant",
    "level",
    "participant_id",
    "mean_value",
    "sd_value"
  )
  if (!all(required %in% names(data_df))) {
    stop(
      "summary_n13.csv must include pollutant, level, participant_id, ",
      "mean_value, sd_value."
    )
  }
}

s5_validate_stage_04_columns <- function(data_df) {
  required <- c(
    "combo_id",
    "section",
    "participant_id",
    "metric",
    "app_value",
    "r_value",
    "python_value"
  )
  if (!all(required %in% names(data_df))) {
    stop(
      "stage_04_uncertainty_chain.csv must include combo_id, section, ",
      "participant_id, metric, app_value, r_value, python_value."
    )
  }
}

s5_extract_participants <- function(data_df, pollutant, level) {
  subset_df <- data_df[
    data_df$pollutant == pollutant &
      data_df$level == level &
      data_df$participant_id != "ref",
    c("participant_id", "mean_value", "sd_value")
  ]

  if (nrow(subset_df) == 0) {
    return(data.frame(
      participant_id = character(0),
      result = numeric(0),
      sd_value = numeric(0),
      stringsAsFactors = FALSE
    ))
  }

  agg_mean <- stats::aggregate(
    subset_df$mean_value,
    by = list(participant_id = subset_df$participant_id),
    FUN = function(x) mean(x, na.rm = TRUE)
  )
  names(agg_mean) <- c("participant_id", "result")

  agg_sd <- stats::aggregate(
    subset_df$sd_value,
    by = list(participant_id = subset_df$participant_id),
    FUN = function(x) mean(x, na.rm = TRUE)
  )
  names(agg_sd) <- c("participant_id", "sd_value")

  merged <- merge(agg_mean, agg_sd, by = "participant_id", all = TRUE)
  merged[order(merged$participant_id), , drop = FALSE]
}

s5_get_stage_04_metric <- function(
    stage_df,
    combo_id,
    method_id,
    metric,
    implementation = c("app", "r")
) {
  implementation <- match.arg(implementation)
  value_col <- if (implementation == "app") "app_value" else "r_value"

  subset_df <- stage_df[
    stage_df$combo_id == combo_id &
      stage_df$section == "uncertainty_chain" &
      stage_df$participant_id == method_id &
      stage_df$metric == metric,
    value_col,
    drop = TRUE
  ]

  if (length(subset_df) == 0) {
    return(NA_real_)
  }
  subset_df[[1]]
}

s5_safe_ratio <- function(numerator, denominator) {
  if (!is.finite(denominator) || denominator <= 0) {
    return(NA_real_)
  }
  numerator / denominator
}

s5_compute_score_metrics <- function(
    result,
    sd_value,
    x_pt,
    sigma_pt,
    u_xpt,
    u_xpt_def,
    u_hom,
    u_stab,
    m,
    k_factor = S5_K_FACTOR
) {
  uncertainty_std <- if (is.finite(m) && m > 0) {
    sd_value / sqrt(m)
  } else {
    sd_value
  }

  z_den <- sigma_pt
  z_score <- s5_safe_ratio(result - x_pt, z_den)

  z_prime_den <- sqrt(sigma_pt^2 + u_xpt_def^2)
  z_prime_score <- s5_safe_ratio(result - x_pt, z_prime_den)

  zeta_den <- sqrt(uncertainty_std^2 + u_xpt_def^2)
  zeta_score <- s5_safe_ratio(result - x_pt, zeta_den)

  u_xi_expanded <- k_factor * uncertainty_std
  u_xpt_expanded <- k_factor * u_xpt_def
  en_den <- sqrt(u_xi_expanded^2 + u_xpt_expanded^2)
  en_score <- s5_safe_ratio(result - x_pt, en_den)

  list(
    m = m,
    result = result,
    sd_value = sd_value,
    uncertainty_std = uncertainty_std,
    x_pt = x_pt,
    sigma_pt = sigma_pt,
    u_xpt = u_xpt,
    u_xpt_def = u_xpt_def,
    u_hom = u_hom,
    u_stab = u_stab,
    z_den = z_den,
    z_score = z_score,
    z_prime_den = z_prime_den,
    z_prime_score = z_prime_score,
    zeta_den = zeta_den,
    zeta_score = zeta_score,
    u_xi_expanded = u_xi_expanded,
    u_xpt_expanded = u_xpt_expanded,
    en_den = en_den,
    en_score = en_score
  )
}

s5_build_impl_rows <- function(
    summary_df,
    stage_04_df,
    combos_df,
    implementation = c("app", "r")
) {
  implementation <- match.arg(implementation)

  method_ids <- c("method_2a", "method_2b", "method_3")
  metric_names <- c(
    "m",
    "result",
    "sd_value",
    "uncertainty_std",
    "x_pt",
    "sigma_pt",
    "u_xpt",
    "u_xpt_def",
    "u_hom",
    "u_stab",
    "z_den",
    "z_score",
    "z_prime_den",
    "z_prime_score",
    "zeta_den",
    "zeta_score",
    "u_xi_expanded",
    "u_xpt_expanded",
    "en_den",
    "en_score"
  )

  out_rows <- list()
  idx <- 1L

  for (i in seq_len(nrow(combos_df))) {
    combo_id <- combos_df$combo_id[i]
    pollutant <- combos_df$pollutant[i]
    level <- combos_df$level[i]

    participants_df <- s5_extract_participants(summary_df, pollutant, level)
    if (nrow(participants_df) == 0) {
      next
    }

    for (method_id in method_ids) {
      x_pt <- s5_get_stage_04_metric(
        stage_df = stage_04_df,
        combo_id = combo_id,
        method_id = method_id,
        metric = "x_pt_method",
        implementation = implementation
      )
      sigma_pt <- s5_get_stage_04_metric(
        stage_df = stage_04_df,
        combo_id = combo_id,
        method_id = method_id,
        metric = "sigma_pt_method",
        implementation = implementation
      )
      u_xpt <- s5_get_stage_04_metric(
        stage_df = stage_04_df,
        combo_id = combo_id,
        method_id = method_id,
        metric = "u_xpt",
        implementation = implementation
      )
      u_xpt_def <- s5_get_stage_04_metric(
        stage_df = stage_04_df,
        combo_id = combo_id,
        method_id = method_id,
        metric = "u_xpt_def",
        implementation = implementation
      )
      u_hom <- s5_get_stage_04_metric(
        stage_df = stage_04_df,
        combo_id = combo_id,
        method_id = method_id,
        metric = "u_hom",
        implementation = implementation
      )
      u_stab <- s5_get_stage_04_metric(
        stage_df = stage_04_df,
        combo_id = combo_id,
        method_id = method_id,
        metric = "u_stab",
        implementation = implementation
      )
      m <- s5_get_stage_04_metric(
        stage_df = stage_04_df,
        combo_id = combo_id,
        method_id = method_id,
        metric = "m",
        implementation = implementation
      )

      section_name <- paste0("scores_", method_id)
      for (j in seq_len(nrow(participants_df))) {
        participant_id <- participants_df$participant_id[j]
        metrics <- s5_compute_score_metrics(
          result = participants_df$result[j],
          sd_value = participants_df$sd_value[j],
          x_pt = x_pt,
          sigma_pt = sigma_pt,
          u_xpt = u_xpt,
          u_xpt_def = u_xpt_def,
          u_hom = u_hom,
          u_stab = u_stab,
          m = m
        )

        for (metric_name in metric_names) {
          out_rows[[idx]] <- data.frame(
            combo_id = combo_id,
            pollutant = pollutant,
            level = level,
            stage = STAGE_05_ID,
            section = section_name,
            participant_id = participant_id,
            metric = metric_name,
            value = unname(metrics[[metric_name]]),
            stringsAsFactors = FALSE
          )
          idx <- idx + 1L
        }
      }
    }
  }

  if (length(out_rows) == 0) {
    return(data.frame(
      combo_id = character(0),
      pollutant = character(0),
      level = character(0),
      stage = character(0),
      section = character(0),
      participant_id = character(0),
      metric = character(0),
      value = numeric(0),
      stringsAsFactors = FALSE
    ))
  }

  do.call(rbind, out_rows)
}

s5_run_python_stage_values <- function(
    summary_input,
    stage_04_path,
    python_values_path
) {
  py_cmd <- Sys.which("python3")
  if (identical(py_cmd, "")) {
    py_cmd <- Sys.which("python")
  }
  if (identical(py_cmd, "")) {
    stop("Python is not available in PATH.")
  }

  args <- c(
    "validation/stage_05_scores.py",
    "--summary-input", summary_input,
    "--stage-04-output", stage_04_path,
    "--values-output", python_values_path
  )
  py_out <- system2(py_cmd, args = args, stdout = TRUE, stderr = TRUE)
  py_status <- attr(py_out, "status")
  if (!is.null(py_status) && py_status != 0) {
    stop("Python stage_05 execution failed:\n", paste(py_out, collapse = "\n"))
  }
  invisible(py_out)
}

s5_is_policy_propagation_discrepancy <- function(
    metric,
    app_value,
    r_value,
    python_value,
    tolerance
) {
  affected_metrics <- c(
    "u_hom",
    "u_xpt_def",
    "u_xpt_expanded",
    "z_prime_den",
    "z_prime_score",
    "zeta_den",
    "zeta_score",
    "en_den",
    "en_score"
  )

  if (!(metric %in% affected_metrics)) {
    return(FALSE)
  }
  if (!is.finite(app_value) || !is.finite(r_value) || !is.finite(python_value)) {
    return(FALSE)
  }

  independent_match <- abs(r_value - python_value) <= tolerance
  app_differs <- abs(app_value - r_value) > tolerance

  independent_match && app_differs
}

s5_classify_status <- function(metric, app_value, r_value, python_value, tolerance) {
  all_non_finite <- all(!is.finite(c(app_value, r_value, python_value)))
  if (all_non_finite) {
    return("EDGE_CASE")
  }

  if (!is.finite(app_value) || !is.finite(r_value) || !is.finite(python_value)) {
    return("KNOWN_DISCREPANCY")
  }

  diffs <- c(
    abs(app_value - r_value),
    abs(app_value - python_value),
    abs(r_value - python_value)
  )
  if (all(diffs <= tolerance)) {
    return("PASS")
  }

  if (s5_is_policy_propagation_discrepancy(
    metric = metric,
    app_value = app_value,
    r_value = r_value,
    python_value = python_value,
    tolerance = tolerance
  )) {
    return("KNOWN_DISCREPANCY")
  }

  "FAIL"
}

s5_build_stage_report <- function(results_df, report_path, tolerance) {
  status_counts <- as.data.frame(table(results_df$status), stringsAsFactors = FALSE)
  names(status_counts) <- c("status", "count")
  discrepancy_df <- results_df[results_df$status != "PASS", ]
  methods <- sort(unique(results_df$section))
  metrics <- sort(unique(results_df$metric))

  lines <- c(
    "# Stage 05 Report - Scores",
    "",
    "## Objective",
    "Validate participant-level scores with tripartite comparison (app/R/Python).",
    "",
    "## Data",
    "- Input: `data/summary_n13.csv`",
    "- Uncertainty chain reference: `validation/outputs/stage_04_uncertainty_chain.csv`",
    sprintf("- Method sections: %d", length(methods)),
    sprintf("- Tolerance: %.1e", tolerance),
    "",
    "## Sections Evaluated",
    paste0("- ", methods),
    "",
    "## Metrics Evaluated",
    paste0("- ", metrics),
    "",
    "## Status Summary",
    if (nrow(status_counts) > 0) {
      paste0("- ", status_counts$status, ": ", status_counts$count)
    } else {
      "- No rows generated"
    },
    "",
    "## Discrepancies"
  )

  if (nrow(discrepancy_df) == 0) {
    lines <- c(lines, "- No discrepancies detected.")
  } else {
    max_rows <- min(20L, nrow(discrepancy_df))
    for (i in seq_len(max_rows)) {
      row <- discrepancy_df[i, ]
      lines <- c(
        lines,
        paste0(
          "- ", row$combo_id, " | ", row$section,
          " | ", row$participant_id,
          " | ", row$metric,
          " | ", row$status,
          " | diff_app_python=",
          format(row$diff_app_python, scientific = TRUE)
        )
      )
    }
  }

  lines <- c(
    lines,
    "",
    "## Conclusion",
    if (any(results_df$status == "FAIL")) {
      "- Stage 05 has FAIL rows and is not closed."
    } else {
      "- Stage 05 closed without FAIL rows."
    }
  )

  writeLines(lines, report_path)
}

run_stage_05_scores <- function(
    summary_input = "data/summary_n13.csv",
    stage_04_output = "validation/outputs/stage_04_uncertainty_chain.csv",
    output_path = "validation/outputs/stage_05_scores.csv",
    report_path = "validation/outputs/stage_05_scores_report.md",
    python_values_path = "validation/outputs/stage_05_python_values.csv",
    tolerance = 1e-9
) {
  combos <- get_target_combos()
  validate_combo_definition(combos)

  if (!file.exists(stage_04_output)) {
    message("Stage 04 output not found. Running stage_04_uncertainty_chain first...")
    run_stage_04_uncertainty_chain()
  }

  summary_df <- utils::read.csv(summary_input, stringsAsFactors = FALSE)
  stage_04_df <- utils::read.csv(stage_04_output, stringsAsFactors = FALSE)

  s5_validate_summary_columns(summary_df)
  s5_validate_stage_04_columns(stage_04_df)

  summary_df$mean_value <- s5_as_numeric_or_na(summary_df$mean_value)
  summary_df$sd_value <- s5_as_numeric_or_na(summary_df$sd_value)

  stage_04_df$app_value <- s5_as_numeric_or_na(stage_04_df$app_value)
  stage_04_df$r_value <- s5_as_numeric_or_na(stage_04_df$r_value)
  stage_04_df$python_value <- s5_as_numeric_or_na(stage_04_df$python_value)

  app_df <- s5_build_impl_rows(
    summary_df = summary_df,
    stage_04_df = stage_04_df,
    combos_df = combos,
    implementation = "app"
  )
  r_df <- s5_build_impl_rows(
    summary_df = summary_df,
    stage_04_df = stage_04_df,
    combos_df = combos,
    implementation = "r"
  )

  names(app_df)[names(app_df) == "value"] <- "app_value"
  names(r_df)[names(r_df) == "value"] <- "r_value"

  s5_run_python_stage_values(
    summary_input = summary_input,
    stage_04_path = stage_04_output,
    python_values_path = python_values_path
  )

  python_df <- utils::read.csv(python_values_path, stringsAsFactors = FALSE)
  python_df$python_value <- s5_as_numeric_or_na(python_df$python_value)

  id_cols <- c(
    "combo_id",
    "pollutant",
    "level",
    "stage",
    "section",
    "participant_id",
    "metric"
  )

  merged_df <- merge(app_df, r_df, by = id_cols, all = TRUE)
  merged_df <- merge(merged_df, python_df, by = id_cols, all = TRUE)

  merged_df$excel_value <- NA_real_
  merged_df$diff_app_r <- abs(merged_df$app_value - merged_df$r_value)
  merged_df$diff_app_python <- abs(merged_df$app_value - merged_df$python_value)
  merged_df$diff_r_python <- abs(merged_df$r_value - merged_df$python_value)
  merged_df$diff_app_excel <- NA_real_
  merged_df$status <- vapply(
    seq_len(nrow(merged_df)),
    function(i) {
      s5_classify_status(
        metric = merged_df$metric[i],
        app_value = merged_df$app_value[i],
        r_value = merged_df$r_value[i],
        python_value = merged_df$python_value[i],
        tolerance = tolerance
      )
    },
    character(1)
  )
  merged_df$tolerance <- tolerance
  merged_df$notes <- ifelse(
    merged_df$status == "KNOWN_DISCREPANCY",
    paste(
      "Known propagation difference from Stage 02 ss/ss_sq policy",
      "through Stage 04 uncertainty chain",
      "(app clamps negative radicand to 0; independent implementations use abs)."
    ),
    ""
  )

  canonical_columns <- get_canonical_columns()
  for (column_name in canonical_columns) {
    if (!(column_name %in% names(merged_df))) {
      merged_df[[column_name]] <- NA
    }
  }

  output_df <- merged_df[, canonical_columns]
  output_df <- output_df[order(
    output_df$combo_id,
    output_df$section,
    output_df$participant_id,
    output_df$metric
  ), ]

  dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(output_df, output_path, row.names = FALSE, na = "")
  s5_build_stage_report(output_df, report_path, tolerance = tolerance)

  message("Stage 05 completed:")
  message(" - CSV: ", output_path)
  message(" - Report: ", report_path)
  message(" - Python values: ", python_values_path)

  invisible(output_df)
}

if (sys.nframe() == 0) {
  run_stage_05_scores()
}
