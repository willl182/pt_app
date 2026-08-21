# ===================================================================
# Figures for the PT analysis across rounds R1, R2, and R3
#
# Generates figures P1-P8 from the analysis plan. User-facing labels
# are in Spanish; color is reinforced with shape and line type.
# ===================================================================

find_analysis_root <- function(start = getwd()) {
  current <- normalizePath(start, winslash = "/", mustWork = TRUE)
  repeat {
    direct <- file.path(current, "data_use_cases")
    if (dir.exists(file.path(direct, "data", "raw"))) return(direct)
    if (dir.exists(file.path(current, "data", "raw")) &&
        dir.exists(file.path(current, "scripts"))) return(current)
    parent <- dirname(current)
    if (identical(parent, current)) break
    current <- parent
  }
  stop("No se encontró data_use_cases desde: ", start)
}

ANALYSIS_ROOT <- find_analysis_root()
SCRIPT_DIR <- file.path(ANALYSIS_ROOT, "scripts")
OUTPUT_DIR <- file.path(ANALYSIS_ROOT, "outputs")
FIG_DIR <- file.path(OUTPUT_DIR, "figs")
TABLE_DIR <- file.path(OUTPUT_DIR, "tables")

required_packages <- c("dplyr", "tidyr", "ggplot2")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages) > 0L) {
  stop(
    "Faltan paquetes requeridos: ",
    paste(missing_packages, collapse = ", ")
  )
}

stats_outputs <- c(
  "A_por_nivel.csv", "B_ceros_ppb.csv", "B_ceros_ppm.csv",
  "C_matriz.csv", "C_cierre.csv", "D_participante_p1.csv",
  "E_nox_r3.csv"
)
stats_ready <- all(file.exists(file.path(TABLE_DIR, stats_outputs)))
if (!exists("pt_qc", inherits = TRUE) || !stats_ready) {
  stats_script <- file.path(SCRIPT_DIR, "03_stats.R")
  if (file.exists(stats_script)) {
    source(stats_script)
  } else if (!exists("pt_qc", inherits = TRUE)) {
    source(file.path(SCRIPT_DIR, "02_qc.R"))
  }
}
if (!exists("pt_qc", inherits = TRUE)) {
  source(file.path(SCRIPT_DIR, "02_qc.R"))
}

dir.create(FIG_DIR, recursive = TRUE, showWarnings = FALSE)

ROLE_COLORS <- c(ref = "#0072B2", part = "#D55E00")
ROLE_LABELS <- c(ref = "Referencia CalAire", part = "Participante")
ROLE_TYPES <- c(ref = "solid", part = "longdash")
ROLE_SHAPES <- c(ref = 16, part = 17)
MATRIX_COLORS <- c(
  ref_R2 = "#0072B2", P1 = "#D55E00",
  ref_R3 = "#009E73", P2 = "#CC79A7"
)
MATRIX_TYPES <- c(
  ref_R2 = "solid", P1 = "longdash",
  ref_R3 = "dotdash", P2 = "twodash"
)
MATRIX_SHAPES <- c(ref_R2 = 16, P1 = 17, ref_R3 = 15, P2 = 18)
LEVEL_SHAPES <- c(`1` = 16, `2` = 17, `3` = 15, `4` = 18, `5` = 8)

plot_theme <- function() {
  ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major = ggplot2::element_line(
        colour = "grey88", linewidth = 0.35
      ),
      strip.text = ggplot2::element_text(face = "bold"),
      plot.title = ggplot2::element_text(face = "bold"),
      plot.subtitle = ggplot2::element_text(colour = "grey30"),
      plot.caption = ggplot2::element_text(
        colour = "grey35", hjust = 0, size = 8.5
      ),
      legend.position = "bottom",
      legend.box = "vertical"
    )
}

save_plot <- function(plot, file_name, width = 10, height = 6) {
  ggplot2::ggsave(
    filename = file.path(FIG_DIR, file_name),
    plot = plot,
    width = width,
    height = height,
    units = "in",
    dpi = 300,
    bg = "white"
  )
}

analysis_data <- pt_qc |>
  dplyr::filter(es_analito)

