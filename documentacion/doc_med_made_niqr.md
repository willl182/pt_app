This guide details the application of basic **robust statistical methods**—the **Median (**$x^\*$**)**, the **Scaled Median Absolute Deviation (MADe,** $s^\*$**)**, and the **Normalized Interquartile Range (nIQR)**—within the context of proficiency testing data, adhering to the principles outlined in ISO 13528\.

Robust statistical methods are generally preferred over classic methods that require deleting results labeled as outliers. They are designed to minimize the influence of extreme values and describe the central part of approximately normally distributed sets of results. These simple, outlier-resistant estimators are crucial, especially as starting points for complex iterative methods like Algorithm A.

### **1\. Robust Measure of Location: The Median ($x^\*$)**

The median is the most straightforward and highly outlier-resistant estimator of the population mean for approximately symmetric distributions. In the context of robust analysis, the median is typically denoted as $Med(x)$ or $x^\*$.

**Calculation:**

1. Sort the data into increasing order.  
2. If the number of data points ($n$) is odd, the median is the single middle value.  
3. If $n$ is even, the median is the average of the two middle values.

### **2\. Robust Measures of Spread (Standard Deviation)**

When outliers are present, the standard deviation can become inflated. Robust estimators provide a more reliable measure of the data's spread.

#### **2.1 Scaled Median Absolute Deviation (MADe, $s^\*$)**

The MADe is a robust estimator of the standard deviation calculated from the median of the absolute deviations from the data's median.

**Calculation:**

1. Calculate the median ($x^\*$) of the data.  
2. Calculate the absolute difference of each data point from the median: $|x\_i \- x^\*|$.  
3. Find the median of these absolute differences: $MAD \= \\text{median}(|x\_i \- x^\*|)$.  
4. Scale the MAD to make it comparable to the standard deviation for normally distributed data: $s^\* \= 1.4826 \\times MAD$. This scaled value is the MADe.

#### **2.2 Normalized Interquartile Range (nIQR)**

The nIQR is another robust estimator of the standard deviation, based on the range between the 25th and 75th percentiles.

**Calculation:**

1. Find the 25th percentile ($Q\_1$) and the 75th percentile ($Q\_3$).  
2. Calculate the Interquartile Range: $IQR \= Q\_3 \- Q\_1$.  
3. Normalize the IQR to make it comparable to the standard deviation for normally distributed data: $nIQR \= 0.7413 \\times IQR$.

### **3\. Application on Grouped Data from homogeneity.csv**

The true power of these methods is their application to grouped data. We will now apply these estimators to the homogeneity.csv dataset, following a clear, structured approach in R.

\# \--- 1\. Setup: Load libraries and data \---  
library(dplyr)

\# Load the homogeneity dataset  
input\_data \<- read.csv("homogeneity.csv")

\# \--- 2\. Defining Manual Functions for Robust Spread \---  
\# Before creating our summary table, we must first define the functions for the   
\# more complex estimators (MADe and nIQR). This is necessary because they will be   
\# called inside the \`summarise\` function later.

\# \--- Manual Scaled MAD (MADe) Calculation \---  
\# This function uses the built-in median() but shows the steps for MADe  
mad\_e\_manual \<- function(x) {  
  x\_clean \<- x\[\!is.na(x)\]  
  if (length(x\_clean) \== 0\) return(NA)  
    
  \# Step 1: Calculate the median of the data  
  data\_median \<- median(x\_clean, na.rm \= TRUE)  
    
  \# Step 2: Calculate absolute deviations from the median  
  abs\_deviations \<- abs(x\_clean \- data\_median)  
    
  \# Step 3: Calculate the median of the absolute deviations (the MAD)  
  mad\_value \<- median(abs\_deviations, na.rm \= TRUE)  
    
  \# Step 4: Scale the MAD to get the MADe  
  return(1.4826 \* mad\_value)  
}

\# \--- Manual Normalized IQR (nIQR) Calculation \---  
nIQR\_manual \<- function(x) {  
  x\_clean \<- x\[\!is.na(x)\]  
  n \<- length(x\_clean)  
  if (n \< 2\) return(NA) \# Cannot compute quartiles with less than 2 points  
    
  x\_sorted \<- sort(x\_clean)  
    
  \# Manual calculation of Q1 (25th percentile) and Q3 (75th percentile)  
  \# This mimics R's default quantile(type=7) interpolation  
  q1\_pos \<- 0.25 \* (n \- 1\) \+ 1  
  q3\_pos \<- 0.75 \* (n \- 1\) \+ 1  
    
  \# Q1 calculation  
  q1\_lower\_index \<- floor(q1\_pos)  
  q1\_upper\_index \<- ceiling(q1\_pos)  
  q1\_frac \<- q1\_pos \- q1\_lower\_index  
  q1 \<- (1 \- q1\_frac) \* x\_sorted\[q1\_lower\_index\] \+ q1\_frac \* x\_sorted\[q1\_upper\_index\]  
    
  \# Q3 calculation  
  q3\_lower\_index \<- floor(q3\_pos)  
  q3\_upper\_index \<- ceiling(q3\_pos)  
  q3\_frac \<- q3\_pos \- q3\_lower\_index  
  q3 \<- (1 \- q3\_frac) \* x\_sorted\[q3\_lower\_index\] \+ q3\_frac \* x\_sorted\[q3\_upper\_index\]  
    
  \# Calculate IQR and scale it to get nIQR  
  iqr\_value \<- q3 \- q1  
  return(0.7413 \* iqr\_value)  
}

\# \--- 3\. Applying All Estimators to Grouped Data \---  
\# Now, we create the final summary table.  
\# The first estimator is the median (robust location), calculated directly.  
\# The robust spread estimators use our manually defined functions from above.  
results\_robust\_summary \<- input\_data %\>%  
  group\_by(pollutant, level) %\>%  
  summarise(  
    \# Estimator 1: Median (Robust Location)  
    robust\_mean\_median \= median(value, na.rm \= TRUE),  
      
    \# Estimator 2: MADe (Robust Spread)  
    robust\_sd\_mad\_e \= mad\_e\_manual(value),  
      
    \# Estimator 3: nIQR (Robust Spread)  
    robust\_sd\_nIQR \= nIQR\_manual(value),  
      
    n\_measurements \= n(),  
    .groups \= 'drop'  
  )

\# \--- 4\. Display the Final Report \---  
print(results\_robust\_summary)

### **4\. Interpreting the Results**

The R script will produce the same summary table as before, as our manual functions correctly replicate the logic of R's built-in estimators.

\# A tibble: 6 × 5  
  pollutant level   robust\_mean\_median robust\_sd\_mad\_e robust\_sd\_nIQR n\_measurements  
  \<chr\>     \<chr\>                \<dbl\>           \<dbl\>          \<dbl\>          \<int\>  
1 co        0-ppm             \-0.0485         0.00161        0.00204             20  
2 co        2.5-ppm            2.50           0.00408        0.00393             20  
3 no2       20-ppb            19.9            0.0889         0.0988              20  
4 no2       60-ppb            59.9            0.0593         0.0612              20  
5 so2       20-ppb            19.9            0.0993         0.111               20  
6 so2       60-ppb            59.9            0.0389         0.0393              20  
