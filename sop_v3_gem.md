# **Comprehensive Standard Operating Procedure (SOP) for the PT Data Analysis Application**

**A Comparative Analysis Workflow in Compliance with ISO 13528:2022**

### **1.0 Purpose and Scope**

This **Standard Operating Procedure (SOP)** defines the complete statistical workflow for the **PT Data Analysis Application**, an R/Shiny-based tool for the analysis of proficiency testing (PT) data, fully aligned with **ISO/IEC 17043:2023** and **ISO 13528:2022**.

The purpose of this procedure is to ensure a reproducible, transparent, and statistically valid workflow for:

* **Robust estimation** of the assigned value ($x\_{pt}$) and standard deviation for proficiency assessment ($\\sigma\_{pt}$) using four distinct robust methods.  
* **Comparative validation** of PT item **homogeneity and stability** by conducting a sensitivity analysis with each estimator.  
* **Determination of the operational** $x\_{pt}$ and the **mandatory calculation of participant performance scores** (z, z', ζ, En).

### **2.0 System and Data Setup**

#### **2.1 Software Requirements**

* **R version:** 4.2 or higher; RStudio is recommended.  
* **R Packages:** shiny, tidyverse, vroom, DT, rhandsontable, shinythemes, outliers.

#### **2.2 Data Files**

* homogeneity.csv — Replicate measurement data for PT items.  
* stability.csv — Results at two different time points (e.g., before and after).  
* Participant summary files for final score calculations.

#### **2.3 Launching the Application**

Rscript run\_app.R

### **3.0 Overall Workflow: A Comparative Approach**

The analysis follows a multi-stage process designed to evaluate the impact of different statistical estimators on the final conclusions of the PT scheme.

1. **Step 1: Calculate Robust Estimators**: Use participant or characterization data to compute four candidate versions of the assigned value ($x\_{pt}$) and the standard deviation for proficiency assessment ($\\sigma\_{pt}$) using the Median, MADe, nIQR, and Algorithm A.  
2. **Step 2: Conduct Comparative Validation**: For each of the four $\\sigma\_{pt}$ versions, perform the full homogeneity and stability tests according to ISO 13528 Annex B criteria.  
3. **Step 3: Analyze and Select**: Compare the outcomes of the validation tests. If the conclusions are consistent, select the most robust and appropriate estimator (typically Algorithm A) to define the final, operational $x\_{pt}$ and $\\sigma\_{pt}$.  
4. **Step 4: Calculate Final Performance Scores**: Use the single, selected $x\_{pt}$ and $\\sigma\_{pt}$ to calculate and report the mandatory performance scores for all participants.

### **4.0 Step 1: Calculation of Core Robust Estimators**

This initial step is foundational. Using a relevant dataset, we will generate a set of robust estimates for the central value (location) and spread (dispersion) of the data.

#### **4.1 Robust Estimators and Formulas**

| Estimator | Formula / Method | Description |
| :---- | :---- | :---- |
| **Median (**$x^\*$**)** | Middle value of sorted data | Basic robust measure of location. |
| **MADe (**$s^\*$**)** | $1.4826 \\times \\text{median}( | x\_i \- x^\* |
| **nIQR** | $0.7413 \\times (Q\_3 \- Q\_1)$ | Robust measure of spread based on quartiles. |
| **Algorithm A** | Iterative weighted mean/SD | Advanced iterative procedure from ISO 13528\. |

#### **4.2 R Implementation**

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

algorithm\_a \<- function(data\_vector, initial\_sd \= NULL, tol \= 1e-4, max\_iter \= 25\) {  
  \# ... full function logic from ISO 13528 ...  
}

### **5.0 Step 2: Comparative Homogeneity and Stability Validation**

This step must be repeated for each candidate $\\sigma\_{pt}$ value generated in Step 1\.

#### **5.1 Homogeneity Assessment**

This test verifies that the variation between PT items ($s\_s$) is acceptably small.

* **Procedure:** Manual ANOVA calculation to find Mean Square Between ($MS\_b$) and Mean Square Within ($MS\_w$).  
* **Acceptance Criterion:** The items are homogeneous if $s\_s \\leq 0.3 \\times \\sigma\_{pt}$.

#### **5.2 Stability Assessment**

This test verifies that the PT items do not change significantly over time by comparing the mean of initial results ($\\bar{y}\_1$) and final results ($\\bar{y}\_2$).

* **Procedure:** Calculate the absolute difference $|\\bar{y}\_1 \- \\bar{y}\_2|$.  
* **Acceptance Criterion:** The items are stable if $|\\bar{y}\_1 \- \\bar{y}\_2| \\leq 0.3 \\times \\sigma\_{pt}$.

### **6.0 Step 3: Final PT Scheme Analysis and Performance Scoring**

After confirming the PT items are valid, the final analysis is performed using a single, selected set of robust estimators.

#### **6.1 Selection of Final Estimators**

Based on the comparative analysis, the PT coordinator must select the definitive assigned value ($x\_{pt}$) and standard deviation for proficiency assessment ($\\sigma\_{pt}$). **The values derived from Algorithm A are generally preferred** due to their high statistical robustness and formal standing in the ISO 13528 standard.

#### **6.2 Calculation of Performance Scores**

Using the selected $x\_{pt}$ and $\\sigma\_{pt}$, calculate the performance scores for each participant. This is a **mandatory** step.

| Score | Formula |
| :---- | :---- |
| **z-score** | $z \= (x\_i \- x\_{pt}) / \\sigma\_{pt}$ |
| **z'-score** | $z' \= (x\_i \- x\_{pt}) / \\sqrt{\\sigma\_{pt}^2 \+ u(x\_i)^2}$ |
| **zeta-score** | $\\zeta \= (x\_i \- x\_{pt}) / \\sqrt{u(x\_i)^2 \+ u(x\_{pt})^2}$ |
| **En-score** | $E\_n \= (x\_i \- x\_{pt}) / \\sqrt{U(x\_i)^2 \+ U(x\_{pt})^2}$ |

#### **6.3 Interpretation Criteria**

| Score | Satisfactory | Questionable | Unsatisfactory |
| :---- | :---- | :---- | :---- |
| **z, z', ζ** | $ | score | \\leq 2.0$ |
| **En** | $ | E\_n | \\leq 1.0$ |

### **7.0 Reporting and Quality Assurance**

* **Export:** All tables and plots from the application should be exported (CSV, XLSX, PDF, PNG) for documentation.  
* **Record Keeping:** The version of R, all package versions, and the selected operational $x\_{pt}$ and $\\sigma\_{pt}$ must be recorded in the final PT report.  
* **Validation:** All statistical functions within the application have been validated against the examples in ISO 13528:2022 and through test datasets.

### **8.0 References**

1. **ISO 13528:2022** — *Statistical methods for use in proficiency testing by interlaboratory comparison.* ([iso.org](https://www.iso.org/standard/78728.html))  
2. **ISO/IEC 17043:2023** — *Conformity assessment – General requirements for proficiency testing.*  
3. **NIST/SEMATECH e-Handbook of Statistical Methods**, Section 1.3.5, "Robust Statistics". ([www.itl.nist.gov](https://www.google.com/search?q=https://www.itl.nist.gov/div898/handbook/prc/section1/prc135.htm))  
4. **Eurachem Guide (2021):** *The Selection, Use and Interpretation of Proficiency Testing (PT) Schemes*. ([www.eurachem.org](https://www.google.com/search?q=https://www.eurachem.org/index.php/publications/guides/pt))  
5. **AMC Technical Brief No. 6:** *Robust Statistics*. Royal Society of Chemistry. ([www.rsc.org](https://www.google.com/search?q=https://www.rsc.org/images/robust-statistics-technical-brief-6_tcm18-214867.pdf))  
6. Rousseeuw, P. J., & Croux, C. (1993). **Alternatives to the median absolute deviation**. *Journal of the American Statistical Association*, 88(424), 1273-1283.  
7. M. G. Linsinger (2018). **The use of robust statistical methods in proficiency testing**. *Accreditation and Quality Assurance*, 23, 399–403.