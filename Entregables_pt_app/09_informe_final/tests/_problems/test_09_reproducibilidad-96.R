# Extracted from test_09_reproducibilidad.R:96

# prequel ----------------------------------------------------------------------
find_project_root <- function(path = getwd()) {
  path <- normalizePath(path)
  repeat {
    if (file.exists(file.path(path, "app.R")) &&
        file.exists(file.path(path, "ptcalc", "DESCRIPTION"))) {
      return(path)
    }
    parent <- dirname(path)
    if (identical(parent, path)) {
      stop("Project root not found.")
    }
    path <- parent
  }
}
root_dir <- find_project_root()
devtools::load_all(file.path(root_dir, "ptcalc"), quiet = TRUE)
hom <- matrix(c(
  9.98, 10.02, 10.01, 10.03, 9.99, 10.00, 10.04, 10.02,
  9.97, 10.01, 10.00, 10.02, 10.03, 10.01, 9.98, 9.99,
  10.02, 10.00, 10.01, 10.04
), ncol = 2, byrow = TRUE)
participants <- c(9.91, 9.96, 9.99, 10.00, 10.02, 10.04, 10.08, 10.60)

# test -------------------------------------------------------------------------
h <- calculate_homogeneity_stats(hom)
testthat::expect_error(
    calculate_homogeneity_criterion_expanded(h$MADe, h$sw, h$g),
    "Invalid arguments", fixed = TRUE
  )
named_result <- calculate_homogeneity_criterion_expanded(
    sigma_pt = h$MADe, sw = h$sw, g = h$g
  )
testthat::expect_equal(named_result, 0.0004016209, tolerance = 1e-10)
