# ===================================================================
# Statistical tables for PT round data
#
# Produces the analysis blocks defined in plan_analisis.md. Stable
# levels are analyzed both with and without Hampel outliers.
# ===================================================================

if (!exists("pt_qc", inherits = TRUE)) {
  script_path <- if (file.exists(file.path("scripts", "02_qc.R"))) {
    file.path("scripts", "02_qc.R")
  } else {
    file.path("data_use_cases", "scripts", "02_qc.R")
  }
  source(script_path)
}

safe_mean <- function(x) {
  if (any(is.finite(x))) mean(x, na.rm = TRUE) else NA_real_
}

safe_sd <- function(x) {
  if (sum(is.finite(x)) >= 2L) stats::sd(x, na.rm = TRUE) else NA_real_
}

mean_ci <- function(x, conf_level = 0.95) {
  x <- x[is.finite(x)]
  n <- length(x)
  estimate <- safe_mean(x)
  if (n < 2L) {
    return(c(valor = estimate, ic_inf = NA_real_, ic_sup = NA_real_))
  }
  error <- stats::qt((1 + conf_level) / 2, df = n - 1L) *
    stats::sd(x) / sqrt(n)
  c(valor = estimate, ic_inf = estimate - error, ic_sup = estimate + error)
}

slope_ci <- function(value, runtime_min, conf_level = 0.95) {
  keep <- is.finite(value) & is.finite(runtime_min)
  if (sum(keep) < 3L || length(unique(runtime_min[keep])) < 2L) {
    return(c(pendiente = NA_real_, ic_inf = NA_real_, ic_sup = NA_real_))
  }
  fit <- stats::lm(value[keep] ~ runtime_min[keep])
  interval <- stats::confint(fit, level = conf_level)[2L, ]
  c(
    pendiente = unname(stats::coef(fit)[2L]),
    ic_inf = unname(interval[1L]),
    ic_sup = unname(interval[2L])
  )
}

levene_test <- function(x, group) {
  keep <- is.finite(x) & !is.na(group)
  x <- x[keep]
  group <- droplevels(factor(group[keep]))
  if (length(levels(group)) != 2L || any(table(group) < 2L)) {
    return(c(F = NA_real_, p = NA_real_))
  }
  centers <- tapply(x, group, stats::median, na.rm = TRUE)
  deviations <- abs(x - centers[group])
  fit <- stats::lm(deviations ~ group)
  result <- stats::anova(fit)
  c(F = result$`F value`[1L], p = result$`Pr(>F)`[1L])
}

make_variants <- function(data) {
  with_outliers <- data
  with_outliers$variante <- "con_outliers"
  without_outliers <- data[!data$flag_outlier, , drop = FALSE]
  without_outliers$variante <- "sin_outliers"
  rbind(with_outliers, without_outliers)
}

summarize_a <- function(data) {
  role_summary <- data |>
    dplyr::group_by(
      variante, ronda, analito, unidad, level_num, nominal, rol
    ) |>
    dplyr::group_modify(function(.x, .y) {
      drift <- slope_ci(.x$valor, .x$runtime_min)
      average <- safe_mean(.x$valor)
      deviation <- safe_sd(.x$valor)
      data.frame(
        n = sum(is.finite(.x$valor)),
        media = average,
        sd = deviation,
        cv_pct = if (is.finite(average) && average != 0) {
          100 * deviation / abs(average)
        } else {
          NA_real_
        },
        sesgo_abs = average - .y$nominal,
        sesgo_rel_pct = if (.y$nominal != 0) {
          100 * (average - .y$nominal) / .y$nominal
        } else {
          NA_real_
        },
        pendiente_unidad_min = drift["pendiente"],
        pendiente_ic_inf = drift["ic_inf"],
        pendiente_ic_sup = drift["ic_sup"]
      )
    }) |>
    dplyr::ungroup()

  paired <- data |>
    dplyr::select(
      variante, source_file, source_row, ronda, analito, unidad,
      level_num, rol, valor
    ) |>
    tidyr::pivot_wider(names_from = rol, values_from = valor) |>
    dplyr::mutate(diferencia = ref - part) |>
    dplyr::group_by(variante, ronda, analito, unidad, level_num) |>
    dplyr::summarise(
      n_pares = sum(is.finite(diferencia)),
      diferencia_ref_part = safe_mean(diferencia),
      diferencia_sd = safe_sd(diferencia),
      loa_inf = diferencia_ref_part - 1.96 * diferencia_sd,
      loa_sup = diferencia_ref_part + 1.96 * diferencia_sd,
      .groups = "drop"
    )

  dplyr::left_join(
    role_summary,
    paired,
    by = c("variante", "ronda", "analito", "unidad", "level_num")
  ) |>
    dplyr::rename(nivel = level_num)
}

