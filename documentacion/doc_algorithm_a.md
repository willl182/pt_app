# **Implementing ISO 13528's Algorithm A in R**

## **Introduction: Taming Outliers with Robust Statistics**

In any dataset, you may encounter **outliers**—data points that are significantly different from other observations. These values can arise from measurement errors, experimental issues, or they can be legitimate but extreme results. Regardless of their origin, outliers can dramatically skew traditional statistical measures like the mean and standard deviation, pulling them away from the true center and spread of the data.

So, how do we get a reliable summary of our data when outliers are present? The answer lies in **robust statistical methods**. These are techniques designed to be less affected by outliers. As stated in section 6.5.1 of the ISO 13528:2022 standard for proficiency testing, robust methods are the preferred approach: "In general, robust methods should be used in preference to methods that delete results labelled as outliers." Instead of simply removing data, we use an algorithm that minimizes the influence of these extreme points.

This tutorial provides a clear, step-by-step guide to implementing **"Algorithm A,"** a powerful robust method from the ISO 13528 standard. We will translate this formal statistical procedure into a practical and reusable R function and apply it to a real-world dataset.

### **What's New in This Version?**

This guide has been updated to align with the implementation used in the **PT Data Analysis Application** (`app.R`). The algorithm uses an **iterative weighting** approach rather than explicit winsorization, which provides a weighted RMS calculation for the standard deviation.

## **Understanding Algorithm A: A Step-by-Step Breakdown**

Before we dive into the R code, let's break down the logic of the algorithm. Algorithm A is an iterative process, meaning it repeats a series of steps, refining its estimates each time until they become stable.

Here’s how it works:

1. **Initial Estimates (The Robust Start):** The algorithm doesn't start with the standard mean and standard deviation, as they are sensitive to outliers. Instead, it begins with robust alternatives:  
   * **Center (x\*):** The **median** of the data. The median is the middle value, making it highly resistant to extreme high or low values.  
   * **Spread (s\*):** The **Scaled Median Absolute Deviation (MADe)**. This is calculated using the formula 1.483 * median(|xi - x*|), making it a robust counterpart to the standard deviation.
2. **The Iterative Refinement Loop:** Once it has its starting estimates, the algorithm begins to loop through the following refinement steps:  
   * **Standardized Residuals:** It calculates standardized residuals for each data point based on the current estimates: u = (x - x*) / (1.5 * s*).
   * **Calculate Weights:** Weights are assigned to each data point to down-weight outliers. If |u| <= 1, the weight is 1. If |u| > 1, the weight is 1/u^2.
   * **Update the Estimates:** A new weighted mean and weighted standard deviation are calculated using these weights.
   * **Check for Convergence:** The algorithm compares the change in x* and s* between iterations. If the change is small enough (e.g., < 0.001), the process stops.

The final values of x\* and s\* are the robust mean and robust standard deviation of your data.

## **The R Implementation: From Logic to Code**

Now, let's assemble those steps into a complete, reusable function. We will also load the dplyr library, which we'll need for applying the function to our data file.

```r
# Install dplyr if you haven't already
# install.packages("dplyr")

library(dplyr)

#' Applies ISO 13528:2022 Algorithm A to a numeric vector.
#'
#' This function calculates robust estimates of the mean and standard deviation
#' for a dataset, handling outliers by iteratively down-weighting extreme values.
#'
#' @param values A numeric vector of data.
#' @param max_iter An integer specifying the maximum number of iterations to prevent infinite loops.
#' @return A list containing the robust mean (`assigned_value`),
#'   robust standard deviation (`robust_sd`), and convergence status.
run_algorithm_a <- function(values, max_iter = 50) {
    # Remove non-finite values
    mask <- is.finite(values)
    values <- values[mask]

    n <- length(values)
    if (n < 3) {
      return(list(error = "El Algoritmo A requiere al menos 3 resultados válidos."))
    }

    # Initial robust estimates
    x_star <- median(values, na.rm = TRUE)
    s_star <- 1.483 * median(abs(values - x_star), na.rm = TRUE)

    # Fallback to SD if MAD is too small
    if (!is.finite(s_star) || s_star < .Machine$double.eps) {
      s_star <- sd(values, na.rm = TRUE)
    }

    if (!is.finite(s_star) || s_star < .Machine$double.eps) {
      return(list(error = "La dispersión de los datos es insuficiente para ejecutar el Algoritmo A."))
    }

    converged <- FALSE

    for (iter in seq_len(max_iter)) {
      # Calculate standardized residuals
      u_values <- (values - x_star) / (1.5 * s_star)

      # Calculate weights
      weights <- ifelse(abs(u_values) <= 1, 1, 1 / (u_values^2))

      weight_sum <- sum(weights)
      if (!is.finite(weight_sum) || weight_sum <= 0) {
        return(list(error = "Los pesos calculados no son válidos para el Algoritmo A."))
      }

      # Update estimates
      x_new <- sum(weights * values) / weight_sum
      s_new <- sqrt(sum(weights * (values - x_new)^2) / weight_sum)

      if (!is.finite(s_new) || s_new < .Machine$double.eps) {
        return(list(error = "El Algoritmo A colapsó debido a una desviación estándar nula."))
      }

      # Check convergence
      delta_x <- abs(x_new - x_star)
      delta_s <- abs(s_new - s_star)
      
      x_star <- x_new
      s_star <- s_new

      if (delta_x < 1e-03 && delta_s < 1e-03) {
        converged <- TRUE
        break
      }
    }

    list(
      assigned_value = x_star,
      robust_sd = s_star,
      converged = converged,
      effective_weight = sum(weights),
      error = NULL
    )
}
```

### **Key Updates to the Function:**

* **Weighted Approach:** This implementation explicitly calculates weights based on standardized residuals and uses them to compute a weighted mean and a weighted RMS standard deviation.
* **Convergence Logic:** Convergence is determined when the change in both x* and s* is less than 0.001.
* **Robustness:** Includes checks for zero variance (s* approx. 0) and insufficient data points.

## **Application on Grouped Data**

Now, let's use this function on the `input_alg_a.csv` dataset. Our goal is to calculate the robust statistics for each unique combination of pollutant, level, and replicate. The dplyr package is perfect for this "split-apply-combine" task.

```r
# 1. Load the data
input_data <- read.csv("input_alg_a.csv")

# 2. Apply Algorithm A to each group
# We use group_by() to define our analytical groups.
# Then, we use summarize() to apply our function to the 'value' column for each group.
results <- input_data %>%
  group_by(pollutant, level, replicate) %>%
  summarise(
    stats = list(run_algorithm_a(value)),
    .groups = 'drop'
  ) %>%
  tidyr::unnest_wider(stats) # Unpack the list-column

# 3. Display the results
print(results)
```

## **Conclusion**

In this updated tutorial, you have enhanced a formal statistical procedure and applied it to a complex dataset. We accomplished this by:

1. **Refining the Algorithm:** We implemented the weighted approach used in the production application (`app.R`).
2. **Structuring the R Code:** We built the logic step-by-step before encapsulating it into a powerful, well-documented, and reusable function.
3. **Grouped Analysis:** We used dplyr to efficiently apply our function across multiple subsets of our data, a common task in data analysis.

The ability to translate technical standards into working code and apply them to real-world, structured data is a critical skill for any data professional. This guide provides a clear template for tackling similar challenges.
