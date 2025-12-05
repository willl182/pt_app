# **Implementing ISO 13528's Algorithm A in R**

## **Introduction: Taming Outliers with Robust Statistics**

In any dataset, you may encounter **outliers**—data points that are significantly different from other observations. These values can arise from measurement errors, experimental issues, or they can be legitimate but extreme results. Regardless of their origin, outliers can dramatically skew traditional statistical measures like the mean and standard deviation, pulling them away from the true center and spread of the data.

So, how do we get a reliable summary of our data when outliers are present? The answer lies in **robust statistical methods**. These are techniques designed to be less affected by outliers. As stated in section 6.5.1 of the ISO 13528:2022 standard for proficiency testing, robust methods are the preferred approach: "In general, robust methods should be used in preference to methods that delete results labelled as outliers." Instead of simply removing data, we use an algorithm that minimizes the influence of these extreme points.

This tutorial provides a clear, step-by-step guide to implementing **"Algorithm A,"** a powerful robust method from the ISO 13528 standard. We will translate this formal statistical procedure into a practical and reusable R function and apply it to a real-world dataset.

### **What's New in This Version?**

This guide has been updated to include two key improvements:

1. **Smarter Convergence:** The algorithm now stops iterating based on a more practical convergence criterion, as specified in ISO 13528:2022. Convergence is assumed when the robust mean (x\*) and robust standard deviation (s\*) are stable to the third significant figure between iterations.  
2. **Real-World Application:** We will apply the algorithm to a dataset (input\_alg\_a.csv) containing multiple pollutants and experimental setups, demonstrating how to perform the analysis on grouped data.

## **Understanding Algorithm A: A Step-by-Step Breakdown**

Before we dive into the R code, let's break down the logic of the algorithm. Algorithm A is an iterative process, meaning it repeats a series of steps, refining its estimates each time until they become stable.

Here’s how it works:

1. **Initial Estimates (The Robust Start):** The algorithm doesn't start with the standard mean and standard deviation, as they are sensitive to outliers. Instead, it begins with robust alternatives:  
   * **Center (x\*):** The **median** of the data. The median is the middle value, making it highly resistant to extreme high or low values.  
   * **Spread (s\*):** The **Median Absolute Deviation (MAD)**. This is calculated using the formula 1.4826 \* median(|xi \- x\*|), making it a robust counterpart to the standard deviation.  
2. **The Iterative Refinement Loop:** Once it has its starting estimates, the algorithm begins to loop through the following refinement steps:  
   * **Define a Boundary:** It calculates a threshold (delta) set at 1.5 times the current robust standard deviation (s\*). This creates a boundary around the current robust mean (x\* \- delta to x\* \+ delta).  
   * **Temporarily Modify the Data (Winsorizing):** Any data point *outside* this boundary is temporarily replaced with the boundary value itself. For example, any value greater than x\* \+ delta is treated as if it were exactly x\* \+ delta. This process, known as **Winsorizing**, effectively "pulls in" the outliers without completely removing them, thus reducing their influence.  
   * **Update the Estimates:** A new mean and standard deviation are calculated from this *modified* dataset. The standard deviation is multiplied by a correction factor of 1.134 to ensure it is an unbiased estimate.  
   * **Check for Convergence:** The algorithm compares the newly calculated x\* and s\* to the values from the previous iteration. If they have stabilized (i.e., they no longer change significantly), the process stops.

The final values of x\* and s\* are the robust mean and robust standard deviation of your data.