summarize_zeros <- function(data, unit) {
  data |>
    dplyr::filter(unidad == unit, level_num == 1L) |>
    dplyr::group_by(variante, ronda, analito, rol) |>
    dplyr::group_modify(function(.x, .y) {
      drift <- slope_ci(.x$valor, .x$runtime_min)
      flags <- ""
      if (.y$ronda == "R2C" && .y$analito == "no2") {
        flags <- "Cero truncado por gap temporal; n reducido"
      }
      data.frame(
        n = sum(is.finite(.x$valor)),
        media_cero = safe_mean(.x$valor),
        sd_cero = safe_sd(.x$valor),
        min = if (any(is.finite(.x$valor))) min(.x$valor, na.rm = TRUE) else NA,
        max = if (any(is.finite(.x$valor))) max(.x$valor, na.rm = TRUE) else NA,
        drift_unidad_h = 60 * drift["pendiente"],
        drift_ic_inf = 60 * drift["ic_inf"],
        drift_ic_sup = 60 * drift["ic_sup"],
        flags = flags
      )
    }) |>
    dplyr::ungroup()
}

series_data <- function(data, series) {
  definitions <- list(
    ref_R2 = list(rounds = c("R2A", "R2B", "R2C"), role = "ref"),
    P1 = list(rounds = c("R2A", "R2B", "R2C"), role = "part"),
    ref_R3 = list(rounds = "R3", role = "ref"),
    P2 = list(rounds = "R3", role = "part")
  )
  definition <- definitions[[series]]
  result <- data[
    data$ronda %in% definition$rounds & data$rol == definition$role,
    , drop = FALSE
  ]
  result$serie <- series
  result
}

inter_comparison <- function(data, pair_id, left_name, right_name,
                             descriptive = FALSE) {
  left <- series_data(data, left_name)
  right <- series_data(data, right_name)
  levels <- unique(rbind(
    left[, c("variante", "analito", "level_num")],
    right[, c("variante", "analito", "level_num")]
  ))
  levels <- levels[!(levels$analito == "no2" & levels$level_num == 3L), ]

  rows <- lapply(seq_len(nrow(levels)), function(i) {
    key <- levels[i, ]
    left_group <- left[
      left$variante == key$variante & left$analito == key$analito &
        left$level_num == key$level_num,
      , drop = FALSE
    ]
    right_group <- right[
      right$variante == key$variante & right$analito == key$analito &
        right$level_num == key$level_num,
      , drop = FALSE
    ]
    scale <- if (key$level_num == 1L) "absoluto" else "err_rel"
    variable <- if (scale == "absoluto") "valor" else "err_rel"
    left_values <- left_group[[variable]]
    right_values <- right_group[[variable]]
    difference <- if (pair_id == "C1") {
      mean_ci(right_values)["valor"] - mean_ci(left_values)["valor"]
    } else {
      mean_ci(left_values)["valor"] - mean_ci(right_values)["valor"]
    }
    standard_error <- sqrt(
      safe_sd(left_values)^2 / sum(is.finite(left_values)) +
        safe_sd(right_values)^2 / sum(is.finite(right_values))
    )
    degrees <- sum(is.finite(left_values)) + sum(is.finite(right_values)) - 2L
    margin <- if (is.finite(standard_error) && degrees > 0L) {
      stats::qt(0.975, degrees) * standard_error
    } else {
      NA_real_
    }
    base <- data.frame(
      variante = key$variante,
      par = pair_id,
      clase = "inter",
      analito = key$analito,
      nivel = key$level_num,
      escala = scale,
      descriptivo = descriptive,
      stringsAsFactors = FALSE
    )
    estimates <- rbind(
      transform(base, estadistico = "diferencia_medias",
                valor = difference, ic_inf = difference - margin,
                ic_sup = difference + margin),
      transform(base, estadistico = paste0("media_", left_name),
                valor = safe_mean(left_values), ic_inf = NA_real_,
                ic_sup = NA_real_),
      transform(base, estadistico = paste0("media_", right_name),
                valor = safe_mean(right_values), ic_inf = NA_real_,
                ic_sup = NA_real_)
    )
    if (pair_id == "C1") {
      test <- levene_test(
        c(left_values, right_values),
        c(rep(left_name, length(left_values)),
          rep(right_name, length(right_values)))
      )
      estimates <- rbind(
        estimates,
        transform(base, estadistico = "levene_F", valor = test["F"],
                  ic_inf = NA_real_, ic_sup = NA_real_),
        transform(base, estadistico = "levene_p", valor = test["p"],
                  ic_inf = NA_real_, ic_sup = NA_real_)
      )
    }
    estimates
  })
  do.call(rbind, rows)
}

