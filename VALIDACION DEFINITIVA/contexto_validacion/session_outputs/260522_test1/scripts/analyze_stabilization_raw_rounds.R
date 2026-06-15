# ===================================================================
# Raw Round Stabilization Analysis
#
# Detects generator concentration changes in raw round files, estimates
# signal stabilization time, and generates one plot per pollutant.
# ===================================================================

source("R/preprocessing/read_calaire_raw.R")

parse_raw_timestamp <- function(date, time, tz = "America/Bogota") {
  text <- paste(trimws(date), trimws(time))

  as.POSIXct(
    text,
    tz = tz,
    tryFormats = c(
      "%m/%d/%y %I:%M:%S %p",
      "%m/%d/%Y %I:%M:%S %p",
      "%m/%d/%y %H:%M",
      "%m/%d/%Y %H:%M"
    )
  )
}

clean_numeric <- function(x) {
  suppressWarnings(as.numeric(trimws(x)))
}

pollutant_from_generator <- function(generator_col) {
  tolower(sub("_gen$", "", generator_col))
}

find_measure_column <- function(data_names, generator_cols, generator_col) {
  pollutant <- pollutant_from_generator(generator_col)
  candidate_names <- setdiff(data_names, c("Date", "Time", generator_cols))

  grep(
    paste0("^", pollutant, "_"),
    candidate_names,
    value = TRUE,
    ignore.case = TRUE
  )[1]
}

calculate_stabilization <- function(timestamp, value, generator,
                                    min_consecutive = 10,
                                    tolerance_fraction = 0.05) {
  complete <- !is.na(timestamp) & !is.na(value) & !is.na(generator)
  timestamp <- timestamp[complete]
  value <- value[complete]
  generator <- generator[complete]

  if (length(generator) < 2) {
    return(data.frame())
  }

  run_starts <- c(1, which(diff(generator) != 0) + 1)
  run_ends <- c(run_starts[-1] - 1, length(generator))
  results <- list()

  for (i in seq_along(run_starts)) {
    start_index <- run_starts[i]
    end_index <- run_ends[i]
    run_minutes <- end_index - start_index + 1

    if (i == 1 || run_minutes < min_consecutive) {
      next
    }

    previous_start <- run_starts[i - 1]
    previous_end <- run_ends[i - 1]

    previous_plateau <- median(
      tail(value[previous_start:previous_end],
           min(30, previous_end - previous_start + 1)),
      na.rm = TRUE
    )
    final_plateau <- median(
      tail(value[start_index:end_index],
           min(30, run_minutes)),
      na.rm = TRUE
    )

    step_size <- abs(final_plateau - previous_plateau)
    tolerance <- max(
      step_size * tolerance_fraction,
      abs(final_plateau) * 0.01,
      0.001
    )

    in_band <- abs(value[start_index:end_index] - final_plateau) <= tolerance
    stable_relative_index <- NA_integer_

    if (length(in_band) >= min_consecutive) {
      rolling_hits <- which(
        stats::filter(
          as.integer(in_band),
          rep(1, min_consecutive),
          sides = 1
        ) >= min_consecutive
      )

      if (length(rolling_hits) > 0) {
        stable_relative_index <- rolling_hits[1] - min_consecutive + 1
      }
    }

    stable_timestamp <- if (is.na(stable_relative_index)) {
      as.POSIXct(NA, origin = "1970-01-01", tz = attr(timestamp, "tzone"))
    } else {
      timestamp[start_index + stable_relative_index - 1]
    }

    results[[length(results) + 1]] <- data.frame(
      change_time = format(timestamp[start_index], "%Y-%m-%d %H:%M"),
      from_gen = generator[start_index - 1],
      to_gen = generator[start_index],
      prev_plateau = round(previous_plateau, 3),
      final_plateau = round(final_plateau, 3),
      tolerance = round(tolerance, 3),
      stable_time = format(stable_timestamp, "%Y-%m-%d %H:%M"),
      minutes_to_stable = if (is.na(stable_relative_index)) {
        NA_integer_
      } else {
        as.integer(difftime(
          stable_timestamp,
          timestamp[start_index],
          units = "mins"
        ))
      },
      run_minutes = run_minutes,
      stringsAsFactors = FALSE
    )
  }

  if (length(results) == 0) {
    return(data.frame())
  }

  do.call(rbind, results)
}

