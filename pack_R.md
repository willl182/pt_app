From Functions to Features: A Beginner's Guide to Creating R Packages

Welcome to the world of R package development! If you've ever written a helpful R function and wished you could easily reuse it across projects or share it with colleagues, you're in the right place. This guide will walk you through the essential steps of transforming your standalone R functions into a structured, documented, and shareable R package. As we'll see, packages are the definitive mechanism for sharing extensions to R, but they are also incredibly useful for managing code that will be reused by a single person over time.


--------------------------------------------------------------------------------


1. Why Create a Package? The Core Benefits

The journey often begins by writing functions to avoid repeating the same bits of code. A package is the natural and formal evolution of this practice, turning a collection of useful functions into a robust and reusable tool. The structure and rules imposed by a package provide several key advantages.

* Reusability: Packaging your code is the most effective way to manage functions that you intend to reuse over time. It keeps your work organized and accessible for future projects.
* Sharing: Packages are, without a doubt, the best mechanism for sharing extensions to the R language with others, whether it's with a small team or the global R community.
* Documentation: R packages enforce strict rules about documentation. This structure makes it possible for your package's help files to be seamlessly merged into R’s main help system, making your functions easy for others (and your future self) to understand and use correctly.

To illustrate this process, we will build a small package around two simple statistical functions.

2. Our Project: Two Statistical Functions

2.1. Function 1: A Robust Statistics Calculator

Our first function is an implementation of "Algorithm A" from the ISO 13528:2022 standard. This algorithm is designed to calculate robust estimates of a mean and standard deviation for a dataset, which is particularly useful for handling outliers by iteratively down-weighting extreme values.

Here is the complete R code for our algorithm_A function. Notice that we explicitly call functions like median() and sd() using the stats:: prefix. This is a best practice for package development that we will discuss later.

algorithm_A <- function(x, max_iter = 100) {
  # Remove NA values to prevent errors
  x <- x[!is.na(x)]
  
  # Initial estimates: median and scaled MAD
  x_star <- stats::median(x)
  s_star <- stats::mad(x, constant = 1.4826)
  
  # Initialize variables for the convergence check
  x_star_prev <- -Inf
  s_star_prev <- -Inf
  
  # Set a small tolerance for the case where s_star is zero
  tolerance <- 1e-9
  
  # Iterative process
  for (i in 1:max_iter) {
    
    # Check for convergence: Stop if the robust mean and standard deviation
    # show no change in their first three significant figures.
    if (signif(x_star, 3) == signif(x_star_prev, 3) && signif(s_star, 3) == signif(s_star_prev, 3)) {
      # Return results upon convergence
      return(list(
        robust_mean = x_star,
        robust_sd = s_star,
        iterations = i - 1
      ))
    }
    
    # Store current estimates for the next iteration's convergence check
    x_star_prev <- x_star
    s_star_prev <- s_star
    
    # Calculate the critical value delta (1.5 * s*)
    delta <- 1.5 * s_star
    if (s_star < tolerance) {
        # If s* is essentially zero, there's no variability to assess.
        # The mean is the median, sd is zero, and we can stop.
        return(list(robust_mean = x_star, robust_sd = 0, iterations = i))
    }

    # Create a modified dataset (x_i') by "Winsorizing" the data.
    # Values outside the range [x* - delta, x* + delta] are replaced by the range boundaries.
    x_prime <- pmin(pmax(x, x_star - delta), x_star + delta)
    
    # Update the estimates based on the modified data
    x_star <- base::mean(x_prime)
    s_star <- 1.134 * stats::sd(x_prime)
  }
  
  # Warning if the loop finishes without converging
  warning("Algorithm did not converge within the maximum number of iterations.")
  return(list(
    robust_mean = x_star,
    robust_sd = s_star,
    iterations = max_iter
  ))
}


2.2. Function 2: A Simple Linear Model Wrapper

Our second function is a simple wrapper for R's built-in lm() function. Its purpose is to fit a linear model based on a given formula and dataset, and then return a summary of the results. This function will serve as a practical example for discussing model formulas in R.

