# **Standard Operating Procedure (SOP) for the PT Data Analysis Application**

**A Comparative Analysis Workflow in Compliance with ISO 13528:2022**

### **1.0 Introduction**

This **Standard Operating Procedure (SOP)** defines the complete workflow for the **PT Data Analysis Application**, an R/Shiny-based tool for the **statistical analysis of proficiency testing (PT)** data in compliance with **ISO/IEC 17043:2023** and **ISO 13528:2022**.

The purpose of this SOP is to standardize a comparative analysis procedure for:

* **Calculating a set of robust statistical estimators** for the assigned value ($x\_{pt}$) and standard deviation for proficiency assessment ($\\sigma\_{pt}$).  
* **Conducting a sensitivity analysis** on the homogeneity and stability validation of PT items using the different estimators.  
* **Selecting the most appropriate assigned value** for the final calculation of performance scores (z, z', ζ, En).

This workflow ensures **traceability, reproducibility, and statistical validity**, providing a robust quality assurance framework for the PT scheme.

### **2.0 System Requirements and Environment Setup**

#### **2.1 Software Requirements**

* **R version:** 4.2 or higher  
* **Framework:** Shiny (for the web interface)  
* **Development Environment:** RStudio (recommended)

#### **2.2 Package Installation**

Install required libraries before running the app:

install.packages(c(  
  "shiny", "tidyverse", "vroom", "DT", "rhandsontable", "shinythemes", "outliers"  
))

#### **2.3 Directory Structure**

Organize files as follows:

/data           \# CSV input files: homogeneity.csv, stability.csv, etc.  
/app            \# Shiny app scripts (app.R or run\_app.R)

### **3.0 Overall Workflow: A Comparative Approach**

The analysis follows a multi-stage process designed to evaluate the impact of different statistical estimators on the final conclusions of the PT scheme.

1. **Step 1: Calculate Robust Estimators**: Use the participant or characterization data to calculate a set of candidate values for the assigned value ($x\_{pt}$) and the standard deviation for proficiency assessment ($\\sigma\_{pt}$) using four different robust methods (Median, MADe, nIQR, and Algorithm A).  
2. **Step 2: Conduct Comparative Validation**: Perform the homogeneity and stability tests multiple times. Each test will use a different $\\sigma\_{pt}$ value calculated in Step 1\.  
3. **Step 3: Analyze and Select**: Compare the validation results. If the conclusions are consistent, select the most robust estimator (typically Algorithm A) for the final analysis.  
4. **Step 4: Calculate Final Performance Scores**: Use the single, selected $x\_{pt}$ and $\\sigma\_{pt}$ to calculate and report the final performance scores for all participants.

### **4.0 Step 1: Calculation of Core Robust Statistical Estimators**

This initial step is foundational to the entire process. Using a relevant dataset (e.g., from the homogeneity study or participant results), we will generate a set of robust estimates for the central value and spread of the data.

#### **4.1 Simple Robust Estimators: Median, MADe, and nIQR**

These estimators provide a quick, outlier-resistant summary of the data.

* **Median (**$x^\*$**):** The most basic robust measure of location. It is the middle value of a sorted dataset.  
* **Scaled Median Absolute Deviation (MADe,** $s^\*$**):** A robust measure of spread. Calculated as $1.4826 \\times \\text{median}(|x\_i \- x^\*|)$.  
* **Normalized Interquartile Range (nIQR):** Another robust measure of spread. Calculated as $0.7413 \\times (Q\_3 \- Q\_1)$.

**R Implementation (Manual)**

\# Define Manual Calculation Functions  
mad\_e\_manual \<- function(x) {  
  data\_median \<- median(x, na.rm \= TRUE)  
  abs\_deviations \<- abs(x \- data\_median)  
  mad\_value \<- median(abs\_deviations, na.rm \= TRUE)  
  return(1.4826 \* mad\_value)  
}

nIQR\_manual \<- function(x) {  
  quartiles \<- quantile(x, probs \= c(0.25, 0.75), na.rm \= TRUE, type \= 7\)  
  iqr\_value \<- quartiles\[2\] \- quartiles\[1\]  
  return(0.7413 \* iqr\_value)  
}

\# Apply to data  
\# robust\_estimates \<- data %\>%  
\#   summarise(  
\#     xpt\_median \= median(value, na.rm \= TRUE),  
\#     s\_pt\_mad\_e \= mad\_e\_manual(value),  
\#     s\_pt\_nIQR \= nIQR\_manual(value)  
\#   )

#### **4.2 Advanced Robust Estimator: Algorithm A**

Algorithm A is an iterative procedure from ISO 13528 that provides highly robust estimates of the mean and standard deviation.

**Calculation Logic:**

1. Initialize with starting estimates $x^\*$ (median) and $s^\*$ (MADe or nIQR).  
2. Iteratively update these estimates by down-weighting values that are far from the current central value.  
3. Stop when the estimates for $x^\*$ and $s^\*$ stabilize between iterations.

**R Implementation**

\# (Function from doc\_algorithm\_a.md)  
algorithm\_a \<- function(data\_vector, initial\_sd \= NULL, tol \= 1e-4, max\_iter \= 25\) {  
  \# ... full function logic ...  
}

\# Apply to data  
\# alg\_a\_results \<- algorithm\_a(data$value)  
\# xpt\_alg\_a \<- alg\_a\_results$robust\_mean  
\# s\_pt\_alg\_a \<- alg\_a\_results$robust\_sd

At the end of this step, you will have a set of candidate values, for example: s\_pt\_mad\_e, s\_pt\_nIQR, and s\_pt\_alg\_a.

### **5.0 Step 2: Comparative Homogeneity and Stability Validation**

This step uses the sigma\_pt values generated in Step 1 to assess the PT items. The procedure must be repeated for each candidate sigma\_pt.

#### **5.1 Homogeneity Assessment Procedure**

This test verifies that the variation between PT items is acceptably small.

**Calculation (Manual ANOVA)**

1. Calculate item averages ($\\bar{x}\_i$) and the general average ($\\bar{\\bar{x}}$).  
2. Calculate Sum of Squares Between ($SS\_{between}$) and Within ($SS\_{within}$).  
3. Calculate Mean Squares ($MS\_b$ and $MS\_w$).  
4. Calculate Between-Sample Standard Deviation: $s\_s \= \\sqrt{(MS\_b \- MS\_w) / m}$.

**Acceptance Criterion:** The items are homogeneous if $s\_s \\leq 0.3 \\times \\sigma\_{pt}$.

#### **5.2 Stability Assessment Procedure**

This test verifies that the PT items do not change significantly over time.

**Calculation**

1. Calculate the mean of initial results ($\\bar{y}\_1$) and final results ($\\bar{y}\_2$).  
2. Calculate the absolute difference: $|\\bar{y}\_1 \- \\bar{y}\_2|$.

**Acceptance Criterion:** The items are stable if $|\\bar{y}\_1 \- \\bar{y}\_2| \\leq 0.3 \\times \\sigma\_{pt}$.

#### **5.3 Comparative Analysis**

Run the homogeneity and stability tests using each of the candidate $\\sigma\_{pt}$ values (e.g., from MADe, nIQR, Algorithm A). Document the conclusion (Pass/Fail) for each test run. If the conclusion is the same regardless of the input sigma\_pt, the validation is robust. If the conclusion changes, it indicates a borderline case that requires further investigation.

### **6.0 Step 3: Final PT Scheme Analysis and Performance Scoring**

After confirming the PT items are valid, the final analysis is performed using a single, selected set of robust estimators.

#### **6.1 Selection of Final Estimators**

Based on the comparative analysis, the PT coordinator must select the definitive assigned value ($x\_{pt}$) and standard deviation for proficiency assessment ($\\sigma\_{pt}$). **The values derived from Algorithm A are generally preferred** due to their high statistical robustness.

#### **6.2 Calculation of Performance Scores**

Using the selected $x\_{pt}$ and $\\sigma\_{pt}$, calculate the performance scores for each participant.

* **Z-Score:** $z \= (x\_i \- x\_{pt}) / \\sigma\_{pt}$  
* **Z'-Score:** $z' \= (x\_i \- x\_{pt}) / \\sqrt{\\sigma\_{pt}^2 \+ u(x\_i)^2}$  
* **Zeta-Score:** $\\zeta \= (x\_i \- x\_{pt}) / \\sqrt{u(x\_i)^2 \+ u(x\_{pt})^2}$  
* **En-Score:** $E\_n \= (x\_i \- x\_{pt}) / \\sqrt{U(x\_i)^2 \+ U(x\_{pt})^2}$

**Interpretation:**

* **Z/Z'/Zeta-Score:** $|score| \\leq 2.0$ (Satisfactory), $2 \< |score| \< 3$ (Questionable), $|score| \\geq 3$ (Unsatisfactory).  
* **En-Score:** $|E\_n| \\leq 1.0$ (Satisfactory), $|E\_n| \> 1.0$ (Unsatisfactory).

### **7.0 References**

1. **ISO 13528:2022** — *Statistical methods for use in proficiency testing by interlaboratory comparison.* ([iso.org](https://www.iso.org/standard/78728.html))  
2. **ISO/IEC 17043:2023** — *Conformity assessment – General requirements for proficiency testing.*  
3. **NIST/SEMATECH e-Handbook of Statistical Methods**, Section 1.3.5, "Robust Statistics". ([NIST.gov](https://www.google.com/search?q=https://www.itl.nist.gov/div898/handbook/prc/section1/prc135.htm))  
4. **Eurachem Guide: The Selection, Use and Interpretation of Proficiency Testing (PT) Schemes (2021)**. ([Eurachem.org](https://www.google.com/search?q=https://www.eurachem.org/index.php/publications/guides/pt))  
5. **AMC Technical Brief No. 6: Robust Statistics**. Royal Society of Chemistry. ([rsc.org](https://www.google.com/search?q=https://www.rsc.org/images/robust-statistics-technical-brief-6_tcm18-214867.pdf))  
6. Rousseeuw, P. J., & Croux, C. (1993). **Alternatives to the median absolute deviation**. *Journal of the American Statistical association*, 88(424), 1273-1283.  
7. M. G. Linsinger (2018). **The use of robust statistical methods in proficiency testing**. *Accreditation and Quality Assurance*, 23, 399–403.