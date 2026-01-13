# Quick Start Guide: PT Data Analysis Application

## 1. System Requirements & Installation

Before you begin, ensure your system meets the following requirements:

*   **R Version**: R 4.0.0 or higher is recommended.
*   **Operating System**: Windows, macOS, or Linux.
*   **Web Browser**: Modern browser (Chrome, Firefox, Edge, Safari).

### Step-by-Step Installation

1.  **Install R**: Download and install R from [CRAN](https://cran.r-project.org/).
2.  **Install RStudio (Optional but Recommended)**: Download from [Posit](https://posit.co/download/rstudio-desktop/).
3.  **Install Dependencies**: Open R or RStudio and run the following code to install all necessary packages:

    ```r
    install.packages(c(
      "shiny",
      "tidyverse",
      "vroom",
      "DT",
      "rhandsontable",
      "shinythemes",
      "outliers",
      "patchwork",
      "bsplus",
      "plotly",
      "rmarkdown",
      "bslib",
      "devtools" # Required for loading the local package
    ))
    ```

4.  **Install Local Package**: The application relies on the local `ptcalc` package.
    ```r
    # Run this from the project root directory
    devtools::install("ptcalc")
    ```

## 2. Launching the Application

You can launch the application using one of the following methods:

**Method A: From R Console (Recommended)**
```r
setwd("/path/to/pt_app")
shiny::runApp("cloned_app.R")
```

**Method B: Command Line**
```bash
Rscript cloned_app.R
```
*Note: Look for the URL in the terminal output (usually `http://127.0.0.1:XXXX`) and open it in your browser.*

## 3. Loading Example Data

To perform your first analysis, you need data files. We provide example files in the `data/` directory.

1.  Navigate to the **"Carga de datos"** (Data Loading) module in the app sidebar.
2.  **Homogeneity File**: Upload `data/homogeneity.csv`.
3.  **Stability File**: Upload `data/stability.csv`.
4.  **Summary Files**: Upload all `summary_n*.csv` files found in `data/`. You can select multiple files at once.

*Tip: If the app shows "File uploaded successfully" in green, you are ready to proceed.*

## 4. First Analysis in 5 Minutes

Follow this path to generate your first homogeneity report:

1.  **Select Module**: Click on **"Homogeneity & Stability Analysis"** in the left navigation panel.
2.  **Configure Parameters**:
    *   **Pollutant**: Select `SO2`.
    *   **Level**: Select `low`.
3.  **Run Analysis**: Click the **"Run Analysis"** button.
4.  **View Results**:
    *   Check the **"Variance Components"** tab for $s_{s}$ and $s_{w}$ values.
    *   Look at the **"Homogeneity Conclusion"** box. It should display "PASS" or "FAIL" based on ISO 13528 criteria.
5.  **Check Stability**: Click **"Run Stability Analysis"** (if available) to compare homogeneity vs. stability means.

Congratulations! You have completed your first PT assessment cycle.
