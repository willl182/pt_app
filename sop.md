Standard Operating Procedure for Proficiency Testing Schemes: Statistical Analysis in R according to ISO 13528:2022

1.0 Introduction

This manual provides a Standard Operating Procedure (SOP) for the statistical analysis of data from proficiency testing (PT) schemes. The procedures detailed herein are designed to be robust, statistically sound, and fully reproducible, aligning with the general requirements for PT providers as outlined in ISO/IEC 17043:2023. All statistical methods and performance scoring calculations strictly follow the guidelines presented in the international standard ISO 13528:2022, "Statistical methods for use in proficiency testing by interlaboratory comparison."

The R programming language and its associated statistical environment have been designated as the standard software for all calculations and data analysis. This choice is predicated on R's powerful statistical capabilities, its extensive libraries for data manipulation and visualization, and its intrinsic support for reproducible research through tools like R Markdown. This manual will guide the user through the entire data analysis workflow, from the initial environment and project setup to the final performance evaluation and reporting.


--------------------------------------------------------------------------------


2.0 R Environment and Project Setup

A well-defined and consistent R environment is of strategic importance for ensuring the reproducibility and integrity of statistical analysis in proficiency testing. A standardized setup minimizes variability between analyses and analysts, ensuring that the results are traceable and auditable. This section covers the necessary initial steps to prepare the R environment for the PT data analysis workflow.

2.1 Required R Packages

A set of core R packages, collectively known as the tidyverse, provides the foundation for the functions used throughout this SOP. Users must ensure this suite of packages is installed in their R environment. Key components for this procedure include:

* readr: Provides a fast and consistent interface for importing rectangular data, such as the CSV files typically used for participant submissions.
* dplyr: Offers a powerful and intuitive grammar for data manipulation, essential for calculating performance scores and preparing data for analysis.
* ggplot2: Implements a "grammar of graphics" for creating informative and high-quality plots, which are critical for data exploration and reporting.

The tidyverse is a collection of packages designed for data science that share a common design philosophy. The entire suite can be installed with a single command in the R console:

install.packages("tidyverse")


2.2 Project Structure for Reproducibility

Using RStudio Projects is a critical component of a reproducible workflow. An RStudio Project isolates the workspace, working directory, command history, and source documents for a specific task. This ensures that analyses are self-contained and do not conflict with other work. It is mandatory to create a new, dedicated RStudio Project for each PT round.

Within each project, a standardized directory structure must be used to organize files logically. This enhances clarity and simplifies auditing and future review.

* /data: For raw participant data files (e.g., CSV files).
* /scripts: For the R scripts used to perform the analysis.
* /reports: For saving final output reports, plots, and other generated documents.

With the environment configured and the project structure established, the first step in the analysis workflow is to import the participant data.


--------------------------------------------------------------------------------


3.0 Data Import and Structuring

Correctly importing and structuring participant data is the foundation for all subsequent statistical analysis. Errors or inconsistencies introduced at this stage can propagate throughout the workflow and invalidate the entire performance evaluation. This section details the standardized procedure for importing and structuring PT data in R.

3.1 Importing Participant Data

Participant data should be imported from a Comma-Separated Values (CSV) file. The read_csv() function from the readr package is the required tool for this task, as it provides an efficient, consistent, and robust method for parsing flat files.

The following R code demonstrates how to import a CSV file. Note the use of the na argument, which is critical for correctly identifying and importing various representations of missing values (e.g., blank cells or "N/A") as R's native NA value.

# Load the necessary library
library(readr)

# Import participant data from a CSV file in the 'data' directory
participant_data <- read_csv("data/pt_round_data.csv",
                             na = c("N/A", ""))


Upon import, the data is stored in a tibble, which is a modern data frame structure used throughout the tidyverse ecosystem. Tibbles offer improved printing and handling compared to traditional R data frames.

3.2 Data Frame Structure

For all subsequent functions to work correctly, the imported data frame (tibble) must adhere to a specific structure. The following table details the essential columns, their required R data types, and a brief description.

Column Name	R Data Type	Description
participant_id	character	A unique identifier for each participating laboratory.
result	numeric	The quantitative measurement result reported by the participant.
uncertainty	numeric	The standard uncertainty of the result, as reported by the participant.