fit_simple_model <- function(formula, data) {
  model <- stats::lm(formula, data)
  summary(model)
}


With our two functions defined, it's time to create the formal structure that will house them as a proper R package.

3. The Blueprint: Creating Your Package Structure

The defining feature of an R package is a file named DESCRIPTION. This file's job is to store important metadata about your package, such as its name, what it does, and who created it. R considers any directory containing a DESCRIPTION file to be a package.

A minimal DESCRIPTION file for our package, which we'll call statmodelr, might look like this:

Package: statmodelr
Title: Simple Tools for Statistical Modeling
Version: 0.0.1
Authors@R: person("Jane", "Doe", email = "jane.doe@example.com",
    role = c("aut", "cre"))
Description: A collection of helper functions to perform robust
    statistical calculations and fit simple linear models.


Our two functions, algorithm_A and fit_simple_model, will be saved in one or more script files inside a directory named R. With this basic structure in place, we are ready to add our functions and, crucially, document them.

4. Bringing it to Life: Adding and Documenting Functions

4.1. The Role of Roxygen2

While you could write documentation manually, a far more efficient and modern workflow uses a package called roxygen2. This approach allows you to write documentation in special comments directly above your functions in your R scripts. These "roxygen comments" always start with #'. This workflow keeps your code and its documentation tightly coupled, making it easier to maintain.

4.2. Documenting Our Functions

Let's add roxygen comments to our two functions.

Documenting algorithm_A

Here, we add a title, a longer description, and document each parameter (@param), the return value (@return), and specify that the function should be made available to users (@export).

#' Calculate Robust Mean and Standard Deviation
#'
#' Applies ISO 13528:2022 Algorithm A to a numeric vector. This function
#' calculates robust estimates of the mean and standard deviation for a
#' dataset, handling outliers by iteratively down-weighting extreme values.
#'
#' @param x A numeric vector of data.
#' @param max_iter An integer specifying the maximum number of iterations.
#' @return A named list containing the robust mean (`robust_mean`),
#'   robust standard deviation (`robust_sd`), and the number of
#'   iterations performed (`iterations`).
#' @export
#' @examples
#' sample_data <- c(10.1, 10.2, 10.5, 9.9, 10.3, 25.0)
#' algorithm_A(sample_data)
algorithm_A <- function(x, max_iter = 100) {
  # Remove NA values to prevent errors
  x <- x[!is.na(x)]
  
  # Initial estimates: median and scaled MAD
  x_star <- stats::median(x)
  s_star <- stats::mad(x, constant = 1.4826)
  
  # Initialize variables for the convergence check
  x_star_prev <- -Inf
  s_star_prev <- -Inf
  
  # Set a small tolerance for the case where s_star is zero
  tolerance <- 1e-9
  
  # Iterative process
  for (i in 1:max_iter) {
    if (signif(x_star, 3) == signif(x_star_prev, 3) && signif(s_star, 3) == signif(s_star_prev, 3)) {
      return(list(robust_mean = x_star, robust_sd = s_star, iterations = i - 1))
    }
    x_star_prev <- x_star
    s_star_prev <- s_star
    delta <- 1.5 * s_star
    if (s_star < tolerance) {
      return(list(robust_mean = x_star, robust_sd = 0, iterations = i))
    }
    x_prime <- pmin(pmax(x, x_star - delta), x_star + delta)
    x_star <- base::mean(x_prime)
    s_star <- 1.134 * stats::sd(x_prime)
  }
  
  warning("Algorithm did not converge within the maximum number of iterations.")
  return(list(robust_mean = x_star, robust_sd = s_star, iterations = max_iter))
}


Documenting fit_simple_model

Similarly, we document our second function. The @examples tag provides a runnable example that helps users understand what the function does at a glance. We'll use R's built-in cars dataset for this.

