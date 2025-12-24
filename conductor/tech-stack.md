# Technology Stack

## Core Technologies
- **Programming Language:** R
- **Web Framework:** Shiny (v1.7.0+)
- **Reporting Engine:** R Markdown (generating .docx reports)

## Data Processing & Visualization
- **Data Manipulation:** `tidyverse` (dplyr, tidyr, purrr, ggplot2), `vroom` for fast I/O.
- **Interactive Visuals:** `plotly` for dynamic charts, `DT` for interactive data tables.
- **Plot Composition:** `patchwork` for complex plot layouts.

## UI & User Experience
- **Theming:** `shinythemes` for a professional, clean interface.
- **UI Enhancements:** `bsplus` for extended Bootstrap functionality.
- **Data Entry:** `rhandsontable` for editable data grids.

## Statistical Analysis
- **Outlier Detection:** `outliers` package (specifically for Grubbs' test).
- **Core Algorithms:** Internal implementation of ISO 13528:2022 (Robust stats, Algorithm A, MADe, nIQR) directly in `app.R`.
