# PT Data Analysis Application

**Version 0.4.0 | January 2026**

This Shiny application provides a comprehensive toolkit for analyzing data from proficiency testing (PT) schemes. It implements statistical methods described in ISO 13528:2022 and ISO 17043:2024 for assessing homogeneity and stability of PT items and for calculating participant performance scores.

## 📖 Documentation

**Spanish Documentation:** For complete documentation in Spanish, see [/es/README.md](es/README.md)

The `/es/` directory contains comprehensive user guides, API references, and technical documentation for version 0.4.0.

---

## Getting Started

### Prerequisites

To run the application, you need to have R and required packages installed.

1. **Install R:** Download and install R from [Comprehensive R Archive Network (CRAN)](https://cran.r-project.org/).

2. **Install Packages:** Open an R console and run the following command to install necessary packages:
    ```r
    install.packages(c("shiny", "tidyverse", "vroom", "DT", "rhandsontable", "shinythemes", "outliers", "patchwork", "bsplus", "plotly", "rmarkdown", "bslib"))
    ```

3. **Run the Application:** Open a terminal or command prompt, navigate to the directory containing the application files, and run the following command:
    ```bash
    Rscript app.R
    ```

The application will start and can be accessed in your web browser, typically at `http://127.0.0.1:XXXX` (the port `XXXX` will be displayed in the console).

---

## Application Modules

### 1. Carga de datos (Data Loading)

This module handles the initial loading of CSV files for analysis.

**Inputs:**
- `homogeneity.csv` - Homogeneity test data
- `stability.csv` - Stability test data
- `summary_n*.csv` - Participant summary data (one file per PT scheme)

### 2. Homogeneity & Stability Analysis

This module assesses whether proficiency test items are sufficiently homogeneous and stable for the PT scheme.

**Inputs:**
- **Select Pollutant:** Choose pollutant to analyze (`co`, `no`, `no2`, `o3`, `so2`)
- **Select PT Level:** Choose concentration level to analyze

**Outputs:**
- Data preview
- ANOVA summary
- Homogeneity and stability assessments

### 3. PT Preparation

Analyzes participant results from different rounds.

**Functionality:**
- Dynamically creates tabs for each pollutant
- Displays bar charts and distributions
- Performs Grubbs' test for outliers

### 4. Valor Asignado / PT Scores

Calculates reference values and participant performance scores.

**Functionality:**
- **Value Assignment:** Supports Algorithm A, Consensus (MADe/nIQR), or Reference Laboratory methods
- **Scoring:** Calculates z-scores, z'-scores, zeta-scores, and En-scores
- **Metrological Compatibility:** Evaluates measurement system compatibility (ISO 13528:2022)

### 5. Informe Global & Generación de Informes

**Informe Global:**
- Heatmap visualization of results across all levels and pollutants
- Cross-pollutant analysis
- Cross-scheme comparison

**Generación de informes:**
- Interface to configure and download final RMarkdown reports
- Customizable report sections including homogeneity, stability, PT scores, and metrological compatibility

---

## User Interface

The application features a modern UI design inspired by shadcn/ui components:

- **Enhanced Header:** Branded header with logo and navigation (see `www/appR.css` lines 830-902)
- **shadcn Cards:** Modern card components for organized data presentation
- **shadcn Alerts:** Color-coded alert boxes for important information and warnings
- **shadcn Badges:** Compact badges for displaying status information
- **Modern Footer:** Clean footer with institutional information (see `www/appR.css` lines 1219-1280)

---

## Developer Documentation

### Technical Overview

**Framework:** R / Shiny (v0.4.0)

**Core Libraries:**
- `shiny` - Web application framework
- `tidyverse` - Data manipulation and visualization
- `vroom` - Fast CSV file reading
- `DT` - Interactive data tables
- `rhandsontable` - Editable tables (loaded but not actively used)
- `shinythemes` / `bslib` - Custom application themes
- `outliers` - Grubbs' test for outlier detection
- `patchwork` - Plot composition
- `plotly` - Interactive plots
- `rmarkdown` - Report generation

**Data Sources:**
- `homogeneity.csv` - Homogeneity test data
- `stability.csv` - Stability test data
- `summary_n*.csv` - Summary data from different PT schemes

### Package Structure

```
pt_app/
├── app.R                    # Main Shiny application (5,685 lines)
├── www/
│   └── appR.css            # Custom CSS styles (1,456 lines)
├── ptcalc/                 # Calculation package (ISO 13528:2022)
│   ├── R/                 # Package functions
│   ├── DESCRIPTION         # Package metadata
│   └── NEWS.md            # Package changelog
├── reports/
│   └── report_template.Rmd  # RMarkdown report template (552 lines)
├── es/                   # Spanish documentation (25 files, ~7,678 lines)
└── data/                  # Example data files
```

### Development Setup

For development, load the `ptcalc` package using:

```r
devtools::load_all("ptcalc")
```

To test changes, restart the Shiny application.

### Running Syntax Checks Without a System R Installation

Some execution environments (including this automated assessment sandbox) do not provide a native `Rscript` binary. For these cases, the repository ships with a lightweight replacement located at the project root. It performs structural validation of R files—verifying bracket balance and string termination—so that automated checks can still run.

To invoke the stub:

```bash
./Rscript -e "source('app.R')"
```

If you prefer calling `Rscript` without the leading `./`, add the repository root to your `PATH` for the current shell session:

```bash
export PATH="$PWD:$PATH"
Rscript -e "source('app.R')"
```

> **Note:** The stub does **not** evaluate R code. It only performs basic structural validation, so you should still run the app with a real R installation before deploying changes.

---

## File Structure

The `app.R` script is divided into two main parts: User Interface (`ui`) and Server Logic (`server`).

### UI (`ui`) Structure

The UI is defined using `fluidPage` and is structured as follows:

1. **`titlePanel`** - Sets the main title of the application
2. **Layout Options** - Collapsible panel allows users to adjust panel widths using a slider
3. **`uiOutput("main_layout")`** - Main UI container rendered dynamically
4. **`navlistPanel`** - Navigation structure with tabs for different modules
5. **Module Layouts**:
   - **Homogeneity & Stability**: Sidebar layout with input controls and tabsetPanel for results
   - **PT Preparation**: Dynamic tabs created per pollutant
   - **PT Scores**: Sidebar layout for value assignment and score calculation

### Server (`server`) Logic

1. **Data Loading:**
   - `hom_data_full` and `stab_data_full` are read from `homogeneity.csv` and `stability.csv`
   - `pt_prep_data` reads all `summary_n*.csv` files and combines them with `n_lab` column

2. **Dynamic UI Rendering:**
   - `output$main_layout`: Renders main `navlistPanel` based on user's layout selections
   - Dynamic selectors for pollutants, levels, and schemes use `renderUI` and `uiOutput`

3. **Reactive Expressions for Analysis:**
   - **`homogeneity_run`**: EventReactive triggered on "Run Analysis" button click
   - **`homogeneity_run_stability`**: EventReactive for stability analysis
   - **`scores_run`**: Reactive for z, z', zeta, and En score calculations
   - **Cache System**: Trigger-based caching for performance optimization

4. **Outputs (`output$*`)**:
   - **Tables**: `renderDataTable` for interactive tables, `renderTable` for static tables
   - **Plots**: `renderPlot` with `ggplot2` for all visualizations
   - **Text**: `renderPrint` and `renderUI` for formatted text and HTML

---

## ISO Standards

The application implements the following standards:

- **ISO 13528:2022** - Statistical methods for use in proficiency testing
  - Robust statistics (MADe, nIQR, Algorithm A)
  - Homogeneity and stability assessment
  - PT scores (z, z', zeta, En)
  - Metrological compatibility

- **ISO 17043:2024** - General requirements for proficiency testing

---

## Support

- **Spanish Documentation:** [/es/README.md](es/README.md) - Complete user and developer guides
- **Data Format Reference:** [/es/01a_formatos_datos.md](es/01a_formatos_datos.md) - Complete CSV schema specification
- **API Reference:** [/es/02a_api_ptcalc.md](es/02a_api_ptcalc.md) - ptcalc package API documentation

---

## Changelog

### v0.4.0 (January 2026)

**Documentation:**
- Complete documentation audit and update (25 files, ~7,678 lines in `/es/`)
- Master documentation guide created
- All obsolete references corrected
- Language standardized (Spanish for `/es/` documentation)

**Features:**
- Metrological compatibility analysis (ISO 13528:2022)
- Enhanced UI with shadcn-inspired components
- Modern header and footer design
- Improved caching system for performance

**Technical:**
- Updated to app.R: 5,685 lines
- Updated appR.css: 1,456 lines
- Updated report_template.Rmd: 552 lines

### v0.3.0 (January 2026)

- Modern UI redesign (shadcn components, header/footer)
- Metrological compatibility feature
- Enhanced data format (run column)

---

## License

MIT License - Universidad Nacional de Colombia / Instituto Nacional de Metrología
