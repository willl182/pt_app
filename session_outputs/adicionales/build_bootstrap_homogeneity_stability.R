#!/usr/bin/env Rscript

# ===================================================================
# Bootstrap datasets for homogeneity and stability
#
# Builds data/homogeneity - homogeneity.csv and
# data/stability - stability.csv from minute-level reference data.
# The input file is explicit on purpose: pass --input=<path>.
# ===================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
})

parse_args <- function(args) {
  parsed <- list()
  for (arg in args) {
    if (!grepl("^--[^=]+=", arg)) {
      stop("Invalid argument: ", arg, call. = FALSE)
    }
    key <- sub("^--([^=]+)=.*$", "\\1", arg)
    value <- sub("^--[^=]+=", "", arg)
    parsed[[key]] <- value
  }
  parsed
}

as_integer_arg <- function(value, name) {
  parsed <- suppressWarnings(as.integer(value))
  if (is.na(parsed)) {
    stop("Argument --", name, " must be an integer.", call. = FALSE)
  }
  parsed
}

derive_output_prefix <- function(input_path) {
  stem <- tools::file_path_sans_ext(basename(input_path))
  stem <- sub("^datos_", "", stem)
  stem <- sub("_(r|p)$", "", stem)
  stem
}

source_preprocessing <- function(root) {
  preprocessing_dir <- file.path(root, "R", "preprocessing")
  for (file in c(
    "read_calaire_raw.R",
    "clean_calaire_raw.R"
  )) {
    source(file.path(preprocessing_dir, file))
  }
}

detect_reference_specs <- function(clean_data) {
  all_names <- names(clean_data)
  ref_cols <- grep("_(ref|calaire)_(ppm|ppb)$", all_names, value = TRUE)
  ref_cols <- setdiff(ref_cols, grep("_gen_", ref_cols, value = TRUE))

  specs <- lapply(ref_cols, function(ref_col) {
    pollutant <- sub("_(ref|calaire)_(ppm|ppb)$", "", ref_col)
    gen_col <- grep(
      paste0("^", pollutant, "_gen_(ppm|ppb)$"),
      all_names,
      value = TRUE
    )

    if (length(gen_col) != 1) {
      return(NULL)
    }

    unit <- if (grepl("_ppm$", ref_col)) "µmol/mol" else "nmol/mol"
    data.frame(
      pollutant = pollutant,
      ref_col = ref_col,
      gen_col = gen_col,
      unit = unit,
      stringsAsFactors = FALSE
    )
  })

  specs <- Filter(Negate(is.null), specs)
  if (length(specs) == 0) {
    stop(
      "No reference/generator column pairs detected. Expected names like ",
      "co_ref/co_gen or co_calaire/co_gen after normalization.",
      call. = FALSE
    )
  }

  dplyr::bind_rows(specs) |>
    dplyr::arrange(.data$pollutant)
}

build_blocks <- function(clean_data, specs) {
  blocks <- vector("list", nrow(specs))

  for (i in seq_len(nrow(specs))) {
    spec <- specs[i, ]
    rows <- clean_data |>
      dplyr::filter(
        !is.na(.data$timestamp),
        !is.na(.data[[spec$ref_col]]),
        !is.na(.data[[spec$gen_col]])
      ) |>
      dplyr::arrange(.data$timestamp)

    if (nrow(rows) == 0) {
      next
    }

    generated <- as.numeric(rows[[spec$gen_col]])
    level <- paste0(generated, "-", spec$unit)
    run <- cumsum(c(TRUE, level[-1] != level[-length(level)]))

    blocks[[i]] <- data.frame(
      pollutant = spec$pollutant,
      run = paste0("corrida_", run),
      level = level,
      timestamp = rows$timestamp,
      value = as.numeric(rows[[spec$ref_col]]),
      source_column = spec$ref_col,
      generator_column = spec$gen_col,
      stringsAsFactors = FALSE
    )
  }

  blocks <- Filter(Negate(is.null), blocks)
  if (length(blocks) == 0) {
    stop("No usable minute-level blocks were found.", call. = FALSE)
  }

  dplyr::bind_rows(blocks) |>
    dplyr::filter(is.finite(.data$value))
}