stable_data <- analysis_data |>
  dplyr::filter(level_num %in% 1:5, !flag_transient)

round_title <- function(round_name) {
  dplyr::recode(
    round_name,
    R1 = "Ronda 1", R2A = "Ronda 2A", R2B = "Ronda 2B",
    R2C = "Ronda 2C", R3 = "Ronda 3"
  )
}

analyte_label <- function(analyte) {
  dplyr::recode(analyte, so2 = "SO2", co = "CO", o3 = "O3",
                no = "NO", no2 = "NO2")
}

# P1: complete time series, including transient periods.
series_keys <- analysis_data |>
  dplyr::distinct(source_file, ronda, analito, unidad)

for (i in seq_len(nrow(series_keys))) {
  key <- series_keys[i, ]
  current <- analysis_data |>
    dplyr::filter(source_file == key$source_file)

  spans <- current |>
    dplyr::distinct(source_row, runtime_min, level, nominal) |>
    dplyr::arrange(runtime_min) |>
    dplyr::mutate(
      group = cumsum(level != dplyr::lag(level, default = dplyr::first(level)))
    ) |>
    dplyr::group_by(group, level) |>
    dplyr::summarise(
      xmin = min(runtime_min, na.rm = TRUE),
      xmax = max(runtime_min, na.rm = TRUE),
      nominal = stats::median(nominal, na.rm = TRUE),
      .groups = "drop"
    )

  transients <- spans |>
    dplyr::filter(level == "estab")
  nominals <- spans |>
    dplyr::filter(level %in% as.character(1:5), is.finite(nominal))

  plot <- ggplot2::ggplot(current, ggplot2::aes(x = runtime_min, y = valor)) +
    ggplot2::geom_rect(
      data = transients,
      ggplot2::aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf),
      inherit.aes = FALSE,
      fill = "grey75",
      alpha = 0.35
    ) +
    ggplot2::geom_segment(
      data = nominals,
      ggplot2::aes(x = xmin, xend = xmax, y = nominal, yend = nominal),
      inherit.aes = FALSE,
      colour = "grey25",
      linewidth = 0.45,
      linetype = "dotted"
    ) +
    ggplot2::geom_line(
      ggplot2::aes(colour = rol, linetype = rol),
      linewidth = 0.65,
      na.rm = TRUE
    ) +
    ggplot2::scale_colour_manual(
      values = ROLE_COLORS, labels = ROLE_LABELS, name = "Rol"
    ) +
    ggplot2::scale_linetype_manual(
      values = ROLE_TYPES, labels = ROLE_LABELS, name = "Rol"
    ) +
    ggplot2::labs(
      title = paste(
        "Serie temporal —", round_title(key$ronda),
        analyte_label(key$analito)
      ),
      subtitle = "Las zonas grises indican estabilización; la línea punteada, el nominal.",
      x = "Tiempo de ejecución (min)",
      y = paste("Valor (", key$unidad, ")", sep = "")
    ) +
    plot_theme()

  save_plot(
    plot,
    sprintf("P1_serie_%s_%s.png", key$ronda, key$analito),
    width = 11,
    height = 5.8
  )
}

