# R Workshop -- Exercise
# January 19, 2024


library(ggplot2)
library(bruceR)
library(tidyverse)

# directory and import data
set.wd

getwd()

m2df  <- readRDS("m2df.rds")

# RQ: How do perceived stress and diagnosis of depression interact to affect one's levels of social anxiety?

## NOTE: If the CESD sum score of individuals is above 16, they will be diagnosed depression

## IVs: perceived stress, depression
## DV: social anxiety 
## Covariates: Age, Sex


# 1. Categorize depression


# 2. Check the histogram, distributions, and descriptives of IVs and the DV

# Histogram


# Distribution and Descriptives (only study variables)



# 3. We want to know if the distributions of reported social anxiety are different 
# in people with different educational backgrounds (High school diploma or lower: 1-5, some college: 6-8, bachelor degree or higher: 9-12). 
# A violin plot can be used to describe the distributions. (Hint: You may need to create a new data frame with no NA in educational level.)
# The violin plot needs to look like this:
#   a. The x-axis needs to be educational level, the y-axis needs to be social anxiety, with different educational levels plotted in the same panel (Hint: Do we need to define group?)
#   b. The labels of axis should be "Educational attainment", "Social Anxiety"
#   c. The title of the plot should be "Violin plot of social anxiety"
#   d. The scale on x-axis should be "Low", "Medium", and "High"
#   e. The plot should include individual scores on Social_Anxiety
#   f. The background of the plot should be white. The border of the panel should be black with a size of 0.6.
#   g. The colors for low, medium, and high education are "#8ec1da","#ededed","#d47364"
#   h. Make the violin plot horizonal (Hint: Use coord_flip())
#   i. Show the full range of data. Do not trim the tails (i.e., potential extrime values). (Hint: search in ?geom_violin())
#   j. Draw 25, 50, 75th of the data (Hint. use draw_quantiles() )

# Create a new data frame with no NA in educational level


# Create a horizontal violin plot



# 4. The main effects and interaction effects of IVs on DV when controlling Covs


# using interactions 


# using PROCESS


# 5. We want to plot the simple slopes. The figure should look like this:
# a. The title of the plot should be 'Interaction Plot Between Depression and Perceived Stress'
# b. The title of legend is "Depression", the labels of legend are "Yes" and "No".
# c. The color for individuals with and without depression should be "#298c8c" and "#f1a226"
# d. The background of the plot should be "white". The border of the panel should be black with a size of 0.6, no grid.
# e. All texts in the plot are black.
# f. Confidence intervals.
# g. Save the plot as "Depression x Perceived Stress.PNG" in the current folder. Make sure the size of figure is good.


# plot simple slope


# save the plot to a file (e.g., in PNG format)