This standardized structure is crucial for the automated application of statistical functions. After import, it is imperative to validate the data structure and types to ensure integrity. An accidental character in a numeric column can cause silent errors downstream. Use a function like dplyr::glimpse() or str() to verify that data types have been correctly assigned and to check for an unexpected number of missing values.

# Load dplyr to use glimpse()
library(dplyr)

# Validate the structure and data types of the imported data
glimpse(participant_data)


Any deviation from the required format must be corrected through data cleaning and restructuring before the analysis can proceed.


--------------------------------------------------------------------------------


4.0 PT Item Homogeneity and Stability Assessment

Before evaluating participant performance, the PT provider must demonstrate that the proficiency test items are sufficiently homogeneous and stable for the purposes of the interlaboratory comparison. This is a fundamental requirement under ISO/IEC 17043:2023, Section 7.3.2. The statistical procedures for conducting this assessment are detailed in ISO 13528:2022, Annex B.

4.1 Statistical Checks

The primary goal of the homogeneity and stability check is to confirm that any variation between the PT items (i.e., inhomogeneity) is not significant enough to adversely influence the evaluation of participant performance. A standard approach is to use an Analysis of Variance (ANOVA) model to test for statistically significant differences between the means of a subset of tested PT items.

In R, this can be implemented using the aov() or lm() functions. The model aims to determine if the variability between samples is significantly greater than the variability within samples. The outcome of this analysis allows for the quantification of the variability between samples, expressed as the between-sample standard deviation (s<sub>s</sub>), which is calculated from the Mean Square Between and Mean Square Within components of the ANOVA table.

# Conceptual model for ANOVA test on homogeneity data
# 'item_value' is the measured result
# 'item_id' is the unique identifier for each PT item tested
homogeneity_model <- aov(item_value ~ item_id, data = homogeneity_data)
summary(homogeneity_model)


4.2 Incorporating Inhomogeneity into Performance Assessment

Failing to account for the between-sample standard deviation (s<sub>s</sub>) would unfairly penalize participants who receive a PT item that deviates significantly from the central value. Their result would appear to have a large error when it may simply reflect the bias of their specific item.

According to ISO 13528:2022, Annex B.4, if s<sub>s</sub> is statistically significant or practically meaningful, it must be accounted for in the performance assessment. The standard provides three methods:

a)  Include the between-sample standard deviation in the standard deviation for proficiency assessment (σ<sub>pt</sub>). b)  Include s<sub>s</sub> in the uncertainty of the assigned value (u(x<sub>pt</sub>)) and use z'- or E'<sub>n</sub>-scores for assessment. c)  If σ<sub>pt</sub> is derived from the robust standard deviation of participant results, the inhomogeneity is already included, and the criterion for homogeneity can be relaxed with caution.

This SOP adopts method (a) when σ<sub>pt</sub> is determined from the scheme design rather than from participant data.