# P2: stable-level detail with mean and +/- two standard deviations.
for (i in seq_len(nrow(series_keys))) {
  key <- series_keys[i, ]
  current <- stable_data |>
    dplyr::filter(source_file == key$source_file) |>
    dplyr::mutate(level = factor(level, levels = as.character(1:5)))

  summary_lines <- current |>
    dplyr::group_by(level, rol) |>
    dplyr::summarise(
      mean_value = mean(valor, na.rm = TRUE),
      sd_value = stats::sd(valor, na.rm = TRUE),
      .groups = "drop"
    ) |>
    tidyr::pivot_longer(
      cols = c(mean_value, sd_value),
      names_to = "statistic",
      values_to = "value"
    )
  means <- summary_lines |>
    dplyr::filter(statistic == "mean_value")
  limits <- summary_lines |>
    dplyr::filter(statistic == "sd_value") |>
    dplyr::left_join(
      means |>
        dplyr::select(level, rol, mean_value = value),
      by = c("level", "rol")
    ) |>
    dplyr::mutate(lower = mean_value - 2 * value,
                  upper = mean_value + 2 * value)

  plot <- ggplot2::ggplot(
    current,
    ggplot2::aes(x = runtime_min, y = valor, colour = rol)
  ) +
    ggplot2::geom_line(ggplot2::aes(linetype = rol), linewidth = 0.55) +
    ggplot2::geom_hline(
      data = means,
      ggplot2::aes(yintercept = value, colour = rol),
      linewidth = 0.65
    ) +
    ggplot2::geom_hline(
      data = limits,
      ggplot2::aes(yintercept = lower, colour = rol),
      linewidth = 0.4,
      linetype = "dotted"
    ) +
    ggplot2::geom_hline(
      data = limits,
      ggplot2::aes(yintercept = upper, colour = rol),
      linewidth = 0.4,
      linetype = "dotted"
    ) +
    ggplot2::facet_wrap(~level, scales = "free_y") +
    ggplot2::scale_colour_manual(
      values = ROLE_COLORS, labels = ROLE_LABELS, name = "Rol"
    ) +
    ggplot2::scale_linetype_manual(
      values = ROLE_TYPES, labels = ROLE_LABELS, name = "Rol"
    ) +
    ggplot2::labs(
      title = paste(
        "Detalle por nivel —", round_title(key$ronda),
        analyte_label(key$analito)
      ),
      subtitle = "Línea continua: media; líneas punteadas: media ± 2 DE.",
      x = "Tiempo de ejecución (min)",
      y = paste("Valor (", key$unidad, ")", sep = "")
    ) +
    plot_theme()

  save_plot(
    plot,
    sprintf("P2_niveles_%s_%s.png", key$ronda, key$analito),
    width = 11,
    height = 6.5
  )
}

# P3: zero distributions, separated by measurement unit.
for (unit_name in c("ppb", "ppm")) {
  zeros <- stable_data |>
    dplyr::filter(level_num == 1, unidad == unit_name) |>
    dplyr::mutate(
      panel = paste(round_title(ronda), analyte_label(analito), sep = " — "),
      rol = factor(rol, levels = c("ref", "part"))
    )

  plot <- ggplot2::ggplot(
    zeros,
    ggplot2::aes(x = rol, y = valor, colour = rol, shape = rol)
  ) +
    ggplot2::geom_boxplot(
      ggplot2::aes(group = rol),
      width = 0.55,
      outlier.shape = NA,
      linewidth = 0.55,
      na.rm = TRUE
    ) +
    ggplot2::geom_point(
      position = ggplot2::position_jitter(width = 0.12, height = 0),
      alpha = 0.35,
      size = 1.5,
      na.rm = TRUE
    ) +
    ggplot2::facet_wrap(~panel, scales = "free_y") +
    ggplot2::scale_colour_manual(
      values = ROLE_COLORS, labels = ROLE_LABELS, name = "Rol"
    ) +
    ggplot2::scale_shape_manual(
      values = ROLE_SHAPES, labels = ROLE_LABELS, name = "Rol"
    ) +
    ggplot2::scale_x_discrete(labels = ROLE_LABELS) +
    ggplot2::labs(
      title = paste("Comparación de ceros —", unit_name),
      subtitle = "Distribución cruda del nivel 1; offset y dispersión se leen por separado.",
      x = NULL,
      y = paste("Valor en cero (", unit_name, ")", sep = ""),
      caption = if (unit_name == "ppb") {
        paste(
          "Nota: el cero de R2C–NO2 tiene n reducido por un gap temporal",
          "de aproximadamente 12 horas."
        )
      } else {
        "CO se presenta por separado porque su unidad es ppm."
      }
    ) +
    plot_theme() +
    ggplot2::theme(axis.text.x = ggplot2::element_blank(),
                   axis.ticks.x = ggplot2::element_blank())

  save_plot(plot, paste0("P3_ceros_", unit_name, ".png"), 11, 7)
}

