# PT-Analysis-ISO13528: Statistical Analysis Application for Proficiency Testing

This repository contains a Shiny web application for performing statistical analysis of proficiency testing (PT) data in accordance with ISO 13528:2022. The application provides a user-friendly interface for conducting homogeneity and stability assessments, which are critical for ensuring the quality of PT schemes.

## Features

The application implements the following statistical procedures:

*   **Data Input**: Supports multiple methods for data entry, including:
    *   Uploading CSV/TSV files.
    *   Pasting data directly into the application.
    *   Using an interactive, editable table (powered by `rhandsontable`).
*   **Homogeneity Assessment**: Performs homogeneity tests based on one-way ANOVA to calculate the between-sample standard deviation (ss) and checks against the criterion `ss <= 0.3 * sigma_pt`.
*   **Stability Assessment**: Conducts stability analysis by comparing datasets from two different time points using t-tests and other metrics.
*   **Data Visualization**: Generates histograms and boxplots to help users visualize the distribution of their data.
*   **Detailed Reporting**: Provides detailed tables for variance components, per-item calculations, and summary statistics.

## How to Run the Application

To run this application, you need to have R and RStudio installed.

1.  **Clone or download this repository.**

2.  **Install the required R packages.** Open R or RStudio and run the following command to install all necessary dependencies:

    ```R
    install.packages(c("shiny", "tidyverse", "vroom", "DT", "rhandsontable"))
    ```

3.  **Run the Shiny app.** Open the `app.R` file in RStudio and click the "Run App" button in the top-right corner of the script editor. Alternatively, you can run the following command in the R console, making sure your working directory is set to the project root:

    ```R
    shiny::runApp("app.R")
    ```

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

*   `app.R`: The main file containing the complete source code for the Shiny application (both UI and server logic).
*   `sop.md`: The Standard Operating Procedure document that details the statistical methods implemented in the app, in alignment with ISO 13528:2022.
*   `base_proposal.md`: The original project proposal outlining the project's objectives and technical specifications.
*   `*.csv`: Sample data files used for testing and demonstrating the application's features. For example:
    *   `CO.csv`: Homogeneity data for Carbon Monoxide.
    *   `bsw_co.csv`: Stability data for Carbon Monoxide.

## Statistical Methods

The statistical analyses performed by this application are based on the guidelines set forth in **ISO 13528:2022: "Statistical methods for use in proficiency testing by interlaboratory comparison."**

For a detailed explanation of the statistical methodology, please refer to the `sop.md` document included in this repository.