* Method: Include the between-sample standard deviation in the standard deviation for proficiency assessment.
* Action: The new, adjusted standard deviation (σ'<sub>pt</sub>) is calculated using the following formula: σ'<sub>pt</sub> = √_σ_<sub>pt</sub>² + s<sub>s</sub>²
* R Implementation: This calculation can be implemented in R as follows:

# Given a pre-determined sigma_pt and a calculated s_s
sigma_pt <- 1.5
s_s <- 0.3

# Calculate the adjusted standard deviation for proficiency assessment
sigma_pt_adjusted <- sqrt(sigma_pt^2 + s_s^2)


Once the PT items have been verified as suitable and any necessary adjustments have been made, the analysis of participant data can proceed.


--------------------------------------------------------------------------------


5.0 Core Statistical Analysis of Participant Data

This section details the central part of the analysis workflow. The following procedures implement the robust statistical methods mandated by ISO 13528:2022 (Clauses 6 and 7). These methods are used to determine the assigned value (x<sub>pt</sub>) and the standard deviation for proficiency assessment (σ<sub>pt</sub>) directly from the participants' results, forming the basis for performance evaluation.

5.1 Initial Data Exploration with Graphical Methods

As recommended in ISO 13528:2022, Clause 10, a preliminary visual inspection of the data is a critical first step. Graphical methods help in assessing the distribution of results and identifying potential issues before numerical analysis begins. Histograms and kernel density plots are particularly effective for this purpose.

These plots allow for a visual assessment of the distribution's shape, central tendency, and dispersion. They are used to check for key assumptions, such as whether the data from competent participants appear unimodal and reasonably symmetric, as described in ISO 13528:2022, Section 5.3.1.

# Load the necessary library
library(ggplot2)

# Generate a histogram of participant results
ggplot(participant_data, aes(x = result)) +
  geom_histogram(binwidth = 0.5, fill = "skyblue", color = "black") +
  labs(title = "Distribution of Participant Results", x = "Result", y = "Frequency")

# Generate a kernel density plot
ggplot(participant_data, aes(x = result)) +
  geom_density(fill = "lightblue", alpha = 0.5) +
  labs(title = "Kernel Density of Participant Results", x = "Result", y = "Density")


5.2 Outlier Detection and Handling

In accordance with ISO 13528:2022, Section 6.6, formal outlier tests can be used to support the visual review of the data. Many common tests, such as Grubbs' test (referenced in ISO 13528:2022, Section 6.6.3), assume that the results from competent participants follow an underlying normal distribution. A crucial caveat noted by the standard is that sequential application of Grubbs' test invalidates the Type I error probabilities of the test.

# Conceptual code for an outlier test
# The 'outliers' package or similar can be used for tests like Grubbs' test
# outliers::grubbs.test(participant_data$result)


It is critical to follow the guidance in ISO 13528:2022, Section 6.6.3: even if a result is statistically identified as an outlier and subsequently excluded from the calculation of summary statistics (like the assigned value), the participant’s performance must still be evaluated against the final assigned value and performance criteria. The result is only excluded from the pool used to determine the criteria, not from the evaluation itself.

5.3 Determination of the Assigned Value (xpt)

When the assigned value is determined from participant results, robust statistical methods are required by ISO 13528:2022 to minimize the influence of outliers. Robust estimators of location provide a stable estimate of the central tendency of the data, even in the presence of extreme values.

As per ISO 13528:2022, Section 6.5.2, the median is an explicitly allowed simple and robust estimator for the assigned value.

# Calculate the assigned value (x_pt) using the median
x_pt <- median(participant_data$result, na.rm = TRUE)


5.4 Calculation of the Standard Deviation for Proficiency Assessment (σpt)

The standard deviation for proficiency assessment (σ<sub>pt</sub>) is the criterion used for evaluating participant performance (e.g., in the calculation of z-scores). When this value is derived from participant results, a robust estimate of the standard deviation is the preferred statistic, as stated in ISO 13528:2022, Section 8.1.3.

ISO 13528:2022, Section 6.5.2 allows for simple robust estimators such as the scaled median absolute deviation (MADe) or the normalized interquartile range (nIQR). This SOP designates the scaled MAD as the primary method due to its high robustness to outliers.

* Median Absolute Deviation (MAD): The primary method. The MAD is the median of the absolute deviations from the data's median. The mad() function calculates this value and scales it by a constant (1.4826) to make it a consistent estimator for the standard deviation of normally distributed data.
* Interquartile Range (IQR): An acceptable alternative method. The IQR is the difference between the 75th and 25th percentiles of the data. The IQR() function calculates this range, which is then normalized by dividing by 1.349 to make it comparable to the standard deviation.

With the assigned value (x<sub>pt</sub>) and the standard deviation for proficiency assessment (σ<sub>pt</sub>) robustly determined, the next step is to calculate the individual performance scores for each participant.


--------------------------------------------------------------------------------


6.0 Performance Score Calculation

Performance scores standardize a participant's result, allowing for an objective and consistent evaluation against the criteria established for the PT round. The following calculations are based on the definitions provided in ISO 13528:2022, Clause 9. The results will be calculated and appended to the main data frame using functions from the dplyr package.

6.1 Performance Score Formulas and R Implementation

The dplyr::mutate() function will be used to efficiently calculate all performance scores in a single step, adding each as a new column to the participant data frame.

* z-Scores The z-score indicates how many standard deviations for proficiency assessment a participant's result (x<sub>i</sub>) is from the assigned value (x<sub>pt</sub>). Formula: z = (x_i - x_pt) / σ_pt
* z'-Scores The z'-score is a variation of the z-score that takes into account the participant's own reported standard uncertainty, u(x_i) (from the uncertainty column). Formula: z' = (x_i - x_pt) / sqrt(σ_pt² + u(x_i)²) 
* ζ-Scores (Zeta-Scores) The ζ-score evaluates the agreement between a participant's deviation from the assigned value and the combined uncertainty of both the participant (u(x_i)) and the assigned value, u(x_pt). Formula: ζ = (x_i - x_pt) / sqrt(u(x_pt)² + u(x_i)²) 
* En-Scores The E<sub>n</sub>-score is similar to the ζ-score and compares the difference between the participant's result and a reference value to the expanded uncertainties of both. Here, x<sub>pt</sub> is used as the reference value, and expanded uncertainties (U) are calculated with a coverage factor of k=2 (U = 2 * u). Formula: En = (x_i - x_ref) / sqrt(U_lab² + U_ref²) 
* R Implementation

6.2 Interpretation of Scores

As described in ISO 13528:2022, Section 9.6.3, the combined interpretation of z-scores and ζ-scores provides valuable diagnostic information. A numerically large z-score (e.g., |z| > 3) indicates a measurement result that deviates significantly from the assigned value. A large ζ-score (e.g., |ζ| > 3) suggests this deviation is also significant relative to the combined declared uncertainties.

By examining both, a participant can gain deeper insight. For instance, a participant who repeatedly obtains |z| > 3 but |ζ| < 2 may have accurately assessed their uncertainty, but their method's performance does not meet the requirements of the proficiency testing scheme. This situation may be acceptable if, for example, the participant is using a screening method while others are using more precise quantitative methods. Conversely, if both |z| and |ζ| are large, it implies that the participant's uncertainty evaluation may be incomplete, as it fails to account for the observed deviation.

These calculated scores form the core quantitative feedback provided to participants in the final report.


--------------------------------------------------------------------------------


7.0 Graphical Representation and Reporting

Effective communication of proficiency testing results is paramount. Graphical methods, as described in ISO 13528:2022, Clause 10, are essential tools for enabling participants to visualize their performance relative to their peers and to understand complex statistical information intuitively. A well-structured final report is required to convey all necessary information clearly.

7.1 Youden Plots

For PT schemes that utilize two similar proficiency test items (e.g., Item A and Item B), the Youden plot is a powerful graphical tool for investigating systematic and random errors, as noted in ISO 13528:2022, Section 10.5.

The interpretation of a Youden plot is based on the position of a participant's point (result_A, result_B) relative to the main cluster of data, as described in ISO 13528:2022, Section 10.5.3:

* Systematic Error: Points falling far from the main cluster along the 45-degree line (in the lower-left or upper-right quadrants) may indicate a systematic bias affecting both measurements.
* Random Error: Points falling far from the 45-degree line (in the upper-left or lower-right quadrants) may indicate larger-than-normal random error or poor repeatability.

A conceptual Youden plot can be generated in R using ggplot2:

# Conceptual code for a Youden plot
# Assumes a data frame 'youden_data' with columns 'result_A' and 'result_B'
ggplot(youden_data, aes(x = result_A, y = result_B)) +
  geom_point() +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed") +
  coord_fixed(ratio = 1) +
  labs(title = "Youden Plot", x = "Result for Item A", y = "Result for Item B")


7.2 Final Report Contents

In accordance with ISO/IEC 17043:2023, Section 7.4.3, the final proficiency testing report provided to participants must include a comprehensive set of information. Essential elements include:

* The name and address of the PT provider.
* Unique identification of the report and the PT scheme.
* The date of issue.
* A clear description of the proficiency test items used.
* The participants’ results, reported clearly and unambiguously.
* The statistical data and summary statistics for the PT round.
* The assigned value (x<sub>pt</sub>) and its uncertainty (u(x<sub>pt</sub>)).
* The standard deviation for proficiency assessment (σ<sub>pt</sub>) or other evaluation criteria.
* The performance scores (e.g., z-scores) for each participant.
* Graphical displays of performance (e.g., score charts).
* Comments on participant performance from the PT provider or technical advisors.

7.3 Reproducible Reporting with R Markdown

To ensure the integrity and reproducibility of the final report, R Markdown is the recommended tool for its generation. R Markdown allows for the seamless integration of narrative text, executable R code, and the outputs of that code (such as tables and plots) into a single source document. This document can then be rendered into high-quality formats like PDF or HTML.

This literate programming approach guarantees that the final report is a direct and verifiable product of the data and the analysis script, eliminating transcription errors and enhancing transparency.


--------------------------------------------------------------------------------


8.0 Appendix: Complete R Script

This appendix provides a complete, commented R script that executes the entire SOP for a hypothetical proficiency testing round. This script is intended to serve as a reproducible template that can be adapted for specific PT schemes. It demonstrates the workflow from data creation to the final calculation of performance scores.

# ===================================================================
# SOP for PT Data Analysis according to ISO 13528:2022
# Complete R Script Example
# ===================================================================

# 1. Load necessary libraries
# The tidyverse suite includes dplyr, readr, ggplot2, etc.
library(tidyverse)

# 2. Create a sample tibble of participant data
# This simulates importing a CSV file.
# In a real scenario: participant_data <- read_csv("data/pt_data.csv")
set.seed(42) # for reproducibility
participant_data <- tibble(
  participant_id = paste0("LAB", sprintf("%02d", 1:20)),
  # Generate results from a normal distribution with a few outliers
  result = c(rnorm(18, mean = 25.0, sd = 0.8), 22.1, 28.5),
  # Generate plausible standard uncertainties
  uncertainty = round(rnorm(20, mean = 0.4, sd = 0.1), 2)
)

# 3. Data Validation (Conceptual Step from Section 3.2)
# After import, always inspect the data structure.
glimpse(participant_data)


# --- Section 5: Core Statistical Analysis ---
# This script follows the primary path where x_pt and sigma_pt are derived
# robustly from participant data.

# 5.1 Initial Data Exploration (Visual)
# A quick histogram to check the distribution
ggplot(participant_data, aes(x = result)) +
  geom_histogram(binwidth = 0.5, color = "black", fill = "gray") +
  labs(title = "Initial Visual Data Check")

# 5.3 Determine the Assigned Value (x_pt) using a robust method (median)
x_pt <- median(participant_data$result, na.rm = TRUE)

# 5.4 Calculate Standard Deviation for Proficiency Assessment (sigma_pt)
# The primary method is the scaled Median Absolute Deviation (MAD).
sigma_pt <- mad(participant_data$result, constant = 1.4826, na.rm = TRUE)

# --- ALTERNATIVE PATH: Use a pre-determined sigma_pt from the scheme design ---
# This block is commented out but shows how to proceed if sigma_pt is not
# derived from participant data. This is where adjustments for inhomogeneity
# (Section 4.2) would apply.

# # Assume a pre-determined value from the scheme design
# sigma_pt_preset <- 1.0
#
# # Assume a between-sample standard deviation from homogeneity testing
# s_s <- 0.2
#
# # Adjust sigma_pt for inhomogeneity as per ISO 13528, Annex B.4
# sigma_pt <- sqrt(sigma_pt_preset^2 + s_s^2)


# --- Uncertainty of the Assigned Value ---
# For zeta and En scores, the uncertainty of the assigned value (u_xpt) is needed.
# This would typically be calculated from characterization, homogeneity, etc.
# For this example, we'll assign a plausible value.
u_xpt <- 0.15


# --- Section 6: Performance Score Calculation ---

# Use a single dplyr::mutate() call to calculate all scores
final_scores <- participant_data %>%
  mutate(
    # Calculate z-Score
    z_score = (result - x_pt) / sigma_pt,

    # Calculate z'-Score
    z_prime_score = (result - x_pt) / sqrt(sigma_pt^2 + uncertainty^2),

    # Calculate zeta-Score
    zeta_score = (result - x_pt) / sqrt(u_xpt^2 + uncertainty^2),

    # Calculate En-Score (using k=2 for expanded uncertainty)
    En_score = (result - x_pt) / sqrt((2 * uncertainty)^2 + (2 * u_xpt)^2)
  )

# --- Final Step: Display the Results ---

# Print the determined parameters
print(paste("Assigned Value (x_pt):", round(x_pt, 2)))
print(paste("Standard Deviation for PT (sigma_pt):", round(sigma_pt, 2)))
print(paste("Uncertainty of Assigned Value (u_xpt):", round(u_xpt, 2)))


# Print the final data frame with all calculated scores
print("Final Participant Scores:")
print(final_scores, n = 20)

