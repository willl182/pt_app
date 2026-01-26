# AGENTS.md - Developer Guide for AI Coding Agents

This document provides essential information for AI coding agents working on the PT (Proficiency Testing) Analysis Application.

## Project Overview

**Type:** R/Shiny web application  
**Purpose:** Proficiency testing analysis per ISO 13528:2022 and ISO 17043:2024  
**Main Files:** `app.R` (Shiny UI/Server), `ptcalc/` (calculation package)  
**Architecture:** MVC pattern with reactive programming  
**License:** MIT (Universidad Nacional de Colombia / Instituto Nacional de Metrología)

## Quick Reference Commands

### Running the Application
```r
# Start the Shiny app
Rscript app.R

# Or from R console
shiny::runApp()
```

### Package Development (ptcalc)
```r
# Load package for development (PREFERRED in dev)
devtools::load_all("ptcalc")

# Install package locally
devtools::install("ptcalc")

# Generate documentation
devtools::document("ptcalc")

# Check package
devtools::check("ptcalc")
```

### Testing

#### Run All Tests
```r
# From project root
testthat::test_dir("tests/testthat")

# Or using devtools (if in package context)
devtools::test()
```

#### Run Single Test File
```r
# Run specific test file
testthat::test_file("tests/testthat/test-doc-inventory.R")

# Run with pattern matching
testthat::test_dir("tests/testthat", filter = "doc-inventory")
```

#### Run Single Test Case
```r
# Source the test file and run interactively
source("tests/testthat/test-doc-inventory.R")

# Or use test_that directly in console
test_that("inventory script generates a valid CSV", {
  # test code here
})
```

### Linting and Style Checking
```r
# Check code style (if lintr is available)
lintr::lint("R/pt_scores.R")
lintr::lint_dir("R/")

# Format code with styler (tidyverse style)
styler::style_file("R/pt_scores.R")
styler::style_dir("R/")
```

### Building and Documentation
```r
# Build package tarball
devtools::build("ptcalc")

# Check examples
devtools::run_examples("ptcalc")
```

## Code Style Guidelines

### 1. Assignment Operator
- **ALWAYS use** `<-` for assignment (NOT `=`)
- Exception: Named function arguments use `=`

```r
# CORRECT
x <- 10
result <- calculate_z_score(x = 10.5, x_pt = 10.0, sigma_pt = 0.5)

# WRONG
x = 10
```

### 2. Naming Conventions

#### Functions
- Use `snake_case` for all function names
- Be descriptive: `calculate_z_score()`, not `calc_z()`
- Prefix related functions: `calculate_*`, `evaluate_*`, `run_*`

#### Variables
- Use `snake_case` for variables
- Short names for iteration: `i`, `g`, `m`
- Descriptive names for data: `sample_data`, `x_pt`, `sigma_pt`

#### Constants
- Use `SCREAMING_SNAKE_CASE` for package constants
- Example: `PT_EN_CLASS_COLORS`, `PT_EN_CLASS_LABELS`

### 3. Function Documentation (roxygen2)

**REQUIRED for all exported functions:**

```r
#' Brief one-line description
#'
#' More detailed description explaining the function's purpose,
#' methodology, and any important considerations.
#'
#' Reference: ISO 13528:2022, Section X.X
#'
#' @param x Description of parameter x.
#' @param y Description of parameter y.
#' @return Description of return value.
#'
#' @examples
#' # Example usage
#' result <- my_function(x = 10, y = 20)
#'
#' @seealso \code{\link{related_function}}
#' @export
my_function <- function(x, y) {
  # implementation
}
```

### 4. File Headers

Include descriptive headers in R files:

```r
# ===================================================================
# Brief Description of File Purpose
# ISO Standard Reference (if applicable)
#
# Additional context about the file's role.
# List key functions or responsibilities.
# ===================================================================
```

### 5. Import Statements

#### In Package Files (ptcalc/R/)
- Use `@importFrom` in roxygen comments, NOT `library()`
- Specify exact functions needed: `@importFrom stats median sd var`
- Package-level imports go in `ptcalc-package.R`

```r
# CORRECT (in package)
#' @importFrom stats median
#' @export
calculate_median <- function(x) {
  stats::median(x)
}

# WRONG (in package)
library(stats)  # Never use library() in package code
```