# P4: point-paired Bland-Altman comparison within each round.
paired <- stable_data |>
  dplyr::select(
    source_file, source_row, ronda, analito, unidad, level, rol, valor
  ) |>
  tidyr::pivot_wider(names_from = rol, values_from = valor) |>
  dplyr::filter(is.finite(ref), is.finite(part)) |>
  dplyr::mutate(
    promedio = (ref + part) / 2,
    diferencia = ref - part,
    panel = paste(round_title(ronda), analyte_label(analito), sep = " — ")
  )

ba_lines <- paired |>
  dplyr::group_by(panel) |>
  dplyr::summarise(
    mean_diff = mean(diferencia, na.rm = TRUE),
    sd_diff = stats::sd(diferencia, na.rm = TRUE),
    lower = mean_diff - 1.96 * sd_diff,
    upper = mean_diff + 1.96 * sd_diff,
    .groups = "drop"
  )

plot_p4 <- ggplot2::ggplot(
  paired,
  ggplot2::aes(x = promedio, y = diferencia, colour = level, shape = level)
) +
  ggplot2::geom_point(alpha = 0.45, size = 1.5) +
  ggplot2::geom_hline(
    data = ba_lines,
    ggplot2::aes(yintercept = mean_diff),
    inherit.aes = FALSE,
    colour = "grey15",
    linewidth = 0.6
  ) +
  ggplot2::geom_hline(
    data = ba_lines,
    ggplot2::aes(yintercept = lower),
    inherit.aes = FALSE,
    colour = "grey35",
    linetype = "dashed",
    linewidth = 0.45
  ) +
  ggplot2::geom_hline(
    data = ba_lines,
    ggplot2::aes(yintercept = upper),
    inherit.aes = FALSE,
    colour = "grey35",
    linetype = "dashed",
    linewidth = 0.45
  ) +
  ggplot2::facet_wrap(~panel, scales = "free") +
  ggplot2::scale_shape_manual(values = LEVEL_SHAPES, name = "Nivel") +
  ggplot2::scale_colour_viridis_d(option = "D", end = 0.85, name = "Nivel") +
  ggplot2::labs(
    title = "Bland–Altman: referencia frente a participante",
    subtitle = "Línea sólida: diferencia media; líneas discontinuas: límites de acuerdo del 95%.",
    x = "Promedio de ambos equipos",
    y = "Referencia − participante",
    caption = "Comparaciones apareadas únicamente dentro de cada ronda."
  ) +
  plot_theme()
save_plot(plot_p4, "P4_bland_altman.png", 12, 8)

# Shared four-series data for the R2 x R3 matrix.
matrix_data <- stable_data |>
  dplyr::filter(analito %in% c("o3", "no", "no2"),
                ronda %in% c("R2A", "R2B", "R2C", "R3")) |>
  dplyr::mutate(
    series = dplyr::case_when(
      ronda != "R3" & rol == "ref" ~ "ref_R2",
      ronda != "R3" & rol == "part" ~ "P1",
      ronda == "R3" & rol == "ref" ~ "ref_R3",
      ronda == "R3" & rol == "part" ~ "P2"
    ),
    analito_label = analyte_label(analito)
  )

matrix_summary <- matrix_data |>
  dplyr::filter(level_num %in% 2:5,
                !(analito == "no2" & level_num == 3)) |>
  dplyr::group_by(analito_label, level_num, series) |>
  dplyr::summarise(
    mean_error = mean(err_rel, na.rm = TRUE) * 100,
    .groups = "drop"
  ) |>
  dplyr::mutate(series = factor(series, levels = names(MATRIX_COLORS)))