#' Fit a Simple Linear Model
#'
#' A simple wrapper around the lm() function to fit a linear model and
#' return the summary of the model fit.
#'
#' @param formula An object of class "formula": a symbolic description
#'   of the model to be fitted.
#' @param data A data frame containing the variables in the model.
#' @return An object containing the summary of the fitted linear model.
#' @export
#' @examples
#' # Use the built-in 'cars' dataset
#' fit_simple_model(dist ~ speed, data = cars)
fit_simple_model <- function(formula, data) {
  model <- stats::lm(formula, data)
  summary(model)
}


Now that our functions are documented, let's take a closer look at the model formulas we used in our second function, as they are a fundamental part of statistical modeling in R.

5. A Deeper Dive: Understanding Model Formulas and Output

5.1. The Language of Models: R Formulas

Model formulas are a core feature of R's statistical modeling capabilities. They provide a symbolic and concise way to express the relationship between variables.

* The central operator in a formula is the tilde ~.
* The variable on the left-hand side of the ~ is the response or dependent variable.
* The variables on the right-hand side are the predictor or independent variables.

For example, the formula dist ~ speed specifies a model where dist (stopping distance) is modeled as a function of speed. This is the formula we used in the example for our fit_simple_model function.

5.2. Fitting a Linear Model with lm()

The lm() function (for linear model) is the workhorse for fitting linear models in R. When we call lm() with a formula and a dataset, it returns a model fit object that contains all the details of the fitted model.

# Load the built-in 'cars' dataset
data(cars)

# Fit the linear model
fm1 <- lm(dist ~ speed, data = cars)


5.3. Interpreting the Results

To inspect the fitted model, we typically use the summary() function.

summary(fm1)


This command produces a detailed output. The most important part is often the Coefficients table, which provides the estimates for the model parameters. Here is a breakdown of its key columns:

Column	Interpretation
Estimate	The calculated value for the model coefficients. For a simple linear model, this includes the intercept and the coefficient for each predictor variable (e.g., speed).
Std. Error	The standard error of the coefficient estimate. It measures the average distance that the estimated coefficient value is from the actual, unknown population value. A smaller standard error indicates a more precise estimate.
t value	The coefficient's estimate divided by its standard error. It tells us how many standard errors the estimated coefficient is away from zero. A larger absolute t-value provides stronger evidence against the null hypothesis that the coefficient is zero.
`Pr(>	t

With our package functions defined and documented, there's one final structural concept to cover: how to handle situations where your package depends on functions from other R packages.

6. Managing Dependencies

It's common for an R package to rely on functions provided by another package. The correct way to manage these dependencies is crucial for creating a robust and portable package.

Even though our functions only use functions from base R's stats package (like median, mad, and lm), best practice for writing robust package code is to always use the package::function() syntax. This avoids any ambiguity about where a function is coming from, which is critical for making your code predictable and reliable.

Notice in our final documented code for algorithm_A, we wrote stats::median(x) instead of just median(x). This is the recommended practice for all functions that are not your own.

When you use functions from a package that is not part of the base R installation (e.g., dplyr), there are two steps:

1. Declare the Dependency in DESCRIPTION: You must add the external package to the Imports field in your DESCRIPTION file. This ensures that the necessary package will be installed when a user installs your package. However, it's critical to understand that listing a package in Imports does not make its functions automatically available inside your code.
2. Call External Functions Explicitly: You must still use the package::function() syntax. For example, if you wanted to use the rename() function from dplyr, you would first add dplyr to Imports and then write dplyr::rename() in your code.

This two-part approach ensures your package is both portable (all dependencies are installed) and robust (there are no ambiguities in your function calls).


--------------------------------------------------------------------------------


7. Conclusion and Next Steps

Congratulations! You've walked through the core process of building a basic R package. We've covered the essential steps: establishing a package structure with a DESCRIPTION file, adding functions to the R/ directory, documenting them with roxygen2 comments, and understanding the basics of model formulas and dependencies. By turning your functions into a formal package, you make your code more robust, reusable, and shareable.

Further Reading

To continue your journey and learn about more advanced topics like testing, vignettes (long-form documentation), and submitting your package to CRAN, the following resource is highly recommended:

* R Packages (2nd Edition) by Hadley Wickham and Jennifer Bryan.

