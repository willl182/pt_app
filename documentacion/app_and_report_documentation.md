# PT App and Report Template Documentation

## Installation and Environment Setup

1. **Install R**: Use a recent version of R (4.2 or later is recommended) from [CRAN](https://cran.r-project.org/).
2. **Install required packages**: From an R console, install all packages used by both the Shiny app (`app.R`) and the reporting template (`reports/report_template.Rmd`).

   ```r
   install.packages(c(
     "shiny", "tidyverse", "vroom", "DT", "rhandsontable", "shinythemes",
     "outliers", "patchwork", "bsplus", "plotly", "rmarkdown", "knitr",
     "kableExtra"
   ))
   ```

   *`tidyverse` pulls in `dplyr`, `ggplot2`, `readr`, and `purrr`, which are used throughout the calculations; `rmarkdown`, `knitr`, and `kableExtra` are required to render the Word report.*
3. **Run the Shiny app**: From the project root, start the app with the helper script so it binds to an available port locally.

   ```bash
   Rscript run_app.R
   ```

   If your environment lacks a native `Rscript`, use the provided stub (`./Rscript`) for syntax validation or add the repository root to your `PATH` so `Rscript` resolves to the stub.
4. **Render the report template**: To generate a report programmatically, call `rmarkdown::render` and supply the parameters listed in the template header. For example:

   ```r
   rmarkdown::render(
     "reports/report_template.Rmd",
     output_file = "informe_final.docx",
     params = list(
       hom_data = homogeneity_df,
       stab_data = stability_df,
       summary_data = participant_summary,
       pollutant = "so2",
       level = "level_1",
       n_lab = 7
     )
   )
   ```

## Calculations in `app.R`

### Homogeneity assessment

* **Data shaping**: The helper `get_wide_data()` filters the uploaded homogeneity file by pollutant and pivots replicate results into `sample_1`, `sample_2`, etc., columns to align items (rows) with replicates (columns).
* **Variance components**: `compute_homogeneity_metrics()` builds item-level averages and ranges, then derives:
  * `hom_sw`: within-item dispersion computed from replicate ranges.
  * `hom_s_x_bar_sq`: variance of item means, with `hom_ss` as the square root of the between-item component `|s_xt^2 - (sw^2 / 2)|`.
* **Robust dispersion and criteria**: The function uses the first replicate (`sample_1`) to compute a robust median absolute deviation (`mad_e = 1.483 * MAD`) and a normalized IQR. The assigned standard deviation for proficiency (`hom_sigma_pt`) equals `mad_e`; the acceptance threshold is `c_criterion = 0.3 * sigma_pt` with an expanded version that blends allowable variance and within-item dispersion.
* **Conclusions**: Homogeneity passes when `hom_ss` is below both criteria; the routine returns summaries, variance tables, and the raw reshaped data for downstream plots.

### Stability assessment

* **Reuse of homogeneity structure**: `compute_stability_metrics()` applies the same reshaping and variance logic to stability samples.
* **Shift against homogeneity mean**: The stability statistic `diff_hom_stab` compares the stability grand mean against the homogeneity grand mean; this difference is judged against `c_criterion = 0.3 * hom_results$sigma_pt` and its expanded form.
* **Outputs**: The function returns dispersion components (`stab_sw`, `stab_ss`), the difference statistic, and flags indicating whether stability meets the criteria.

### Assigned value and scoring logic

* **Algorithm A (ISO 13528)**: The app applies the iterative weighting routine `run_algorithm_a()` to participant means to obtain a robust assigned value (`x_star`) and dispersion (`s_star`). Weights dampen outliers via `w = 1/u^2` when standardized residuals exceed 1.
* **Consensus σ<sub>pt</sub> options**: Users can choose between robust MAD-based dispersion (`sigma_pt_1`) or a weighted standard deviation (`sigma_pt_2`), both derived from participant summaries and cached for reuse.
* **Performance scores**: The scoring module computes z, z′, zeta, and En metrics per participant using the chosen assigned value (`x_pt`) and proficiency standard deviation (`sigma_pt`). It augments results with warning/action flags for quick interpretation and aggregates scores across levels when requested.

## Calculations in `reports/report_template.Rmd`

### Parameterization and data

The template is fully parameterized through its YAML header (`params:`) so automation scripts can inject homogeneity, stability, and participant summaries along with metadata such as scheme IDs, pollutant, level, and coverage factor `k_factor`.

### Embedded calculation helpers

* **Normalized IQR**: `calculate_niqr()` scales the interquartile range by 0.7413 to mirror the standard deviation of a normal distribution when only quartiles are available.
* **Robust assigned value**: `run_algorithm_a()` replicates ISO 13528 Algorithm A, iteratively recomputing weighted means and standard deviations until convergence or a maximum iteration count.
* **Homogeneity summary**: `compute_homogeneity()` reshapes replicate columns to long form, derives within-item (`sw`) and between-item (`ss`) standard deviations, and reports whether `ss` falls below the critical threshold `c_crit = 0.3 * sigma_pt` (with `sigma_pt` from the first replicate’s MAD).

### Report content

The document uses `knitr` and `kableExtra` to build participant tables, homogeneity and stability summaries, and score overviews. Because the calculations are embedded directly in the template, rendering the report reproduces the same logic as the interactive app, ensuring consistency between the on-screen outputs and the final Word document.
