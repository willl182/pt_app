#!/usr/bin/env Rscript

# ===================================================================
# Adapts round 3 minute-level raw files (R3_*.csv, one "date time"
# column plus per-instrument serial columns) to the CalAire raw layout
# consumed by build_bootstrap_homogeneity_stability.R:
#
#   Date;Time;<POLLUTANT>_ref;<POLLUTANT>_gen
#
# The reference series is the CalAire instrument (serial prefixed 4U).
# ===================================================================

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
})

REFERENCE_PREFIX <- "4U"

specs <- list(
  list(input = "data/raw/R3_O3.csv",  pollutant = "o3",  output = "data/raw/datos_ronda_3a_r.csv"),
  list(input = "data/raw/R3_NO.csv",  pollutant = "no",  output = "data/raw/datos_ronda_3b_r.csv"),
  list(input = "data/raw/R3_NO2.csv", pollutant = "no2", output = "data/raw/datos_ronda_3c_r.csv")
)

adapt <- function(spec) {
  raw <- readr::read_csv(spec$input, show_col_types = FALSE, progress = FALSE)

  candidates <- grep(
    paste0("^", spec$pollutant, "_", REFERENCE_PREFIX),
    names(raw),
    value = TRUE
  )
  if (length(candidates) != 1) {
    stop(
      "Expected exactly one reference column for ", spec$pollutant,
      " in ", spec$input, "; found: ", paste(candidates, collapse = ", "),
      call. = FALSE
    )
  }
  gen_col <- paste0(spec$pollutant, "_gen")
  if (!gen_col %in% names(raw)) {
    stop("Missing generator column ", gen_col, " in ", spec$input, call. = FALSE)
  }

  stamp <- trimws(raw[["date time"]])
  parts <- strsplit(stamp, " ", fixed = TRUE)
  upper <- toupper(spec$pollutant)

  out <- tibble::tibble(
    Date = vapply(parts, `[`, character(1), 1L),
    Time = paste0(vapply(parts, `[`, character(1), 2L), ":00"),
    ref  = as.numeric(raw[[candidates]]),
    gen  = as.numeric(raw[[gen_col]])
  )
  names(out)[3:4] <- c(paste0(upper, "_ref"), paste0(upper, "_gen"))

  readr::write_delim(out, spec$output, delim = ";", na = "")
  message(
    "  ", spec$input, " [", candidates, "] -> ", spec$output,
    " (", nrow(out), " rows)"
  )
}

invisible(lapply(specs, adapt))