bootstrap_hourly_means <- function(blocks, n_datasets) {
  groups <- blocks |>
    dplyr::distinct(.data$pollutant, .data$run, .data$level) |>
    dplyr::arrange(.data$pollutant, .data$run, .data$level)

  hourly_results <- vector("list", nrow(groups) * n_datasets)
  minute_results <- vector("list", nrow(groups) * n_datasets)
  k_hourly <- 1L
  k_minute <- 1L

  for (i in seq_len(nrow(groups))) {
    group <- groups[i, ]
    pool <- blocks |>
      dplyr::filter(
        .data$pollutant == group$pollutant,
        .data$run == group$run,
        .data$level == group$level
      ) |>
      dplyr::arrange(.data$timestamp)

    if (nrow(pool) < 1) {
      next
    }

    for (dataset_id in seq_len(n_datasets)) {
      sampled_rows <- sample(seq_len(nrow(pool)), size = 60L, replace = TRUE)
      simulated <- pool[sampled_rows, , drop = FALSE]

      minute_results[[k_minute]] <- data.frame(
        pollutant = group$pollutant,
        run = group$run,
        level = group$level,
        dataset_id = dataset_id,
        simulated_minute = seq_len(60L),
        value = simulated$value,
        source_timestamp = format(simulated$timestamp, "%Y-%m-%d %H:%M:%S"),
        source_column = simulated$source_column,
        generator_column = simulated$generator_column,
        stringsAsFactors = FALSE
      )
      k_minute <- k_minute + 1L

      hourly_results[[k_hourly]] <- data.frame(
        pollutant = group$pollutant,
        run = group$run,
        level = group$level,
        dataset_id = dataset_id,
        value = round(mean(simulated$value), 3),
        minute_pool_n = nrow(pool),
        stringsAsFactors = FALSE
      )
      k_hourly <- k_hourly + 1L
    }
  }

  list(
    hourly = dplyr::bind_rows(hourly_results),
    minutes = dplyr::bind_rows(minute_results)
  )
}

make_assignment <- function(n_datasets) {
  if (n_datasets < 20) {
    stop("At least 20 datasets are required.", call. = FALSE)
  }

  dplyr::bind_rows(
    data.frame(
      study_type = "homogeneity",
      dataset_id = seq_len(20L),
      replicate = rep(1:2, each = 10L),
      sample_id = rep(seq_len(10L), times = 2L),
      stringsAsFactors = FALSE
    ),
    data.frame(
      study_type = "stability",
      dataset_id = seq_len(4L),
      replicate = rep(1:2, each = 2L),
      sample_id = rep(seq_len(2L), times = 2L),
      stringsAsFactors = FALSE
    )
  )
}

build_output <- function(bootstrapped, assignment, target_study_type) {
  assignment |>
    dplyr::filter(.data$study_type == target_study_type) |>
    dplyr::select("dataset_id", "replicate", "sample_id") |>
    dplyr::left_join(bootstrapped, by = "dataset_id") |>
    dplyr::transmute(
      pollutant = .data$pollutant,
      run = .data$run,
      level = .data$level,
      replicate = .data$replicate,
      sample_id = .data$sample_id,
      value = .data$value
    ) |>
    dplyr::arrange(
      .data$pollutant,
      .data$run,
      .data$level,
      .data$replicate,
      .data$sample_id
    )
}

build_register <- function(bootstrapped, assignment, input_path, seed) {
  assignment |>
    dplyr::left_join(
      bootstrapped,
      by = "dataset_id",
      relationship = "many-to-many"
    ) |>
    dplyr::mutate(
      input_path = input_path,
      seed = seed,
      simulated_minutes_n = 60L
    ) |>
    dplyr::select(
      "study_type",
      "pollutant",
      "run",
      "level",
      "replicate",
      "sample_id",
      "dataset_id",
      "value",
      "minute_pool_n",
      "simulated_minutes_n",
      "seed",
      "input_path"
    ) |>
    dplyr::arrange(
      .data$study_type,
      .data$pollutant,
      .data$run,
      .data$level,
      .data$replicate,
      .data$sample_id
    )
}

