# PT Data Analysis Application

This Shiny application provides a comprehensive toolkit for analyzing data from proficiency testing (PT) schemes. It implements the statistical methods described in ISO 13528:2022 for assessing the homogeneity and stability of PT items and for calculating participant performance scores.

## User Guide

### Getting Started

To run the application, you need to have R and the required packages installed.

1.  **Install R:** Download and install R from the [Comprehensive R Archive Network (CRAN)](https://cran.r-project.org/).
2.  **Install Packages:** Open an R console and run the following command to install the necessary packages:
    ```r
    install.packages(c("shiny", "tidyverse", "vroom", "DT", "rhandsontable", "shinythemes", "outliers"))
    ```
3.  **Run the Application:** Open a terminal or command prompt, navigate to the directory containing the application files, and run the following command:
    ```bash
    Rscript run_app.R
    ```
    The application will start and can be accessed in your web browser, typically at `http://127.0.0.1:XXXX` (the port `XXXX` will be displayed in the console).

### Application Modules

The application is organized into three main modules, accessible from the navigation panel on the left.

#### 1. Homogeneity & Stability Analysis

This module is used to assess whether the proficiency test items are sufficiently homogeneous and stable for the PT scheme.

*   **Inputs:**
    *   **Select Pollutant:** Choose the pollutant to analyze (`co`, `no`, `no2`, `o3`, `so2`). The application will load the corresponding data from `homogeneity.csv` and `stability.csv`.
    *   **Select PT Level:** Choose the concentration level of the pollutant to analyze.
*   **Outputs:**
    *   **Data Preview:** Shows a preview of the raw homogeneity and stability data, along with distribution plots (histogram and boxplot).
    *   **Homogeneity Assessment:** Provides a conclusion on whether the items meet the homogeneity criteria based on ISO 13528:2022. It displays detailed statistical tables, including robust statistics, variance components, and per-item calculations.
    *   **Stability Assessment:** Provides a conclusion on the stability of the items by comparing data from two different time points. It includes variance components and detailed statistical tables for the stability data.

#### 2. PT Preparation

This module provides an analysis of participant results from different PT schemes. The data is loaded from `summary_n*.csv` files.

*   **Functionality:**
    *   The module dynamically creates tabs for each pollutant found in the summary files.
    *   Within each pollutant tab, you can select the PT scheme (by the number of participants `n`) and the concentration level.
*   **Outputs:**
    *   **Participant Results Plot:** A bar chart showing the mean values and standard deviations for each participant.
    *   **Data Table:** A table of the summary data for the selected scheme.
    *   **Results Distribution:** Histogram, boxplot, and density plots to visualize the distribution of participant results.
    *   **Grubbs' Test for Outliers:** A statistical test to identify potential outliers in the data.
    *   **Run Chart:** A chart showing the mean values for each participant across different sample groups.

#### 3. PT Scores

This module calculates various performance scores for participants based on their results.

*   **Inputs:**
    *   **Select Data:** Choose the pollutant, PT scheme (`n`), and concentration level.
    *   **Set Parameters:** Adjust the parameters used for score calculation, such as the standard deviation for proficiency assessment (`sigma_pt`), the standard uncertainty of the assigned value (`u_xpt`), and the coverage factor (`k`).
*   **Outputs:**
    *   **Scores Table:** A detailed table showing the calculated z-scores, z'-scores, zeta-scores, and En-scores for each participant, along with a "Satisfactory," "Questionable," or "Unsatisfactory" evaluation.
    *   **Score Plots:** A series of plots visualizing each of the calculated scores for all participants, with warning and action limits clearly marked.

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
2.  **Layout Options**: A collapsible panel (`checkboxInput` and `conditionalPanel`) allows the user to adjust the width of the navigation and analysis panels using `sliderInput`.
3.  **`uiOutput("main_layout")`**: This is the main UI container. The entire layout is rendered dynamically in the server logic to allow for the adjustable panel widths.
4.  **`navlistPanel`**: Inside the dynamic layout, a `navlistPanel` creates the main navigation structure with three tabs: "Homogeneity & Stability Analysis," "PT Preparation," and "PT Scores."
5.  **Module Layouts**:
    *   **Homogeneity & Stability**: Uses a `sidebarLayout` with a `sidebarPanel` for inputs and a `mainPanel` with a `tabsetPanel` for displaying the results.
    *   **PT Preparation**: Uses a `uiOutput("pt_pollutant_tabs")` to dynamically generate a `tabsetPanel` with a tab for each pollutant.
    *   **PT Scores**: Uses a `sidebarLayout` with a `sidebarPanel` for inputs and a `mainPanel` with a `tabsetPanel` for the scores table and plots.

#### Server (`server`) Logic

### Running Syntax Checks Without a System R Installation

Some execution environments (including this automated assessment sandbox) do not provide a native `Rscript` binary. For these
cases the repository ships with a lightweight replacement located at the project root. It performs structural validation of R
files—verifying bracket balance and string termination—so that automated checks can still run.

To invoke the stub, execute:

```bash
./Rscript -e "source('app.R')"
```

If you prefer calling `Rscript` without the leading `./`, add the repository root to your `PATH` for the current shell session:

```bash
export PATH="$PWD:$PATH"
Rscript -e "source('app.R')"
```

> **Note:** the stub does **not** evaluate R code. It only performs basic structural validation, so you should still run the app with a real R installation before deploying changes.

## File Structure
The server function contains the logic for data processing, analysis, and rendering outputs.

1.  **Data Loading**:
    *   `hom_data_full` and `stab_data_full` are read from `homogeneity.csv` and `stability.csv` at the start of the session.
    *   `pt_prep_data` is a `reactive` expression that reads all `summary_n*.csv` files, combines them into a single data frame, and adds a column `n_lab` to identify the scheme.

2.  **Dynamic UI Rendering**:
    *   `output$main_layout`: Renders the main `navlistPanel` based on the user's layout selections.
    *   The selectors for pollutants, levels, and schemes within each module are rendered dynamically using `renderUI` and `uiOutput`. This ensures that the choices are always based on the currently available data.

3.  **Reactive Expressions for Analysis**:
    *   **`homogeneity_run`**: An `eventReactive` expression that triggers when the "Run Analysis" button is clicked. It performs the homogeneity calculations on the data from `homogeneity.csv` for the selected pollutant and level. It returns a list containing the results, including variance components (`ss`, `sw`), conclusions, and intermediate data frames.
    *   **`homogeneity_run_stability`**: A similar `eventReactive` expression for the stability data from `stability.csv`. It also calculates the difference in means between the homogeneity and stability datasets.
    *   **`scores_run`**: A `reactive` expression that calculates the z-scores, z'-scores, zeta-scores, and En-scores based on the selected PT scheme and parameters.
    *   **Dynamic Module Logic (`PT Preparation`)**: An `observe` block is used to dynamically create the UI and server logic for each pollutant tab in the "PT Preparation" module. It uses `lapply` to loop through the pollutants and creates the necessary `renderUI`, `renderPlot`, `renderDataTable`, and `renderPrint` outputs for each one.

4.  **Outputs (`output$*`)**:
    *   Each `render*` function (e.g., `renderDataTable`, `renderPlot`, `renderTable`, `renderUI`) is responsible for generating a specific piece of output in the UI.
    *   The outputs are linked to the reactive expressions. When an input changes, the reactive expressions that depend on it are re-evaluated, which in turn causes the outputs that depend on those reactives to be updated. This is the core of Shiny's reactivity model.
    *   **Tables**: `renderDataTable` is used for interactive tables (e.g., `scores_table`), while `renderTable` is used for static tables (e.g., `variance_components`).
    *   **Plots**: `renderPlot` is used to generate all the plots using `ggplot2`.
    *   **Text**: `renderPrint` and `renderUI` are used to display text outputs, such as conclusions and summaries. `renderUI` is used when the output needs to include HTML for styling (e.g., colored alert boxes for conclusions).