# 14. Report Template: report_template.Rmd

| Property | Value |
|----------|-------|
| **Document Type** | RMarkdown Report Template Reference |
| **File** | `reports/report_template.Rmd` |
| **Lines** | 558 |
| **Format** | YAML + R chunks + Markdown |
| **Related Docs** | `12_generacion_informes.md`, `05_pt_scores.md`, `04_pt_homogeneity.md` |

---

## 1. Overview

The `report_template.Rmd` file is an RMarkdown template for automatic generation of proficiency testing (PT) reports. It implements ISO/IEC 17043:2023 report structure with ISO 13528:2022 statistical methods.

### Key Features
- **Multi-format Output**: Word, HTML, and PDF support
- **Dynamic Content**: Parameter-driven sections and tables
- **PT Theme Styling**: Custom CSS matching the application design
- **Comprehensive Analysis**: Homogeneity, stability, scoring, and metrological compatibility
- **Per-Participant Results**: Individual performance matrices and summaries

> **Note:** Screenshots and figures in this documentation should be updated to reflect the current report design with metrological compatibility section and enhanced participant data handling.

---

## 2. File Location

```
pt_app/
└── reports/
    └── report_template.Rmd    # Main report template (558 lines)
```

---

## 3. Parameters (YAML Header)

The template accepts numerous parameters for customization:

### 3.1 Core Data Parameters

```yaml
params:
  # Raw data inputs
  hom_data: NA                    # Homogeneity raw data
  stab_data: NA                   # Stability raw data
  summary_data: NA                # Participant summary data
  
  # Analysis settings
  metric: "z"                     # Score type: z, z', zeta, En
  method: "3"                     # Assignment method: 1, 2a, 2b, 3
  pollutant: NULL                 # Selected pollutant(s)
  level: "level_1"                # Selected level(s)
  n_lab: 7                        # Number of laboratories
  k_factor: 2                     # Coverage factor for uncertainties
```

### 3.2 Identification Parameters

```yaml
params:
  scheme_id: "EA-202X-XX"         # PT scheme identifier
  report_id: "INF-202X-XX"        # Report identifier
  issue_date: NA                  # Report issue date
  period: "Mes - Mes Año"         # PT scheme period
  coordinator: "Nombre"           # EA coordinator name
  quality_pro: "Nombre"           # Quality professional name
  ops_eng: "Nombre"               # Operations engineer name
  quality_manager: "Nombre"       # Quality manager name
```

### 3.3 Data Summary Parameters

```yaml
params:
  participants_data: NA           # Uploaded participant instrument data
  grubbs_summary: NA              # Grubbs test results summary
  xpt_summary: NA                 # Assigned value summary table
  homogeneity_summary: NA         # Homogeneity results summary
  stability_summary: NA           # Stability results summary
  score_summary: NA               # Overall score summary
  heatmaps: NA                    # Pre-generated heatmap plots
  participant_data: NA            # Per-participant detailed data
```

### 3.4 Metrological Compatibility Parameters

```yaml
params:
  metrological_compatibility: NA           # Compatibility data table
  metrological_compatibility_method: "2a"  # Method for comparison: 2a, 2b, 3
```

---

## 4. Report Sections Structure

### 4.1 Section 1: Introduction

| Subsection | Content |
|------------|---------|
| 1.1 Provider & Scheme Info | Scope, objectives, scheme ID |
| 1.2 Confidentiality | Data protection policy |
| 1.3 Key Personnel | Coordinator, engineers, managers |
| 1.4 Participants | Laboratory codes and instrumentation table |

### 4.2 Section 2: Methodology

| Subsection | Content |
|------------|---------|
| 2.1 Test Items | Gas generation methods, concentration levels |
| 2.2 Homogeneity & Stability | Verification methods per ISO 13528 Annex B |
| 2.3 Assigned Value ($x_{pt}$) | Method-specific determination (Reference/Consensus/Algorithm A) |
| 2.4 Metrological Compatibility | **NEW** Comparison between reference and consensus values |

### 4.3 Section 3: Evaluation Criteria