main <- function() {
  root <- normalizePath(".", mustWork = TRUE)
  args <- parse_args(commandArgs(trailingOnly = TRUE))

  if (is.null(args$input)) {
    stop("Missing required argument --input=<path>.", call. = FALSE)
  }

  input_path <- normalizePath(args$input, mustWork = TRUE)
  seed <- if (is.null(args$seed)) 13528L else as_integer_arg(args$seed, "seed")
  n_datasets <- if (is.null(args$datasets)) {
    20L
  } else {
    as_integer_arg(args$datasets, "datasets")
  }
  output_prefix <- if (is.null(args$output_prefix)) {
    derive_output_prefix(input_path)
  } else {
    args$output_prefix
  }

  homogeneity_out <- if (is.null(args$homogeneity_out)) {
    file.path("data", "processed", paste0(output_prefix, "_homogeneidad.csv"))
  } else {
    args$homogeneity_out
  }
  stability_out <- if (is.null(args$stability_out)) {
    file.path("data", "processed", paste0(output_prefix, "_estabilidad.csv"))
  } else {
    args$stability_out
  }
  register_out <- if (is.null(args$register_out)) {
    "data/metadata/bootstrap_homogeneity_stability_register.csv"
  } else {
    args$register_out
  }
  hourly_datasets_out <- if (is.null(args$hourly_datasets_out)) {
    "data/processed/bootstrap_hourly_datasets.csv"
  } else {
    args$hourly_datasets_out
  }
  simulations_out <- if (is.null(args$simulations_out)) {
    "data/processed/bootstrap_minute_simulations.csv"
  } else {
    args$simulations_out
  }

  source_preprocessing(root)
  set.seed(seed)

  raw <- read_calaire_raw(input_path)
  cleaned <- clean_calaire_raw(raw)$data
  specs <- detect_reference_specs(cleaned)
  blocks <- build_blocks(cleaned, specs)
  bootstrapped <- bootstrap_hourly_means(blocks, n_datasets = n_datasets)
  bootstrapped_hourly <- bootstrapped$hourly
  bootstrapped_minutes <- bootstrapped$minutes
  assignment <- make_assignment(n_datasets)

  homogeneity <- build_output(bootstrapped_hourly, assignment, "homogeneity")
  stability <- build_output(bootstrapped_hourly, assignment, "stability")
  register <- build_register(bootstrapped_hourly, assignment, input_path, seed)

  dir.create(dirname(homogeneity_out), recursive = TRUE, showWarnings = FALSE)
  dir.create(dirname(stability_out), recursive = TRUE, showWarnings = FALSE)
  dir.create(dirname(register_out), recursive = TRUE, showWarnings = FALSE)
  dir.create(dirname(hourly_datasets_out), recursive = TRUE, showWarnings = FALSE)
  dir.create(dirname(simulations_out), recursive = TRUE, showWarnings = FALSE)

  readr::write_csv(homogeneity, homogeneity_out)
  readr::write_csv(stability, stability_out)
  readr::write_csv(register, register_out)
  readr::write_csv(bootstrapped_hourly, hourly_datasets_out)
  readr::write_csv(bootstrapped_minutes, simulations_out)

  message("Input: ", input_path)
  message("Seed: ", seed)
  message("Bootstrap datasets per pollutant/run/level: ", n_datasets)
  message("Homogeneity rows: ", nrow(homogeneity), " -> ", homogeneity_out)
  message("Stability rows: ", nrow(stability), " -> ", stability_out)
  message("Register rows: ", nrow(register), " -> ", register_out)
  message("Hourly dataset rows: ", nrow(bootstrapped_hourly), " -> ", hourly_datasets_out)
  message("Minute simulation rows: ", nrow(bootstrapped_minutes), " -> ", simulations_out)
}

main()