plot_p5 <- ggplot2::ggplot(
  matrix_summary,
  ggplot2::aes(
    x = level_num, y = mean_error, colour = series,
    linetype = series, shape = series, group = series
  )
) +
  ggplot2::geom_hline(yintercept = 0, colour = "grey45", linewidth = 0.4) +
  ggplot2::geom_line(linewidth = 0.8, na.rm = TRUE) +
  ggplot2::geom_point(size = 2.7, stroke = 0.8) +
  ggplot2::facet_wrap(~analito_label, scales = "free_y") +
  ggplot2::scale_x_continuous(breaks = 2:5) +
  ggplot2::scale_colour_manual(values = MATRIX_COLORS, name = "Serie") +
  ggplot2::scale_linetype_manual(values = MATRIX_TYPES, name = "Serie") +
  ggplot2::scale_shape_manual(values = MATRIX_SHAPES, name = "Serie") +
  ggplot2::labs(
    title = "Matriz R2 × R3: error relativo por nivel",
    subtitle = "Cuatro series discretas; las comparaciones entre rondas usan agregados por nivel.",
    x = "Nivel PT",
    y = "Error relativo medio (%)",
    caption = paste(
      "NO2 nivel 3 excluido de la matriz (nominal 105 vs 112 ppb).",
      "NO2 nivel 2 en R3: nominal 144 ppb y lecturas cercanas a 154 ppb",
      "en ambos equipos; se muestra sin corrección."
    )
  ) +
  plot_theme()
save_plot(plot_p5, "P5_matriz_C.png", 11, 6.5)

# P5c: matrix zero level in absolute ppb.
zero_matrix <- matrix_data |>
  dplyr::filter(level_num == 1) |>
  dplyr::group_by(analito_label, series) |>
  dplyr::summarise(
    mean_value = mean(valor, na.rm = TRUE),
    sd_value = stats::sd(valor, na.rm = TRUE),
    .groups = "drop"
  ) |>
  dplyr::mutate(series = factor(series, levels = names(MATRIX_COLORS)))

plot_p5c <- ggplot2::ggplot(
  zero_matrix,
  ggplot2::aes(x = series, y = mean_value, colour = series, shape = series)
) +
  ggplot2::geom_hline(yintercept = 0, colour = "grey45", linewidth = 0.4) +
  ggplot2::geom_errorbar(
    ggplot2::aes(ymin = mean_value - sd_value, ymax = mean_value + sd_value),
    width = 0.16,
    linewidth = 0.55
  ) +
  ggplot2::geom_point(size = 3) +
  ggplot2::facet_wrap(~analito_label, scales = "free_y") +
  ggplot2::scale_colour_manual(values = MATRIX_COLORS, name = "Serie") +
  ggplot2::scale_shape_manual(values = MATRIX_SHAPES, name = "Serie") +
  ggplot2::labs(
    title = "Matriz R2 × R3: nivel 1 (cero)",
    subtitle = "Media ± 1 DE en unidades absolutas; el cero no admite error relativo.",
    x = NULL,
    y = "Valor medio (ppb)",
    caption = paste(
      "El cero de R2C–NO2 tiene n reducido por un gap temporal",
      "de aproximadamente 12 horas."
    )
  ) +
  plot_theme()
save_plot(plot_p5c, "P5c_ceros_matriz.png", 10, 6)

# P5b: compare the participant-gap change with reference drift.
closure <- matrix_data |>
  dplyr::filter(level_num %in% 2:5,
                !(analito == "no2" & level_num == 3)) |>
  dplyr::group_by(analito_label, level_num, series) |>
  dplyr::summarise(mean_error = mean(err_rel, na.rm = TRUE) * 100,
                   .groups = "drop") |>
  tidyr::pivot_wider(names_from = series, values_from = mean_error) |>
  dplyr::mutate(
    `C3 − C2` = (ref_R3 - P2) - (ref_R2 - P1),
    C1 = ref_R3 - ref_R2
  ) |>
  tidyr::pivot_longer(
    cols = c("C3 − C2", "C1"),
    names_to = "componente",
    values_to = "valor"
  )