| Subsection | Content |
|------------|---------|
| 3.1 Performance Indicators | z, z', zeta, En formulas and thresholds |
| 3.2 Statistical Treatment | Validation, outlier identification (Grubbs test) |

### 4.4 Section 4: Results and Discussion

| Subsection | Content |
|------------|---------|
| 4.1 General Summary | Overall performance statistics |
| 4.2 Per-Pollutant Results | Heatmaps and detailed tables |

### 4.5 Section 5: Conclusions

General conformity assessment, areas of concern, and recommended actions.

### 4.6 Annexes

| Annex | Content |
|-------|---------|
| Annex A | Assigned values and standard deviations |
| Annex B | Homogeneity and stability summaries |
| Annex C | Per-participant detailed results with matrix plots |

---

## 5. Helper Functions

The template includes standalone helper functions that replicate `ptcalc` logic for report independence:

### 5.1 calculate_niqr()

```r
calculate_niqr <- function(x) {
  x_clean <- x[is.finite(x)]
  if (length(x_clean) < 2) return(NA_real_)
  quartiles <- stats::quantile(x_clean, probs = c(0.25, 0.75), na.rm = TRUE, type = 7)
  0.7413 * (quartiles[2] - quartiles[1])
}
```

**Purpose**: Calculate normalized IQR for robust dispersion estimation.

### 5.2 get_wide_data()

```r
get_wide_data <- function(df, target_pollutant) {
  filtered <- df %>% filter(pollutant == target_pollutant)
  if (nrow(filtered) == 0) return(NULL)
  filtered %>%
    select(-pollutant) %>%
    pivot_wider(names_from = replicate, values_from = value, names_prefix = "sample_")
}
```

**Purpose**: Transform long-format data to wide format for analysis.

### 5.3 run_algorithm_a()

```r
run_algorithm_a <- function(values, max_iter = 50) {
  # Implementation of ISO 13528 Algorithm A
  # Returns: list(mean = x_star, sd = s_star, error = NULL/message)
}
```

**Purpose**: Calculate robust mean and standard deviation using ISO 13528 Algorithm A.

### 5.4 compute_homogeneity()

```r
compute_homogeneity <- function(data_full, pol, lev) {
  # ANOVA-based homogeneity calculation
  # Returns: list(ss, sw, sigma_pt, c_crit, mean, passed)
}
```

**Purpose**: Compute between-sample ($s_s$) and within-sample ($s_w$) standard deviations.

---

## 6. Output Formats

### 6.1 Word Document

```yaml
output:
  word_document:
    toc: true
    toc_depth: 3
    reference_docx: null   # Optional: custom template
```

### 6.2 HTML Document

```yaml
output:
  html_document:
    toc: true
    toc_depth: 3
    toc_float: true        # Floating sidebar navigation
```

Includes custom CSS for PT theme styling (yellow accents, branded links).

### 6.3 PDF Document

```yaml
output:
  pdf_document:
    toc: true
    toc_depth: 3
    latex_engine: pdflatex
```

---

## 7. Custom Styling

The template includes embedded CSS for HTML output:

```css
/* Active TOC items - PT Yellow */
.list-group-item.active {
  background-color: #FDB913 !important;
  border-color: #FDB913 !important;
  color: #111827 !important;
}

/* Title styling */
h1.title {
  border-bottom: 3px solid #FDB913;
  padding-bottom: 10px;
}

/* Link colors */
a { color: #E5A610; }
a:hover { color: #FDB913; }

/* Selection highlight */
::selection {
  background: #FDB913;
  color: #111827;
}
```

---

## 8. Key Dynamic Features

### 8.1 Assigned Value Method Selection

The template automatically adjusts text based on `params$method`:

| Method | Description |
|--------|-------------|
| `"1"` | Reference laboratory value |
| `"2a"` | Consensus (Median + MADe) |
| `"2b"` | Consensus (Median + nIQR) |
| `"3"` | Consensus (Algorithm A) |

### 8.2 Metrological Compatibility

**New Feature**: Section 2.4 displays comparison between reference values and consensus values:

