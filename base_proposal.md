

# **Development Proposal: Statistical Application for Proficiency Testing in Compliance with ISO 17043:2023 and ISO 13528:20233**

Subject: Technical development plan for a statistical analysis application in R/Shiny.  
Duration: 8 weeks.  
Responsible: Wilson Rafael Salas Chávez  
Reference Standard: ISO 17043:2023 \- ISO 13528:2022

### **1\. Executive Summary**

This document presents the technical plan for the development of a statistical application in R and Shiny, designed to automate and standardize the analysis of proficiency testing data. The system will rigorously implement the statistical methods stipulated in ISO 17043:2023 and ISO 13528:2022 standards, ensuring the validity and traceability of the assessments, as well as the corresponding reporting of results.

The goal is to build a tool that encompasses everything from test item validation to participant performance evaluation and report generation, providing a robust solution for proficiency testing management.

### **2\. Project Objectives**

The development will focus on implementing a workflow that meets the following technical objectives:

1. **Validation of Test Items:**Implement statistical procedures for verifying homogeneity and stability.  
2. **Participant Data Analysis:**Build an analysis engine that determines assigned value, identifies outliers, and calculates performance indicators.  
3. **Results Display:**Generate the graphical representations required for exploratory analysis and presentation of results.  
4. **Report Generation:**Automate the creation of preliminary, dynamic, and exportable technical reports.

### **3\. Functional Modules and Technical Breakdown**

The application will be structured into functional modules, with particular emphasis on the robustness of the statistical analysis engine.

#### **3.1. Data Entry and Validation Module**

* Interface for data import.  
* Validation routines for data structure and type.  
* Management of round metadata (identifiers, units, etc.).

#### **3.2. Test Item Verification Module (Preliminary Analysis)**

This module is critical to ensure that performance evaluation is not affected by test item variability.

* **Homogeneity Tests (ISO 13528, Annex B):**  
  * Implementation of one-way ANOVA to calculate the standard deviation between samples (ss).  
  * Acceptance criterion: ss \<= 0.3 σpt  
* **Stability Tests (ISO 13528, Annex B):**  
  * Implementation of Student's t-tests to compare the means of the items before and after the test.  
  * Acceptance criterion: ∣y​1​−y​2​∣\<0.3σpt​.

#### **3.3. Statistical Analysis Module (Main Engine)**

This is the core of the application and will contain the detailed implementation of the following methods:

* Determining the Assigned Value (xpt​):  
  The application will support the two main methods for setting the assigned value:  
  * **Consensus Value:**Calculated from participant results using the robust statistical methods described below.  
  * **Value** of **Reference:**An externally determined value (e.g. by a reference laboratory) that is entered into the application.  
* **Robust Statistical Methods (ISO 13528, Annex C):**  
  * **Initial Dispersion Estimators:**  
    * **nIQR (Normalized Interquartile Range):**Quartile-based estimator.  
    * **MADe (Scaled Median Absolute Deviation):**Estimator based on the median of the absolute deviations.  
  * **Algorithm A (ISO 13528, C.3.1):**It will be the central method to obtain the assigned value (x\*) and the robust standard deviation (s\*) by consensus.  
* **Identification of Outliers:**  
  * **Formal Tests:**  
    * **Boxplots**  
    * **Additional:**  
      * **Test de Grubbs (ISO 5725-2):**For a single outlier.  
      * **Test de Cochran (ISO 5725-2):**For anomalous variances.  
* **Calculation of Performance Indicators:**  
  * **z-score**  
  * **z' score (z-prime)**  
  * **Zeta Score**  
  * **Score In​:**It will be implemented to evaluate performance against a reference value

#### **3.4. Results Display Module**

* **Boxplot:**Primary tool for visual inspection of distribution and identification of outliers.  
* **Frequency Histograms:**To visualize the distribution of the data.  
* **Score Charts:**Graphical representation of the z (or z') scores of all participants.

#### **3.5. Report Generation Module:**

* Use of`R Markdown` / `Room`to create dynamic report templates.  
* Reports will automatically integrate text, results tables, and generated graphs and sections in accordance with ISO 17043:2023.  
* Exporting reports to formats**DOCX, PDF** and **HTML**.

### **4\. Technological Architecture and Work Schedule (8 Weeks)**

| Component | Purpose |
| :---- | :---- |
| **Language R** | Core for all statistical computation and logic. |
| **Framework Shiny** | To build the interactive web user interface. |
| **Tidyverse** | For data manipulation and visualization (ggplot2, dplyr). |
| **R Markdown/Quarto** | For generating reproducible reports. |

**Detailed Work Schedule:**

| Week | Phase | Main Activities | Key Deliverable |
| :---- | :---- | :---- | :---- |
| **1** | Statistical Engine | Project structure. Base functions for data loading and validation. | Repository of initial code and scripts. |
| **2** | Statistical Engine | Implementation of test item validation tests (Homogeneity and Stability). | R functions for validated ANOVA and t-test. |
| **3** | Statistical Engine | Development of the robust analysis core (Algorithm A, nIQR, MADe). | R functions for calculating robust statistics. |
| **4** | Statistical Engine | Implementation of all performance indicators (). Report template. | Score calculation module and R Markdown template. |
| **5** | User Interface | Design and layout of the UI/UX in Shiny (panels, inputs, buttons). | Static prototype of the user interface. |
| **6** | Integration | Connecting UI controls to statistical engine functions. | Application with functional business logic (without graphics). |
| **7** | User Interface | Development of interactive visualizations (Boxplots, histograms, score charts). | Dashboards with integrated dynamic graphics. |
| **8** | Finalization | Integration testing, debugging, and writing the user manual. | Beta version of the application and final documentation. |
| **9** | Application validation report | Prepare the application validation report for the project deliverable. | The report contains the validation tests of the calculations, processes and results reporting. |