closure_colors <- c(`C3 − C2` = "#D55E00", C1 = "#0072B2")
closure_shapes <- c(`C3 − C2` = 17, C1 = 16)
closure_types <- c(`C3 − C2` = "longdash", C1 = "solid")
plot_p5b <- ggplot2::ggplot(
  closure,
  ggplot2::aes(
    x = level_num, y = valor, colour = componente,
    shape = componente, linetype = componente, group = componente
  )
) +
  ggplot2::geom_hline(yintercept = 0, colour = "grey45", linewidth = 0.4) +
  ggplot2::geom_line(linewidth = 0.8) +
  ggplot2::geom_point(size = 2.7) +
  ggplot2::facet_wrap(~analito_label, scales = "free_y") +
  ggplot2::scale_x_continuous(breaks = 2:5) +
  ggplot2::scale_colour_manual(values = closure_colors, name = "Componente") +
  ggplot2::scale_shape_manual(values = closure_shapes, name = "Componente") +
  ggplot2::scale_linetype_manual(values = closure_types, name = "Componente") +
  ggplot2::labs(
    title = "Cierre de la matriz: C3 − C2 frente a C1",
    subtitle = "La proximidad entre líneas indica cuánto explica la deriva de la referencia.",
    x = "Nivel PT",
    y = "Diferencia en error relativo (puntos porcentuales)",
    caption = paste(
      "NO2 nivel 3 excluido. NO2 nivel 2 en R3 se conserva",
      "sin corregir la anomalía del nominal."
    )
  ) +
  plot_theme()
save_plot(plot_p5b, "P5b_cierre.png", 11, 6.5)

# P6: reference performance, separated by unit.
reference_summary <- stable_data |>
  dplyr::filter(rol == "ref", level_num %in% 2:5) |>
  dplyr::group_by(ronda, analito, unidad, level_num, nominal) |>
  dplyr::summarise(
    bias_relative = mean(err_rel, na.rm = TRUE) * 100,
    .groups = "drop"
  ) |>
  dplyr::mutate(
    series = paste(round_title(ronda), analyte_label(analito), sep = " — ")
  )

for (unit_name in c("ppb", "ppm")) {
  current <- reference_summary |>
    dplyr::filter(unidad == unit_name, is.finite(bias_relative))
  series_levels <- unique(current$series)
  shape_values <- stats::setNames(
    c(16, 17, 15, 18, 8, 3, 7)[seq_along(series_levels)],
    series_levels
  )
  type_values <- stats::setNames(
    c("solid", "longdash", "dotdash", "twodash", "dashed", "dotted",
      "1234")[seq_along(series_levels)],
    series_levels
  )
  plot <- ggplot2::ggplot(
    current,
    ggplot2::aes(
      x = nominal, y = bias_relative, colour = series,
      linetype = series, shape = series, group = series
    )
  ) +
    ggplot2::geom_hline(yintercept = 0, colour = "grey45", linewidth = 0.4) +
    ggplot2::geom_line(linewidth = 0.75) +
    ggplot2::geom_point(size = 2.5) +
    ggplot2::scale_colour_viridis_d(
      option = "D", end = 0.85, name = "Ronda — analito"
    ) +
    ggplot2::scale_linetype_manual(
      values = type_values, name = "Ronda — analito"
    ) +
    ggplot2::scale_shape_manual(
      values = shape_values, name = "Ronda — analito"
    ) +
    ggplot2::labs(
      title = paste("Desempeño de la referencia —", unit_name),
      subtitle = "Sesgo relativo del analizador CalAire 4U frente al nominal.",
      x = paste("Nivel nominal (", unit_name, ")", sep = ""),
      y = "Sesgo relativo medio (%)",
      caption = if (unit_name == "ppb") {
        paste(
          "NO2 nivel 2 en R3 se reporta sin corrección:",
          "ambos equipos midieron cerca de 154 ppb frente a 144 ppb nominales."
        )
      } else {
        "CO se presenta por separado porque su unidad es ppm."
      }
    ) +
    plot_theme()
  save_plot(plot, paste0("P6_referencia_", unit_name, ".png"), 10, 6)
}

# P7: descriptive characterization of participant P1 in R1 and R2.
p1_bias <- stable_data |>
  dplyr::filter(rol == "part", participante == "P1", level_num %in% 2:5) |>
  dplyr::group_by(ronda, analito) |>
  dplyr::summarise(value = mean(abs(err_rel), na.rm = TRUE) * 100,
                   .groups = "drop") |>
  dplyr::mutate(metric = "Magnitud media del sesgo relativo (%)")

p1_zero <- stable_data |>
  dplyr::filter(rol == "part", participante == "P1", level_num == 1) |>
  dplyr::group_by(ronda, analito) |>
  dplyr::summarise(value = stats::sd(valor, na.rm = TRUE), .groups = "drop") |>
  dplyr::mutate(metric = "Ruido de cero (DE, unidad original)")