[Image of a flowchart for Algorithm A](https://encrypted-tbn2.gstatic.com/licensed-image?q=tbn:ANd9GcQg0eCeNemVzTE0ZAMDCbzfMrNnC0Y2ojK0THQ09FcqR5djI-1eJxECxaYz7tLQhsX2_pKa9SwKS5697z9F8qOtBE70OjWG6Or-stiRjhMp70zAR4k)

## **Building the R Code, Step by Step**

Let's translate the logic from the previous section into R code, piece by piece. We'll start with a sample dataset to see how each part works.

\# Sample data with an obvious outlier  
sample\_data \<- c(10.1, 10.4, 10.8, 11.2, 9.8, 10.5, 25.0)

**Step 1: Calculate Initial Robust Estimates**

We start with the median and the Median Absolute Deviation (MAD). R's built-in functions median() and mad() make this simple. The constant \= 1.4826 argument in mad() ensures that for normally distributed data, the MAD is a consistent estimator of the standard deviation.

\# Initial robust mean (median)  
x\_star \<- median(sample\_data)   
\# Initial robust standard deviation (MAD)  
s\_star \<- mad(sample\_data, constant \= 1.4826) 

**Step 2: The Iterative Loop and Convergence Check**

The algorithm repeats a process, so we need a loop. A for loop is a good choice. Inside the loop, our first action is to check if the process has converged. We compare the current x\_star and s\_star with the values from the previous iteration (x\_star\_prev and s\_star\_prev). If they are the same to three significant figures, we stop.

\# (Inside the loop)  
if (signif(x\_star, 3\) \== signif(x\_star\_prev, 3\) && signif(s\_star, 3\) \== signif(s\_star\_prev, 3)) {  
  \# The process is stable, so we exit the loop.  
  break   
}

\# We store the current values before updating them, so we can check them in the next iteration.  
x\_star\_prev \<- x\_star  
s\_star\_prev \<- s\_star

**Step 3: Define the Boundary and Winsorize the Data**

Next, we calculate the delta threshold and create the modified dataset, x\_prime, by pulling extreme values to the boundary defined by x\_star ± delta. The pmax() function ensures no value is lower than the lower bound, and pmin() ensures no value is higher than the upper bound.

\# (Inside the loop)  
delta \<- 1.5 \* s\_star  
x\_prime \<- pmin(pmax(sample\_data, x\_star \- delta), x\_star \+ delta)

**Step 4: Update the Estimates**

Finally, we recalculate x\_star and s\_star using the modified x\_prime data. We use the standard mean() and sd() functions here, applying the 1.134 correction factor to the standard deviation.

\# (Inside the loop)  
x\_star \<- mean(x\_prime)  
s\_star \<- 1.134 \* sd(x\_prime)

Putting all these pieces together, along with some good practices like handling NA values and adding a maximum iteration limit, gives us our final, complete function.

## **1\. The R Implementation: From Logic to Code**

Now, let's assemble those steps into a complete, reusable function. We will also load the dplyr library, which we'll need for applying the function to our data file.

\# Install dplyr if you haven't already  
\# install.packages("dplyr")

library(dplyr)

\#' Applies ISO 13528:2022 Algorithm A to a numeric vector.  
\#'  
\#' This function calculates robust estimates of the mean and standard deviation  
\#' for a dataset, handling outliers by iteratively down-weighting extreme values.  
\#'  
\#' @param x A numeric vector of data.  
\#' @param max\_iter An integer specifying the maximum number of iterations to prevent infinite loops.  
\#' @return A named list containing the robust mean (\`robust\_mean\`),  
\#'   robust standard deviation (\`robust\_sd\`), and the number of  
\#'   iterations performed (\`iterations\`).  
algorithm\_A \<- function(x, max\_iter \= 100\) {  
  \# Remove NA values to prevent errors  
  x \<- x\[\!is.na(x)\]  
    
  \# Initial estimates: median and scaled MAD  
  x\_star \<- median(x)  
  s\_star \<- mad(x, constant \= 1.4826)  
    
  \# Initialize variables for the convergence check  
  x\_star\_prev \<- \-Inf  
  s\_star\_prev \<- \-Inf  
    
  \# Set a small tolerance for the case where s\_star is zero  
  tolerance \<- 1e-9  
    
  \# Iterative process  
  for (i in 1:max\_iter) {  
      
    \# Check for convergence: Stop if the robust mean and standard deviation  
    \# show no change in their first three significant figures.  
    if (signif(x\_star, 3\) \== signif(x\_star\_prev, 3\) && signif(s\_star, 3\) \== signif(s\_star\_prev, 3)) {  
      \# Return results upon convergence  
      return(list(  
        robust\_mean \= x\_star,  
        robust\_sd \= s\_star,  
        iterations \= i \- 1  
      ))  
    }  
      
    \# Store current estimates for the next iteration's convergence check  
    x\_star\_prev \<- x\_star  
    s\_star\_prev \<- s\_star  
      
    \# Calculate the critical value delta (1.5 \* s\*)  
    delta \<- 1.5 \* s\_star  
    if (s\_star \< tolerance) {  
        \# If s\* is essentially zero, there's no variability to assess.  
        \# The mean is the median, sd is zero, and we can stop.  
        return(list(robust\_mean \= x\_star, robust\_sd \= 0, iterations \= i))  
    }

    \# Create a modified dataset (x\_i') by "Winsorizing" the data.  
    \# Values outside the range \[x\* \- delta, x\* \+ delta\] are replaced by the range boundaries.  
    x\_prime \<- pmin(pmax(x, x\_star \- delta), x\_star \+ delta)  
      
    \# Update the estimates based on the modified data  
    x\_star \<- mean(x\_prime)  
    s\_star \<- 1.134 \* sd(x\_prime)  
  }  
    
  \# Warning if the loop finishes without converging  
  warning("Algorithm did not converge within the maximum number of iterations.")  
  return(list(  
    robust\_mean \= x\_star,  
    robust\_sd \= s\_star,  
    iterations \= max\_iter  
  ))  
}

### **Key Updates to the Function:**

* **Convergence Logic:** The for loop now includes an if statement at the beginning. It uses R's signif() function to round x\_star and s\_star from the current and previous iterations to three significant figures. If both values match their previous counterparts, the loop terminates.  
* **Iteration Tracking:** A counter i tracks the number of iterations, which is returned along with the final results. This is useful for diagnostics.  
* **Zero SD Handling:** A small tolerance is checked to handle cases with no variability, preventing potential issues and returning a valid result.

## **2\. Application on Grouped Data**

Now, let's use this function on the input\_alg\_a.csv dataset. Our goal is to calculate the robust statistics for each unique combination of pollutant, level, and replicate. The dplyr package is perfect for this "split-apply-combine" task.

\# 1\. Load the data  
input\_data \<- read.csv("input\_alg\_a.csv")

\# 2\. Apply Algorithm A to each group  
\# We use group\_by() to define our analytical groups.  
\# Then, we use summarize() to apply our function to the 'value' column for each group.  
\# The results are stored in a new list-column, which we then unnest.  
results \<- input\_data %\>%  
  group\_by(pollutant, level, replicate) %\>%  
  summarise(  
    stats \= list(algorithm\_A(value)),  
    .groups \= 'drop'  \# Drop grouping after summarizing  
  ) %\>%  
  tidyr::unnest\_wider(stats) \# Unpack the list-column into separate columns

\# 3\. Display the results  
print(results)

## **3\. Interpreting the Results**

Running the code above produces the following table:

\# A tibble: 12 × 6  
   pollutant level   replicate robust\_mean robust\_sd iterations  
   \<chr\>     \<chr\>       \<int\>       \<dbl\>     \<dbl\>      \<int\>  
 1 co        0-ppm           1     \-0.0384    0.0210          4  
 2 co        0-ppm           2     \-0.0381    0.0195          4  
 3 co        2.5-ppm         1      2.46      0.0360          3  
 4 co        2.5-ppm         2      2.46      0.0364          3  
 5 no2       20-ppb          1     19.9       0.177           4  
 6 no2       20-ppb          2     19.9       0.150           4  
 7 no2       60-ppb          1     59.9       0.0910          3  
 8 no2       60-ppb          2     59.9       0.0881          3  
 9 so2       20-ppb          1     19.9       0.155           4  
10 so2       20-ppb          2     19.9       0.151           4  
11 so2       60-ppb          1     59.9       0.0438          3  
12 so2       60-ppb          2     59.9       0.0433          3

This output is highly informative. For each experimental condition (e.g., co at 0-ppm, replicate 1), we now have a robust mean and standard deviation, which are resistant to any potential outliers in the measurements. We can also see that the algorithm consistently converged in just 3 or 4 iterations for every group, demonstrating its efficiency.

## **Conclusion**

In this updated tutorial, you have enhanced a formal statistical procedure and applied it to a complex dataset. We accomplished this by:

1. **Refining the Algorithm:** We implemented a more robust and practical convergence criterion based on the stability of significant figures.  
2. **Structuring the R Code:** We built the logic step-by-step before encapsulating it into a powerful, well-documented, and reusable function.  
3. **Grouped Analysis:** We used dplyr to efficiently apply our function across multiple subsets of our data, a common task in data analysis.

The ability to translate technical standards into working code and apply them to real-world, structured data is a critical skill for any data professional. This guide provides a clear template for tackling similar challenges.
## Actualización 2024-11-21
- Sincronizado con la lógica vigente en `app.R`, incluyendo el uso de Algoritmo A, las variantes de \u03c3_pt y los criterios de homogeneidad/estabilidad basados en las medianas robustas.
- Referencia cruzada con `reports/report_template.Rmd` para reflejar los parámetros YAML (pollutant, level, n_lab, k_factor y metrological_compatibility_method) utilizados al generar informes.
- Verificado que las descripciones mantienen consistencia con la interfaz Shiny y el flujo de cálculo de puntajes z, z', zeta y En.
