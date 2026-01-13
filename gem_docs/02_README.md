# PT Data Analysis Application

This Shiny application provides a comprehensive toolkit for analyzing data from proficiency testing (PT) schemes. It implements the statistical methods described in ISO 13528:2022 for assessing the homogeneity and stability of PT items and for calculating participant performance scores.

![Application Screenshot](docs/images/app_screenshot_placeholder.png)
*Figure 1: Overview of the PT Data Analysis Application Dashboard*

## User Guide

For a step-by-step installation walkthrough and a deeper explanation of how the app and report template calculate homogeneity, stability, and participant scores, see the documentation in `gem_docs/` and `cloned_docs/`.

**Key Documentation:**
*   **Quick Start**: `gem_docs/00_quickstart.md`
*   **Calculations**: `DOCUMENTACION_CALCULOS.md`
*   **Technical Specs**: `TECHNICAL_DOCUMENTATION.md`
*   **Glossary**: `gem_docs/00_glossary.md`

### Getting Started

#### Prerequisites
To run the application, you need to have R (version 4.0.0+) and the required packages installed.

1.  **Install R:** Download and install R from the [Comprehensive R Archive Network (CRAN)](https://cran.r-project.org/).
2.  **Install Packages:** Open an R console and run the following command to install the necessary packages:
    ```r
    install.packages(c("shiny", "tidyverse", "vroom", "DT", "rhandsontable", "shinythemes", "outliers", "patchwork", "bsplus", "plotly", "rmarkdown", "bslib"))
    ```

#### Running the App
You can run the application directly from the R console or the command line.

**Option 1: From R Console**
```r
shiny::runApp("cloned_app.R")
```

**Option 2: From Terminal**
```bash
Rscript cloned_app.R
```
The application will start and can be accessed in your web browser, typically at `http://127.0.0.1:XXXX`.

### Example Data
Example data files are included in the `data/` directory to help you test the application immediately.
*   **Homogeneity**: `data/homogeneity.csv`
*   **Stability**: `data/stability.csv`
*   **Participant Results**: `data/summary_n*.csv`

See `gem_docs/00_quickstart.md` for a 5-minute tutorial on using this data.

### Application Modules

#### 1. Carga de datos
This module handles the initial loading of CSV files for analysis.
*   **Inputs:** `homogeneity.csv`, `stability.csv`, and `summary_n*.csv` files.
*   **Validation:** Checks for required columns (`value`, `pollutant`, `level`).

#### 2. Homogeneity & Stability Analysis
This module is used to assess whether the proficiency test items are sufficiently homogeneous and stable for the PT scheme.
*   **Inputs:**
    *   **Select Pollutant:** Choose the pollutant to analyze (`co`, `no`, `no2`, `o3`, `so2`).
    *   **Select PT Level:** Choose the concentration level to analyze.
*   **Outputs:** Data preview, ANOVA summary, homogeneity and stability assessments ($s_s$, $s_w$, ISO criteria check).

#### 3. PT Preparation
Analyzes participant results from different rounds.
*   **Functionality:** Dynamically creates tabs for each pollutant.
*   **Outputs:** Bar charts, distributions, and Grubbs' test for outliers.

#### 4. Valor Asignado / PT Scores
Calculates reference values and participant performance scores.
*   **Functionality:**
    *   **Value Assignment:** Supports Algorithm A, Consensus (MADe/nIQR), or Reference laboratory.
    *   **Scoring:** Calculates z, z', zeta, and En scores using robust statistics.
    *   **Uncertainty:** Incorporates standard uncertainty of the assigned value ($u(x_{pt})$).

#### 5. Informe Global & Generación de Informes
*   **Informe Global:** Heatmap visualization of results across all levels and pollutants.
*   **Generación de informes:** Interface to configure and download the RMarkdown final report.

## Troubleshooting

### Common Errors

**1. "Error: El archivo... debe contener las columnas..."**
*   **Cause:** The uploaded CSV file has incorrect headers.
*   **Solution:** Ensure your CSV headers exactly match: `value`, `pollutant`, `level` (case-sensitive).

**2. "disconnected from the server"**
*   **Cause:** The R session crashed, often due to a syntax error or memory issue.
*   **Solution:** Check the R console/terminal for error logs. Restart the app.

**3. "there is no package called..."**
*   **Cause:** Missing dependencies.
*   **Solution:** Run the `install.packages(...)` command listed in the Prerequisites section.

**4. Plots not rendering**
*   **Cause:** `ggplot2` or `plotly` might be missing or conflicting.
*   **Solution:** Update your packages: `update.packages()`.

## Developer Documentation

### Technical Overview

*   **Framework:** R / Shiny
*   **Core Libraries:**
    *   `shiny`: Web application framework.
    *   `tidyverse`: Data manipulation and visualization.
    *   `DT`: Interactive data tables.
    *   `rhandsontable`: Not actively used in the current version, but loaded.
    *   `shinythemes`: For custom application themes.
    *   `outliers`: For the Grubbs' test.
*   **Data Sources:**
    *   `homogeneity.csv`: Data for homogeneity analysis.
    *   `stability.csv`: Data for stability analysis.
    *   `summary_n*.csv`: Summary data from different PT schemes.

### `app.R` Deep Dive

The `app.R` script is divided into two main parts: the User Interface (`ui`) and the Server Logic (`server`).

#### UI (`ui`) Structure
The UI is defined using `fluidPage` and is structured as follows:
1.  **`titlePanel`**: Sets the main title of the application.
2.  **Layout Options**: A collapsible panel allows the user to adjust the width of the navigation and analysis panels.
3.  **`uiOutput("main_layout")`**: Main UI container rendered dynamically.
4.  **`navlistPanel`**: Main navigation structure.

#### Server (`server`) Logic
The server function contains the logic for data processing, analysis, and rendering outputs.
1.  **Data Loading**: `hom_data_full` and `stab_data_full` are read from CSVs.
2.  **Reactive Expressions**:
    *   `homogeneity_run`: Performs ANOVA and ISO calculations.
    *   `scores_run`: Calculates z-scores and other metrics.
3.  **Outputs**: `renderDataTable`, `renderPlot`, etc., update the UI based on reactive states.

### Running Syntax Checks
To run basic syntax checks without a full R environment (e.g., in CI/CD):
```bash
./Rscript -e "source('cloned_app.R')"
```

## Contribution Guidelines

We welcome contributions to improve this application!

1.  **Fork the repository**.
2.  **Create a feature branch**: `git checkout -b feature/NewFeature`.
3.  **Commit your changes**: `git commit -m 'Add some feature'`.
4.  **Push to the branch**: `git push origin feature/NewFeature`.
5.  **Open a Pull Request**.

Please ensure your code follows the existing style (tidyverse style guide recommended) and includes comments for complex logic.

---
*Developed by UNAL/INM - Laboratorio CALAIRE*
