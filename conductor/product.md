# Product Guide: PT Data Analysis Application

## 1. Initial Concept
This Shiny application provides a comprehensive toolkit for analyzing data from proficiency testing (PT) schemes, implementing statistical methods from ISO 13528:2022.

## 2. Target Users
The primary users of this application are:
*   **PT Scheme Coordinators:** Individuals responsible for managing and overseeing proficiency testing schemes.
*   **Statistical Analysts in Laboratories:** Professionals who analyze data within testing or calibration laboratories.
*   **Quality Assurance Managers:** Personnel ensuring quality standards are met within laboratory operations.

## 3. Core Goals
The application aims to facilitate the following key objectives:
*   **Assess Item Quality:** Evaluate the homogeneity and stability of proficiency testing items to ensure their suitability.
*   **Evaluate Performance:** Calculate and visualize standard participant performance scores, including z-scores, z'-scores, zeta-scores, and En-scores.
*   **Report Generation:** Produce comprehensive proficiency testing reports that comply with ISO 13528:2022 standards.
*   **Outlier Detection:** Identify statistical outliers within the dataset to ensure data integrity.
*   **Parameter Calculation:** Calculate the assigned value ($x_{pt}$) and the standard deviation for proficiency assessment ($\sigma_{pt}$) using various robust methods (Reference values, MADe, nIQR, Algorithm A).

## 4. Key Features
To achieve these goals, the application includes:
*   **Interactive Dashboard:** A user-friendly interface for conducting Homogeneity, Stability, and Performance Analysis.
*   **Dynamic Reporting:** The ability to generate customizable reports in Word format.
*   **Robust Statistical Engine:** Implementation of advanced algorithms (Algorithm A, MADe, nIQR) for accurate calculation of $x_{pt}$ and $\sigma_{pt}$.
*   **Visualization Tools:** Capabilities to calculate performance scores and create visual representations of the data for easier interpretation.
