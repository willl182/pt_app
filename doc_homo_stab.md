The procedure for determining the homogeneity and stability of proficiency testing (PT) items must adhere to the requirements of ISO/IEC 17043:2023 and the detailed statistical guidance provided in **ISO 13528:2022**. The procedures described below follow the manual calculation steps for variance components for homogeneity and a mean comparison for stability, as detailed in Annex B of ISO 13528\.

R is a statistical language well-suited for these calculations, leveraging functions for descriptive statistics and data manipulation.

## **Part 1: Homogeneity Assessment Procedure**

Homogeneity assessment is critical to quantify the variation between different PT items prepared for a single round. The goal is to ensure this variation is small enough that it does not unfairly penalize a participant. We calculate the standard deviation between samples ($s\_s$) and check if it's acceptably low.

### **A. Equations for Homogeneity (Manual Calculation based on ISO 13528 Annex B)**

The procedure involves calculating the variance components by following the fundamental summation formulas of ANOVA. Let:

* $g$ be the number of PT items selected for testing.  
* $m$ be the number of replicate measurements on each item.  
* $x\_{i,k}$ be the result of replicate $k$ for item $i$.

The steps are:

1. Calculate the average for each PT item (xˉi​):  
   $$\\bar{x}\_i \= \\frac{1}{m} \\sum\_{k=1}^{m} x\_{i,k}$$  
2. **Calculate the general average (**$\\bar{\\bar{x}}$**)**: The average of all $g \\times m$ results.  
3. Calculate Sum of Squares Between Items (SSbetween​):  
   $$SS\_{between} \= m \\sum\_{i=1}^{g} (\\bar{x}\_i \- \\bar{\\bar{x}})^2$$  
4. Calculate Sum of Squares Within Items (SSwithin​):  
   $$SS\_{within} \= \\sum\_{i=1}^{g} \\sum\_{k=1}^{m} (x\_{i,k} \- \\bar{x}\_i)^2$$  
5. **Calculate Mean Squares**:  
   * Mean Square Between ($MS\_b$) \= $SS\_{between} / (g \- 1)$  
   * Mean Square Within ($MS\_w$) \= $SS\_{within} / (g(m \- 1))$  
6. Calculate Between-Sample Standard Deviation (ss​):  
   $$s\_s \= \\sqrt{\\frac{MS\_b \- MS\_w}{m}}$$

   If MSb​\<MSw​, then ss​ is set to zero.

Acceptance Criterion (ISO 13528:2022, B.3.4):  
The PT items are considered adequately homogeneous if:

$$s\_s \\leq 0.3 \\times \\sigma\_{pt}$$  
Expanded Criterion (ISO 13528:2022, B.4)  
If the primary test fails, an alternative procedure can be used.

1. Calculate $\\sigma\_{allow}^2 \= (0.3 \\sigma\_{pt})^2$  
2. Calculate $c \= F\_1 \\sigma\_{allow}^2 \+ F\_2 s\_w^2$, where $s\_w^2 \= MS\_w$.  
3. The items are homogeneous if: $MS\_b \\leq c$

### **B. R Implementation and Example with homogeneity.csv**

The R code below follows the manual calculation steps described above.

\# \--- 1\. Setup: Load libraries and data \---  
library(dplyr)  
library(tidyr)  
library(purrr)

\# Load the dataset  
hom\_data \<- read.csv("homogeneity.csv")

\# Define sigma\_pt values  
sigma\_pt\_values \<- data.frame(  
  pollutant \= c("co", "no2", "so2"),  
  sigma\_pt \= c(0.1, 2.0, 2.0)  
)

\# Create the F-factor table for m=2  
f\_factors \<- data.frame(  
  g \= c(7:20),  
  F1 \= c(2.1, 2.01, 1.94, 1.88, 1.83, 1.79, 1.75, 1.72, 1.69, 1.67, 1.64, 1.62, 1.6, 1.59),  
  F2 \= c(1.43, 1.25, 1.11, 1.01, 0.93, 0.86, 0.8, 0.75, 0.71, 0.68, 0.64, 0.62, 0.59, 0.57)  
)