#### In Shiny App (app.R)
- Load libraries at the top of the file
- One `library()` call per line
- Group by purpose (Shiny, tidyverse, specialized)

```r
# Shiny and UI
library(shiny)
library(bslib)
library(DT)

# Data manipulation
library(tidyverse)
library(vroom)

# Specialized
library(outliers)
library(plotly)
```

### 6. Error Handling

#### Validation Checks
```r
# Check for invalid input
if (!is.finite(sigma_pt) || sigma_pt <= 0) {
  return(NA_real_)
}

# Check data structure
if (is.data.frame(sample_data)) {
  sample_data <- as.matrix(sample_data)
}

# Check minimum requirements
if (g < 2) {
  return(list(error = "At least 2 samples required for homogeneity assessment."))
}
```

#### Return NA for Invalid Cases
- Use typed NA: `NA_real_`, `NA_integer_`, `NA_character_`
- Return consistent types across all code paths

### 7. Code Formatting

#### Spacing
- Space after commas: `c(1, 2, 3)` not `c(1,2,3)`
- Space around operators: `x <- y + z` not `x<-y+z`
- No space before `(` in function calls: `mean(x)` not `mean (x)`

#### Line Length
- Aim for ≤ 80 characters per line
- Break long function calls across lines with proper indentation

#### Indentation
- Use 2 spaces (NOT tabs)
- Align function arguments vertically when breaking across lines

### 8. Comments

```r
# Single-line comments start with # followed by space

# Multi-line explanations use multiple
# single-line comments, each starting with #

# Section separators (in app.R)
# -------------------------------------------------------------------
# Section Title
# -------------------------------------------------------------------
```

### 9. Deprecation

Mark deprecated functions with lifecycle badges:

```r
#' @description
#' `r lifecycle::badge("deprecated")`
#'
#' This function is deprecated. Please use \code{\link{new_function}} instead.
```

## Architecture Principles

### Separation of Concerns

1. **Pure Calculations** → `ptcalc/R/` (NO Shiny dependencies)
2. **UI Definition** → `app.R` (Shiny UI components)
3. **Reactive Logic** → `app.R` server function (orchestration)
4. **Data Files** → `data/` directory (CSV files)

### File Organization

```
pt_app/
├── app.R                 # Main Shiny application
├── R/                    # Helper functions (Shiny-aware)
│   ├── pt_homogeneity.R
│   ├── pt_robust_stats.R
│   ├── pt_scores.R
│   └── utils.R          # DEPRECATED
├── ptcalc/              # Pure calculation package
│   ├── R/               # Package functions
│   ├── man/             # Generated documentation
│   ├── DESCRIPTION      # Package metadata
│   └── NAMESPACE        # Generated exports
├── tests/testthat/      # Test files
├── data/                # Input CSV files
└── scripts/             # Demo scripts
```

## Testing Guidelines

- Tests primarily validate documentation merging and file existence
- Use `testthat` framework with `test_that()` blocks
- Set working directory context in tests when needed:
  ```r
  old_wd <- setwd("../..")
  on.exit(setwd(old_wd))
  ```

## Common Patterns

### Vectorized Evaluation Functions

Use `dplyr::case_when()` for vectorized conditionals:

```r
evaluate_score_vec <- function(z) {
  dplyr::case_when(
    !is.finite(z) ~ "N/A",
    abs(z) <= 2 ~ "Satisfactorio",
    abs(z) > 2 & abs(z) < 3 ~ "Cuestionable",
    abs(z) >= 3 ~ "No satisfactorio"
  )
}
```

## References

- **ISO 13528:2022** - Statistical methods for proficiency testing
- **ISO 17043:2024** - General requirements for proficiency testing
- **Tidyverse Style Guide** - https://style.tidyverse.org/
- **R Packages (2e)** - https://r-pkgs.org/

## Important Notes

- NEVER use `library()` or `require()` in package code (ptcalc/)
- ALWAYS use `devtools::load_all("ptcalc")` during development
- Mathematical functions must have NO Shiny dependencies
- Document all exported functions with roxygen2
- Include ISO standard references in documentation
- Use Spanish for user-facing text, English for code/comments
