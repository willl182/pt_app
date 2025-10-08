# PT-Analysis-ISO13528: Statistical Analysis Application for Proficiency Testing

This repository contains a Shiny web application for performing statistical analysis of proficiency testing (PT) data in accordance with ISO 13528:2022. The application provides a user-friendly interface for conducting homogeneity and stability assessments, which are critical for ensuring the quality of PT schemes.

## Features

The application implements the following statistical procedures:

*   **Homogeneity Assessment**: Performs homogeneity tests based on the methods described in ISO 13528:2022, Annex B, to calculate the between-sample standard deviation (`ss`) and check it against the required criteria.
*   **Stability Assessment**: Conducts stability analysis by comparing datasets from two different time points, checking the difference between their means against the criterion `0.3 * sigma_pt`.
*   **Data Visualization**: Generates histograms and boxplots to help users visualize the distribution of their data.
*   **Detailed Reporting**: Provides detailed tables for variance components, per-item calculations, and summary statistics.

## How to Run the Application

To run this application, you need to have R and RStudio installed.

1.  **Clone or download this repository.**

2.  **Install the required R packages.** Open R or RStudio and run the following command to install all necessary dependencies:

    ```R
    install.packages(c("shiny", "tidyverse", "vroom", "DT", "rhandsontable", "shinythemes"))
    ```

3.  **Run the Shiny app.** Open the `app.R` file in RStudio and click the "Run App" button in the top-right corner of the script editor. Alternatively, you can run the following command in the R console, making sure your working directory is set to the project root:

    ```R
    shiny::runApp("app.R")
    ```

## Data Input Format

The application requires data to be provided in two CSV files located in the root directory:

1.  `homogeneity.csv`: Contains the data for the initial homogeneity assessment.
2.  `stability.csv`: Contains the data from a later time point for the stability assessment.

Both files **must** adhere to the following structure (long format):

| pollutant | level | replicate | value     |
| :-------- | :---- | :-------- | :-------- |
| co        | 1     | 1         | 50.1      |
| co        | 1     | 2         | 50.3      |
| co        | 2     | 1         | 101.2     |
| ...       | ...   | ...       | ...       |

**Column Descriptions:**

*   `pollutant` (character): The name of the substance or analyte being measured (e.g., "co", "no2", "so2"). The application uses this to filter the data.
*   `level` (character or numeric): A unique identifier for the concentration level or batch of the PT item.
*   `replicate` (numeric): An identifier for the replicate measurement for a given item (e.g., 1, 2, 3...).
*   `value` (numeric): The measured result.

## File and Code Structure

*   `app.R`: The main file containing the complete source code for the Shiny application. It is organized into three parts:
    *   **I. User Interface (UI)**: Defines the layout and appearance of the application, including all input controls (e.g., dropdowns, buttons) and output placeholders (e.g., plots, tables). It is built using a responsive `fluidPage` layout.
    *   **II. Server Logic**: Contains the computational engine. It uses reactive programming to link user inputs to data processing and analysis. Key calculations are triggered by an `actionButton` and performed within an `eventReactive` expression to ensure the analysis runs only when requested. The server logic is heavily commented, with reactive components labeled for clarity (e.g., `R1`, `R2`).
    *   **III. Application Execution**: A single command that launches the Shiny app.
*   `sop.md`: The Standard Operating Procedure document that details the statistical methods implemented in the app, in alignment with ISO 13528:2022.
*   `base_proposal.md`: The original project proposal outlining the project's objectives and technical specifications.
*   `homogeneity.csv` / `stability.csv`: Sample data files used for testing and demonstrating the application's features. These files contain data for multiple pollutants and levels and serve as an example of the required data format.

## Statistical Methods

The statistical analyses performed by this application are based on the guidelines set forth in **ISO 13528:2022: "Statistical methods for use in proficiency testing by interlaboratory comparison."**

For a detailed explanation of the statistical methodology, please refer to the `sop.md` document included in this repository.