# **Technology Stack**

This document defines the technical architecture, programming languages, and specific libraries selected for the development of the Proficiency Testing (PT) analysis application.

## **1\. Core Technologies**

The development foundation centers on the R ecosystem to ensure the statistical accuracy required by ISO standards.

* **Programming Language:** **R** (Latest stable version). Selected for its robustness in statistics and data analysis.  
* **Web Framework:** **Shiny** (v1.7.0+). Used to build the interactive web application, allowing for local reactive execution.  
* **Reporting Engine:** **R Markdown** / **knitr**. Configured primarily for the automated generation of Microsoft Word (.docx) reports, facilitating subsequent editing by the user.

## **2\. Data Processing and Manipulation**

Performance in file reading and modern syntax for data manipulation are prioritized.

* **Data Manipulation:** tidyverse (including dplyr, tidyr, purrr). Industry standard for data cleaning and transformation.  
* **High-Performance I/O:** vroom. Implemented for ultra-fast reading of large participant datasets.

## **3\. Visualization and Presentation**

A combination of high-quality static charts for reports and interactive visualizations for on-screen exploration.

* **Static Charts:** ggplot2. The base for generating high-quality vector graphics included in downloadable reports.  
* **Interactive Charts:** plotly. Allows users to zoom, filter, and dynamically explore data on the dashboard.  
* **Chart Composition:** patchwork. Used to combine multiple charts into complex layouts (e.g., homogeneity \+ stability panels).  
* **Interactive Tables:** DT (R interface to DataTables). Enables pagination, search, and sorting of large result tables.

## **4\. User Interface (UI) and Experience (UX)**

Components selected to offer a professional, clean, spreadsheet-like experience.

* **Visual Themes:** shinythemes. Provides a clean and professional aesthetic (e.g., 'flatly' theme or similar) based on Bootstrap.  
* **Data Entry:** rhandsontable. A critical component offering Excel-like editable grids, allowing users to copy and paste data directly from their spreadsheets.  
* **UI Enhancements:** bsplus. Extends Bootstrap functionality for advanced modals, tooltips, and accordions.

## **5\. Statistical Analysis and Algorithms**

Specialized libraries to comply with ISO 13528:2022 standards.

* **Outlier Detection:** outliers. Specifically for the implementation of Grubbs' test and other outlier tests.  
* **Internal ISO 13528 Engine:** Custom logic implemented in app.R for robust algorithms where standard libraries do not cover the specific requirements of the standard (e.g., Iterative Algorithm A, MADe, nIQR).