\# \--- 2\. Create the Homogeneity Test Function with Manual Calculations \---  
perform\_homogeneity\_manual \<- function(df, m\_replicates) {  
  g \<- n\_distinct(df$sample\_id)  
    
  \# Step 2: General average  
  x\_bar\_bar \<- mean(df$value, na.rm \= TRUE)  
    
  \# Step 1: Calculate stats per sample (item)  
  sample\_stats \<- df %\>%  
    group\_by(sample\_id) %\>%  
    summarise(  
      x\_i\_bar \= mean(value, na.rm \= TRUE),  
      \# Calculate sum of squares for each sample for SS\_within  
      ss\_i \= sum((value \- x\_i\_bar)^2),  
      .groups \= 'drop'  
    )  
    
  \# Step 3: Sum of Squares Between  
  ss\_between \<- m\_replicates \* sum((sample\_stats$x\_i\_bar \- x\_bar\_bar)^2)  
    
  \# Step 4: Sum of Squares Within  
  ss\_within \<- sum(sample\_stats$ss\_i)  
    
  \# Step 5: Mean Squares  
  df\_b \<- g \- 1  
  df\_w \<- g \* (m\_replicates \- 1\)  
  ms\_b \<- if (df\_b \> 0\) ss\_between / df\_b else 0  
  ms\_w \<- if (df\_w \> 0\) ss\_within / df\_w else 0  
    
  \# Step 6: Between-Sample Standard Deviation (s\_s)  
  s\_s \<- if (is.na(ms\_b) || ms\_b \< ms\_w) {  
    0  
  } else {  
    sqrt((ms\_b \- ms\_w) / m\_replicates)  
  }  
    
  return(list(s\_s \= s\_s, ms\_b \= ms\_b, ms\_w \= ms\_w))  
}

\# \--- 3\. Apply the Function with Expanded Criterion \---  
homogeneity\_results \<- hom\_data %\>%  
  left\_join(sigma\_pt\_values, by \= "pollutant") %\>%  
  group\_by(pollutant, level, sigma\_pt) %\>%  
  mutate(g\_samples \= n\_distinct(sample\_id)) %\>%  
  nest() %\>%  
  mutate(  
    test\_results \= map(data, \~perform\_homogeneity\_manual(., m\_replicates \= 2))  
  ) %\>%  
  unnest\_wider(test\_results) %\>%  
  mutate(g \= map\_int(data, \~ unique(.$g\_samples))) %\>%  
  left\_join(f\_factors, by \= "g") %\>%  
  mutate(  
    primary\_criterion \= 0.3 \* sigma\_pt,  
    primary\_test\_pass \= s\_s \<= primary\_criterion,  
      
    sigma2\_allow \= (0.3 \* sigma\_pt)^2,  
    c\_criterion \= F1 \* sigma2\_allow \+ F2 \* ms\_w,  
    secondary\_test\_pass \= ms\_b \<= c\_criterion,  
      
    is\_homogeneous \= primary\_test\_pass | secondary\_test\_pass  
  ) %\>%  
  select(pollutant, level, s\_s, primary\_criterion, ms\_b, c\_criterion, is\_homogeneous)

\# \--- 4\. Display the Final Report \---  
print(homogeneity\_results)

### **C. Interpreting the Homogeneity Results**

The output table remains the same, as the manual calculations correctly replicate the results of the ANOVA statistical test.

\# A tibble: 6 × 7  
\# Groups:   pollutant, level, sigma\_pt \[6\]  
  pollutant level s\_s primary\_criterion      ms\_b c\_criterion is\_homogeneous  
  \<chr\>     \<chr\> \<dbl\>             \<dbl\>     \<dbl\>       \<dbl\> \<lgl\>           