```r
# Dynamic text based on method
if (method == "2a") {
  cat("Differences between x_pt,ref and x_pt,2a...")
} else if (method == "2b") {
  cat("Differences between x_pt,ref and x_pt,2b...")
} else if (method == "3") {
  cat("Differences between x_pt,ref and x_pt,3...")
}
```

The compatibility table shows:
- Pollutant and level
- Reference value
- Consensus value (based on selected method)
- Difference (Ref - Consensus)

### 8.3 Performance Metric Selection

The template adjusts formulas and thresholds based on `params$metric`:

| Metric | Formula | Thresholds |
|--------|---------|------------|
| `z` | $z = \frac{x_i - x_{pt}}{\sigma_{pt}}$ | ≤2.0 Satisfactory, 2-3 Questionable, ≥3 Unsatisfactory |
| `z'` | $z' = \frac{x_i - x_{pt}}{\sqrt{\sigma_{pt}^2 + u(x_{pt})^2}}$ | Same as z |
| `zeta` | $\zeta = \frac{x_i - x_{pt}}{\sqrt{u(x_i)^2 + u(x_{pt})^2}}$ | Same as z |
| `En` | $E_n = \frac{x_i - x_{pt}}{\sqrt{U(x_i)^2 + U(x_{pt})^2}}$ | ≤1.0 Satisfactory, >1.0 Unsatisfactory |

### 8.4 Heatmap Integration

Pre-generated heatmaps are embedded per pollutant:

```r
if (!is.null(params$heatmaps) && length(params$heatmaps) > 0) {
  for (pol in names(params$heatmaps)) {
    cat("\n\n### Results for", toupper(pol), "\n\n")
    print(params$heatmaps[[pol]])
  }
}
```

### 8.5 Per-Participant Results

Annex C iterates through participant data:

```r
for (pid in names(params$participant_data)) {
  p_info <- params$participant_data[[pid]]
  
  # Matrix plot
  print(p_info$matrix_plot)
  
  # Summary table
  print(kable(p_info$summary_table, ...))
  
  cat("\\newpage")  # Page break between participants
}
```

---

## 9. Data Requirements

### 9.1 Required Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `summary_data` | data.frame | Participant results with columns: participant_id, pollutant, level, run, mean_value, n_lab |
| `metric` | character | Score type selection |
| `method` | character | Assignment method |
| `n_lab` | integer | Number of laboratories |

### 9.2 Optional Enhancement Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `participants_data` | data.frame | Instrument information per lab |
| `heatmaps` | named list | Pre-rendered ggplot heatmaps |
| `participant_data` | named list | Per-participant results (matrix_plot, summary_table) |
| `metrological_compatibility` | data.frame | Reference vs consensus comparison |

---

## 10. Customization Guide

### 10.1 Adding a New Section

1. Add content after the appropriate section number
2. Use consistent heading levels (# for main sections, ## for subsections)
3. Wrap dynamic content in R chunks with appropriate options

### 10.2 Modifying Tables

Tables use `kable()` with `kableExtra` for styling:

```r
kable(data, 
      digits = 4, 
      caption = "Table X. Description",
      escape = FALSE)  # Allow HTML in cells
```

### 10.3 Adding New Parameters

1. Add to YAML header under `params:`
2. Reference with `params$param_name`
3. Add conditional handling for NA values

---

## 11. Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| Tables not rendering | NA data | Add null checks: `if (!is.null(params$data))` |
| LaTeX errors in PDF | Special characters | Escape underscores, use `$...$` for math |
| Heatmaps missing | Not passed from app | Verify `params$heatmaps` is populated |
| Wrong column count | Data format mismatch | Check expected vs actual column names |

---

## 12. See Also

- [12_generacion_informes.md](12_generacion_informes.md) - Report generation module documentation
- [05_pt_scores.md](05_pt_scores.md) - Score calculation formulas
- [04_pt_homogeneity.md](04_pt_homogeneity.md) - Homogeneity/stability criteria
- [ISO 13528:2022](https://www.iso.org/standard/78879.html) - Statistical methods for proficiency testing
- [ISO 17043:2023](https://www.iso.org/standard/79919.html) - General requirements for proficiency testing