intra_comparison <- function(data, pair_id, rounds, participant_name) {
  selected <- data[data$ronda %in% rounds, , drop = FALSE]
  paired <- selected |>
    dplyr::select(
      variante, source_file, source_row, analito, level_num, rol, valor
    ) |>
    tidyr::pivot_wider(names_from = rol, values_from = valor) |>
    dplyr::mutate(diferencia = ref - part) |>
    dplyr::filter(!(analito == "no2" & level_num == 3L))

  paired |>
    dplyr::group_by(variante, analito, level_num) |>
    dplyr::group_modify(function(.x, .y) {
      interval <- mean_ci(.x$diferencia)
      deviation <- safe_sd(.x$diferencia)
      data.frame(
        par = pair_id,
        clase = "intra",
        nivel = .y$level_num,
        escala = "concentracion",
        descriptivo = FALSE,
        estadistico = c(
          "diferencia_pareada", "sd_diferencia", "loa_inf", "loa_sup",
          "correlacion"
        ),
        valor = c(
          interval["valor"], deviation,
          interval["valor"] - 1.96 * deviation,
          interval["valor"] + 1.96 * deviation,
          if (sum(stats::complete.cases(.x$ref, .x$part)) >= 3L) {
            stats::cor(.x$ref, .x$part, use = "complete.obs")
          } else {
            NA_real_
          }
        ),
        ic_inf = c(interval["ic_inf"], rep(NA_real_, 4L)),
        ic_sup = c(interval["ic_sup"], rep(NA_real_, 4L))
      )
    }) |>
    dplyr::ungroup() |>
    dplyr::mutate(participante = participant_name) |>
    dplyr::select(
      variante, par, clase, analito, nivel, escala, descriptivo,
      estadistico, valor, ic_inf, ic_sup
    )
}

summarize_c <- function(data) {
  dplyr::bind_rows(
    inter_comparison(data, "C1", "ref_R2", "ref_R3"),
    intra_comparison(data, "C2", c("R2A", "R2B", "R2C"), "P1"),
    intra_comparison(data, "C3", "R3", "P2"),
    inter_comparison(data, "C4", "ref_R2", "P2"),
    inter_comparison(data, "C5", "ref_R3", "P1"),
    inter_comparison(data, "C6", "P1", "P2", descriptive = TRUE)
  )
}

summarize_closure <- function(data) {
  series <- dplyr::bind_rows(
    series_data(data, "ref_R2"),
    series_data(data, "P1"),
    series_data(data, "ref_R3"),
    series_data(data, "P2")
  ) |>
    dplyr::filter(!(analito == "no2" & level_num == 3L)) |>
    dplyr::mutate(
      escala = ifelse(level_num == 1L, "absoluto", "err_rel"),
      medida = ifelse(level_num == 1L, valor, 100 * err_rel)
    ) |>
    dplyr::group_by(variante, analito, level_num, escala, serie) |>
    dplyr::summarise(media = safe_mean(medida), .groups = "drop") |>
    tidyr::pivot_wider(names_from = serie, values_from = media)

  series |>
    dplyr::transmute(
      variante,
      analito,
      nivel = level_num,
      escala = ifelse(escala == "absoluto", "ppb", "puntos_porcentuales"),
      C1 = ref_R3 - ref_R2,
      C2 = ref_R2 - P1,
      C3 = ref_R3 - P2,
      c3_menos_c2 = C3 - C2,
      c1_deriva_ref = C1,
      residuo_cierre = c3_menos_c2 - c1_deriva_ref
    )
}