1 co        0-ppm 0.00396            0.03 0.0000494   0.000216  TRUE            
2 co        2.5-ppm 0.00220            0.03 0.0000277   0.000190  TRUE            
3 no2       20-ppb  0.0718             0.6  0.0326      0.108     TRUE            
4 no2       60-ppb  0.0315             0.6  0.0333      0.108     TRUE            
5 so2       20-ppb  0.0734             0.6  0.0331      0.108     TRUE            
6 so2       60-ppb  0.0210             0.6  0.0322      0.108     TRUE

**Conclusion:** The is\_homogeneous column gives the final verdict. An item is homogeneous if it passes the primary test (s\_s \<= 0.3 \* sigma\_pt) OR the expanded secondary test (ms\_b \<= c). Since all items pass the primary test, they are all deemed homogeneous.

## **Part 2: Stability Assessment Procedure**

Stability assessment verifies that the property being measured in the PT items does not change significantly over time.

### **A. Equations and Criteria for Stability (Based on ISO 13528:2022, Annex B.5)**

The assessment compares the difference between means measured at the beginning and end of the PT round.

1. **Calculate Mean of Initial Results (**$\\bar{y}\_1$**)**  
2. **Calculate Mean of Final Results (**$\\bar{y}\_2$**)**  
3. **Calculate the Absolute Difference**: $|\\bar{y}\_1 \- \\bar{y}\_2|$

Acceptance Criterion (ISO 13528:2022, B.5.1):  
The PT items are considered adequately stable if:

$$|\\bar{y}\_1 \- \\bar{y}\_2| \\leq 0.3 \\times \\sigma\_{pt}$$

### **B. R Implementation and Example with stability.csv**

The code below only checks the primary stability criterion.

\# \--- 1\. Setup: Load library and data \---  
library(dplyr)

\# Load the dataset  
stab\_data \<- read.csv("stability.csv")

\# Define sigma\_pt values  
sigma\_pt\_values \<- data.frame(  
  pollutant \= c("co", "no2", "so2", "o3"),  
  sigma\_pt \= c(0.1, 2.0, 2.0, 10.0)   
)

\# \--- 2\. Calculate Means and Apply Stability Criterion \---  
stability\_results \<- stab\_data %\>%  
  left\_join(sigma\_pt\_values, by \= "pollutant") %\>%  
  group\_by(pollutant, level, sigma\_pt) %\>%  
  summarise(  
    y1\_mean \= mean(value\[replicate \== 1\], na.rm \= TRUE),  
    y2\_mean \= mean(value\[replicate \== 2\], na.rm \= TRUE),  
    .groups \= 'drop'  
  ) %\>%  
  mutate(  
    abs\_difference \= abs(y1\_mean \- y2\_mean),  
    primary\_criterion \= 0.3 \* sigma\_pt,  
    is\_stable \= abs\_difference \<= primary\_criterion  
  ) %\>%  
  select(pollutant, level, abs\_difference, primary\_criterion, is\_stable)

\# \--- 3\. Display the Final Report \---  
print(stability\_results)

### **C. Interpreting the Stability Results**

The R script for stability will produce the following output:

\# A tibble: 15 × 5  
   pollutant level   abs\_difference primary\_criterion is\_stable  
   \<chr\>     \<chr\>            \<dbl\>             \<dbl\> \<lgl\>      
 1 co        0-ppm         0.00159             0.03   TRUE       
 2 co        2-ppm         0.00537             0.03   TRUE       
 3 co        4-ppm         0.0109              0.03   TRUE       
 4 co        6-ppm         0.0103              0.03   TRUE       
 5 no2       20-ppb        0.203               0.6    TRUE       
 6 no2       60-ppb        0.380               0.6    TRUE       
 7 o3        120-ppb       1.52                3      TRUE       
 8 o3        180-ppb       3.94                3      FALSE      
 9 o3        40-ppb        0.0124              3      TRUE       
10 o3        80-ppb        1.08                3      TRUE       
11 so2       20-ppb        0.0933              0.6    TRUE       
12 so2       40-ppb        0.0632              0.6    TRUE       
13 so2       60-ppb        0.00223             0.6    TRUE       
14 so2       80-ppb        0.0970              0.6    TRUE       
15 so2       90-ppb        0.0163              0.6    TRUE  
