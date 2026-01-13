# Quick Start Guide

This guide will get you running the Proficiency Testing Application in under 5 minutes.

---

## System Requirements

| Requirement | Minimum Version | Recommended |
|-------------|-----------------|-------------|
| R | 4.3.0 | 4.4.0 or later |
| RStudio | 2023.06 | 2024.04 or later |
| Operating System | Windows 10+, macOS 11+, Linux | Any modern OS |
| RAM | 4 GB | 8 GB+ |

## Installation

### 1. Install R Packages

Open R or RStudio and run:

```r
install.packages(c(
  "shiny", "bslib", "tidyverse", "vroom", "DT", "rhandsontable",
  "shinythemes", "outliers", "patchwork", "bsplus", "plotly", "rmarkdown", "devtools"
))
```

### 2. Install the ptcalc Package

The application requires the `ptcalc` package for ISO 13528/17043 calculations.

```r
# From the application directory:
devtools::load_all("ptcalc")
```

For production deployment:

```r
devtools::install("ptcalc")
```

---

## Launching the Application

### Method 1: From R/RStudio

```r
shiny::runApp("cloned_app.R")
```

The application will open in your default web browser at `http://127.0.0.1:3838`.

### Method 2: Command Line

```bash
R -e "shiny::runApp('cloned_app.R')"
```

---

## Loading Example Data (First Analysis)

### Step 1: Upload Homogeneity Data

1. Navigate to the **Carga de Datos** section
2. Click **Browse** under "Archivo de Homogeneidad"
3. Select `data/homogeneity.csv` from the project directory

Example homogeneity data format:

```csv
pollutant,level,replicate,sample_id,value
so2,20-nmol/mol,1,1,19.70
so2,20-nmol/mol,1,2,19.72
so2,20-nmol/mol,2,1,19.68
```

### Step 2: Upload Stability Data

1. Click **Browse** under "Archivo de Estabilidad"
2. Select `data/stability.csv`

### Step 3: Upload Participant Data

1. Click **Browse** under "Datos de Participantes"
2. Select a participant data file (e.g., `data/participants_data.csv`)

Example participant data format:

```csv
Codigo_Lab,Analizador_SO2,Analizador_CO,Analizador_O3,Analizador_NO_NO2
REFERENCIA,HORIBA APSA-370,Teledyne T300,Thermo 49i,HORIBA APSA-370
PART1,20.1,2.05,120.3,30.2
PART2,19.8,2.03,119.8,29.9
```

---

## Running Your First Analysis

### Homogeneity Assessment

1. After uploading data, go to **Homogeneidad** tab
2. Select a pollutant (e.g., `so2`)
3. Select a concentration level (e.g., `20-nmol/mol`)
4. Click **Ejecutar Análisis**
5. Review results:
   - ANOVA table
   - Homogeneity criteria evaluation
   - Visual plots

### Stability Assessment

1. Go to **Estabilidad** tab
2. Select pollutant and level
3. Click **Ejecutar Análisis**
4. Review t-test results and plots

### Assigned Value Calculation

1. Go to **Valor Asignado** tab
2. Choose calculation method:
   - **Media Robusta**: Uses robust statistics (Algorithm A)
   - **Consenso**: Median of all participants
3. Click **Calcular Valor Asignado**

### PT Scores

1. Go to **Puntajes PT** tab
2. Select score type:
   - **z**: Standard z-score
   - **z'**: Robust z-score
   - **ζ (zeta)**: Zeta score with uncertainty
   - **En**: Normalized error score
3. View participant performance results

---

## Troubleshooting

### Error: "Error: El archivo de homogeneidad debe contener las columnas..."

**Solution**: Ensure your CSV file has the required columns:
- `pollutant`
- `level`
- `value`
- (optional) `replicate`, `sample_id`

### Application won't start

**Solution**: Check that all dependencies are installed:

```r
required_packages <- c("shiny", "bslib", "tidyverse", "vroom", "DT", "rhandsontable",
                       "shinythemes", "outliers", "patchwork", "bsplus", "plotly",
                       "rmarkdown", "devtools", "dplyr", "stats")
missing <- setdiff(required_packages, rownames(installed.packages()))
if (length(missing) > 0) install.packages(missing)
```

### ptcalc package not found

**Solution**: Run from the project root directory:

```r
setwd("/path/to/pt_app")
devtools::load_all("ptcalc")
```

---

## Next Steps

- Review full documentation: [README.md](README.md)
- Learn about data formats: See `cloned_docs/01_carga_datos.md`
- Understand PT calculations: See `cloned_docs/03_pt_robust_stats.md`

---

## Support

For issues or questions:
- Check the troubleshooting section above
- Review the detailed module documentation
- Contact: Laboratorio CALAIRE, Universidad Nacional de Colombia