p1_summary <- dplyr::bind_rows(p1_bias, p1_zero) |>
  dplyr::mutate(
    analito_label = analyte_label(analito),
    ronda_label = round_title(ronda)
  )

plot_p7 <- ggplot2::ggplot(
  p1_summary,
  ggplot2::aes(
    x = analito_label, y = value, colour = ronda_label,
    shape = ronda_label, group = ronda_label
  )
) +
  ggplot2::geom_point(size = 3, position = ggplot2::position_dodge(width = 0.35)) +
  ggplot2::facet_wrap(~metric, scales = "free_y", ncol = 1) +
  ggplot2::scale_colour_manual(
    values = c(`Ronda 1` = "#0072B2", `Ronda 2A` = "#D55E00",
               `Ronda 2B` = "#009E73", `Ronda 2C` = "#CC79A7"),
    name = "Ronda"
  ) +
  ggplot2::scale_shape_discrete(name = "Ronda") +
  ggplot2::labs(
    title = "Participante P1 a través de R1 y R2",
    subtitle = "Comparación descriptiva entre analitos; no constituye un contraste inferencial.",
    x = "Analito",
    y = NULL,
    caption = paste(
      "CO conserva su unidad original (ppm) en el panel de ruido de cero;",
      "no se compara numéricamente con los analitos en ppb."
    )
  ) +
  plot_theme()
save_plot(plot_p7, "P7_participante_p1.png", 10, 7)

# P8: NOx conservation in the multichannel R3 files.
if (!exists("pt_nox_residuals", inherits = TRUE)) {
  source(file.path(SCRIPT_DIR, "02_qc.R"))
}
nox_plot_data <- pt_nox_residuals |>
  dplyr::left_join(
    pt_qc |>
      dplyr::filter(source_file %in% c("R3_NO.csv", "R3_NO2.csv")) |>
      dplyr::distinct(source_file, source_row, analito, level_num),
    by = c("source_file", "source_row")
  ) |>
  dplyr::filter(level_num %in% 1:5) |>
  dplyr::mutate(
    analito_label = analyte_label(analito),
    rol = factor(rol, levels = c("ref", "part")),
    level_num = factor(level_num, levels = 1:5)
  )

plot_p8 <- ggplot2::ggplot(
  nox_plot_data,
  ggplot2::aes(
    x = level_num, y = nox_residuo, colour = rol,
    shape = rol, group = interaction(level_num, rol)
  )
) +
  ggplot2::geom_hline(yintercept = 0, colour = "grey35", linewidth = 0.5) +
  ggplot2::geom_boxplot(
    ggplot2::aes(fill = rol),
    position = ggplot2::position_dodge(width = 0.7),
    width = 0.58,
    alpha = 0.14,
    outlier.shape = NA,
    linewidth = 0.5
  ) +
  ggplot2::geom_point(
    position = ggplot2::position_jitterdodge(
      jitter.width = 0.12, dodge.width = 0.7
    ),
    alpha = 0.25,
    size = 1.2
  ) +
  ggplot2::facet_wrap(~analito_label, scales = "free_y") +
  ggplot2::scale_colour_manual(
    values = ROLE_COLORS, labels = ROLE_LABELS, name = "Rol"
  ) +
  ggplot2::scale_fill_manual(
    values = ROLE_COLORS, labels = ROLE_LABELS, name = "Rol"
  ) +
  ggplot2::scale_shape_manual(
    values = ROLE_SHAPES, labels = ROLE_LABELS, name = "Rol"
  ) +
  ggplot2::labs(
    title = "Conservación de NOx en R3",
    subtitle = "Residuo NO + NO2 − NOx por equipo y nivel.",
    x = "Nivel PT",
    y = "Residuo (ppb)",
    caption = "Chequeo disponible sólo en R3; las rondas R2 son monocanal."
  ) +
  plot_theme()
save_plot(plot_p8, "P8_nox_r3.png", 10, 6.5)

message("Figuras P1-P8 guardadas en: ", FIG_DIR)