summarize_d <- function(data) {
  data |>
    dplyr::filter(ronda %in% c("R1", "R2A", "R2B", "R2C"), rol == "part") |>
    dplyr::group_by(variante, ronda, analito, unidad, level_num, nominal) |>
    dplyr::group_modify(function(.x, .y) {
      drift <- slope_ci(.x$valor, .x$runtime_min)
      average <- safe_mean(.x$valor)
      data.frame(
        n = sum(is.finite(.x$valor)),
        ruido_cero_sd = if (.y$level_num == 1L) safe_sd(.x$valor) else NA,
        sesgo_rel_pct = if (.y$nominal > 0) {
          100 * (average - .y$nominal) / .y$nominal
        } else {
          NA_real_
        },
        pendiente_unidad_min = drift["pendiente"],
        pendiente_ic_inf = drift["ic_inf"],
        pendiente_ic_sup = drift["ic_sup"]
      )
    }) |>
    dplyr::ungroup() |>
    dplyr::rename(nivel = level_num)
}

summarize_e <- function(data) {
  selected <- data |>
    dplyr::filter(
      source_file %in% c("R3_NO.csv", "R3_NO2.csv"),
      canal %in% c("no", "no2", "nox")
    ) |>
    dplyr::select(
      variante, source_file, source_row, analito, level_num, rol,
      canal, valor
    ) |>
    tidyr::pivot_wider(names_from = canal, values_from = valor) |>
    dplyr::mutate(residuo = no + no2 - nox)

  selected |>
    dplyr::group_by(variante, source_file, analito, level_num, rol) |>
    dplyr::summarise(
      n = sum(is.finite(residuo)),
      media_residuo = safe_mean(residuo),
      sd_residuo = safe_sd(residuo),
      min_residuo = if (any(is.finite(residuo))) min(residuo, na.rm = TRUE) else NA,
      max_residuo = if (any(is.finite(residuo))) max(residuo, na.rm = TRUE) else NA,
      n_flag_abs_mayor_3 = sum(abs(residuo) > 3, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::rename(nivel = level_num)
}

summarize_discards <- function(data) {
  data |>
    dplyr::filter(es_analito) |>
    dplyr::group_by(ronda, analito, unidad, level) |>
    dplyr::summarise(
      filas = dplyr::n_distinct(source_row),
      descartes_transitorio = dplyr::n_distinct(source_row[flag_transient]),
      descartes_na = sum(flag_na & !flag_transient),
      outliers_reportados = sum(flag_outlier & !flag_transient, na.rm = TRUE),
      usados_con_outliers = sum(
        level %in% as.character(1:5) & !flag_transient & !flag_na
      ),
      usados_sin_outliers = sum(
        level %in% as.character(1:5) & !flag_transient & !flag_na &
          !flag_outlier
      ),
      .groups = "drop"
    )
}

write_table <- function(data, file_name, table_dir) {
  utils::write.csv(
    data, file.path(table_dir, file_name), row.names = FALSE, na = ""
  )
}

run_stats <- function() {
  stable <- pt_qc |>
    dplyr::filter(es_analito, level_num %in% 1:5, !flag_transient)
  variants <- make_variants(stable)
  all_variants <- make_variants(
    pt_qc |> dplyr::filter(level_num %in% 1:5, !flag_transient)
  )

  tables <- list(
    A_por_nivel = summarize_a(variants),
    B_ceros_ppb = summarize_zeros(variants, "ppb"),
    B_ceros_ppm = summarize_zeros(variants, "ppm"),
    C_matriz = summarize_c(variants),
    D_participante_p1 = summarize_d(variants),
    E_nox_r3 = summarize_e(all_variants),
    descartes = summarize_discards(pt_qc)
  )
  tables$C_cierre <- summarize_closure(variants)

  table_dir <- file.path(OUTPUT_DIR, "tables")
  dir.create(table_dir, recursive = TRUE, showWarnings = FALSE)
  for (table_name in names(tables)) {
    write_table(tables[[table_name]], paste0(table_name, ".csv"), table_dir)
  }

  assign("pt_stats", tables, envir = .GlobalEnv)
  message("Tablas estadísticas generadas en: ", table_dir)
  invisible(tables)
}

run_stats()