read_raw_measurements <- function(raw_dir = "data/raw") {
  files <- list.files(raw_dir, full.names = TRUE, pattern = "[.]csv$")
  measurements <- list()
  stabilizations <- list()

  for (file in files) {
    raw <- read_calaire_raw(file)$data
    raw <- raw[nzchar(trimws(raw$Date)), , drop = FALSE]

    timestamp <- parse_raw_timestamp(raw$Date, raw$Time)
    generator_cols <- grep("_gen$", names(raw), value = TRUE)

    for (generator_col in generator_cols) {
      measure_col <- find_measure_column(names(raw), generator_cols, generator_col)

      if (is.na(measure_col)) {
        next
      }

      pollutant <- pollutant_from_generator(generator_col)
      value <- clean_numeric(raw[[measure_col]])
      generator <- clean_numeric(raw[[generator_col]])

      measurement <- data.frame(
        file = basename(file),
        pollutant = pollutant,
        measure = measure_col,
        generator = generator_col,
        timestamp = timestamp,
        value = value,
        generator_value = generator,
        stringsAsFactors = FALSE
      )
      measurement <- measurement[!is.na(measurement$timestamp), , drop = FALSE]

      measurements[[length(measurements) + 1]] <- measurement

      stabilization <- calculate_stabilization(timestamp, value, generator)

      if (nrow(stabilization) > 0) {
        stabilization$file <- basename(file)
        stabilization$pollutant <- pollutant
        stabilization$measure <- measure_col
        stabilization$generator <- generator_col
        stabilizations[[length(stabilizations) + 1]] <- stabilization
      }
    }
  }

  list(
    measurements = do.call(rbind, measurements),
    stabilizations = do.call(rbind, stabilizations)
  )
}

write_stabilization_table <- function(stabilizations,
                                      output_path = paste0(
                                        "session_outputs/",
                                        "260522_test1/",
                                        "results/tables/",
                                        "stabilization_times_raw_rounds.csv"
                                      )) {
  dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)

  output <- stabilizations[, c(
    "file", "measure", "generator", "pollutant", "change_time", "from_gen",
    "to_gen", "prev_plateau", "final_plateau", "tolerance", "stable_time",
    "minutes_to_stable", "run_minutes"
  )]

  utils::write.csv(output, output_path, row.names = FALSE)
  output
}

plot_pollutant_stabilization <- function(measurements, stabilizations,
                                         output_dir = paste0(
                                           "session_outputs/",
                                           "260522_test1/",
                                           "results/figures"
                                         )) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required to generate plots.")
  }

  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  plot_paths <- character(0)

  for (pollutant in sort(unique(measurements$pollutant))) {
    measurement_data <- measurements[
      measurements$pollutant == pollutant,
      ,
      drop = FALSE
    ]
    stabilization_data <- stabilizations[
      stabilizations$pollutant == pollutant,
      ,
      drop = FALSE
    ]

    stabilization_data$change_timestamp <- as.POSIXct(
      stabilization_data$change_time,
      format = "%Y-%m-%d %H:%M",
      tz = "America/Bogota"
    )
    stabilization_data$stable_timestamp <- as.POSIXct(
      stabilization_data$stable_time,
      format = "%Y-%m-%d %H:%M",
      tz = "America/Bogota"
    )

    plot <- ggplot2::ggplot(
      measurement_data,
      ggplot2::aes(x = timestamp, y = value)
    ) +
      ggplot2::geom_line(ggplot2::aes(color = measure), linewidth = 0.35) +
      ggplot2::geom_step(
        ggplot2::aes(y = generator_value, linetype = "Generador"),
        color = "grey35",
        linewidth = 0.45,
        na.rm = TRUE
      ) +
      ggplot2::geom_vline(
        data = stabilization_data,
        ggplot2::aes(xintercept = change_timestamp),
        color = "#B44A3C",
        linewidth = 0.35,
        alpha = 0.65
      ) +
      ggplot2::geom_point(
        data = stabilization_data,
        ggplot2::aes(x = stable_timestamp, y = final_plateau),
        inherit.aes = FALSE,
        color = "#1F7A5A",
        size = 2,
        na.rm = TRUE
      ) +
      ggplot2::facet_wrap(ggplot2::vars(file), scales = "free_x", ncol = 1) +
      ggplot2::scale_linetype_manual(values = c("Generador" = "dashed")) +
      ggplot2::labs(
        title = paste("Estabilización después de cambios de concentración -",
                      toupper(pollutant)),
        x = "Tiempo",
        y = "Concentración",
        color = "Medida",
        linetype = NULL,
        caption = paste(
          "Líneas rojas: cambio del generador.",
          "Puntos verdes: primer minuto estable según el criterio operativo."
        )
      ) +
      ggplot2::theme_minimal(base_size = 11) +
      ggplot2::theme(
        legend.position = "bottom",
        panel.grid.minor = ggplot2::element_blank(),
        plot.title = ggplot2::element_text(face = "bold")
      )

    output_path <- file.path(
      output_dir,
      paste0("stabilization_", pollutant, ".png")
    )

    ggplot2::ggsave(
      filename = output_path,
      plot = plot,
      width = 11,
      height = max(5, 2.8 * length(unique(measurement_data$file))),
      dpi = 160
    )

    plot_paths <- c(plot_paths, output_path)
  }

  plot_paths
}

main <- function() {
  analysis <- read_raw_measurements()
  table <- write_stabilization_table(analysis$stabilizations)
  plot_paths <- plot_pollutant_stabilization(
    analysis$measurements,
    analysis$stabilizations
  )

  message(paste0(
    "Tabla generada: session_outputs/260522_test1/",
    "results/tables/stabilization_times_raw_rounds.csv"
  ))
  message("Filas de estabilización: ", nrow(table))
  message("Gráficas generadas:")
  message(paste(" -", plot_paths, collapse = "\n"))
}

if (sys.nframe() == 0) {
  main()
}
