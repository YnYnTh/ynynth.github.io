# R Workshop -- Basic Data Analysis
# January 13, 2023
# Yingying Tang
# I appreciate Dr. Han-Wu-Shuang (Bruce) Bao for developing the BruceR package: https://psychbruce.github.io/

# Brief introduction to BruceR --------------------------------------------
#Website: https://www.rdocumentation.org/packages/bruceR/versions/0.8.9
#BRoadly Useful Convenient and Efficient R functions that BRing Users Concise and Elegant R data analyses.
#install package
## Method 1: Install from CRAN
install.packages("bruceR", dep=TRUE)  # dependencies=TRUE

## Method 2: Install from GitHub
install.packages("devtools")
devtools::install_github("psychbruce/bruceR", dep=TRUE, force=TRUE)

#load package
library("bruceR")


# Basic R Programming -----------------------------------------------------
#Set working directory to the path of currently opened file (in our case an R script).
set.wd() 

## import data
?import

bigfive1 <- import("bigfive.csv")
bigfive2 <- import("bigfive.xlsx")
bigfive3 <- import("bigfive.sav")

# check data
# library(tidyverse)
dim(bigfive1) # return the number of rows and columns in the dataset
head(bigfive1, n = 3) # print the first several rows of a dataset
tail(bigfive1, n = 3) # print the last several rows of a dataset
names(bigfive1) # print the variable names of a datase

## export data
export(bigfive1, file="New_bigfive.csv")
export(bigfive2, file="New_bigfive.xlsx")
export(bigfive3, file="New_bigfive.sav")
## export multiple data
export(list(bigfive1, bigfive2), sheet=c("csv", "xlsx"), file="Two_bigfives.xlsx")

# Multivariate Computation ------------------------------------------------
# Dataset: sample dataset phi in the "psych" package; same as bigfive1-3
?psych::bfi
#help("::")

# recode variables into new/same variables
bigfive <- as.data.table(psych::bfi) # These functions can't compute list format data
# Notice all the letters should be capitalized in "RECODE"
# Note: "$" is used to extract or subset a specific part of a data object
bigfive[, ':='(
  age_adult = RECODE(bigfive$age, "lo:18=0") 
)
]
#?':='

# RESCALE variables
added(bigfive, {
  new.A1.1 = RESCALE(A1, to=1:7)
  new.A1.2 = RESCALE(A1, from=1:6, to=1:7)
})

# MEAN(): Compute mean across variables. 
# You don't need to reverse scores manually!
# Notice all the letters should be capitalized in "MEAN"
added (bigfive, {
  E = MEAN(bigfive, "E", 1:5, rev=c("E1", "E2"), likert=1:6)
  A = MEAN(bigfive, vars = c("A1", "A2", "A3", "A4", "A5"), rev="A1", likert=1:6)
  C =  MEAN(bigfive, "C", 1:5, rev=c(4, 5), likert=1:6)
  N = MEAN(bigfive, "N", 1:5, likert=1:6)
  O = MEAN(bigfive, "O", 1:5, rev=c(2, 5), likert=1:6)
}, drop = FALSE)
bigfive


# Reliability and Factor Analyses -----------------------------------------
# Reliability analysis
Alpha(bigfive, "E", 1:5)  # see the warning message
Alpha(bigfive, "E", 1:5, rev=c("E1", "E2"))
Alpha(bigfive, "E", 1:5, rev=1:2)

# Exploratory factor analysis 
EFA_bigfive <- EFA(bigfive, varrange="A1:O5", 
    method = "ml",
    rotation = "oblimin",
    nfactors="eigen",
    hide.loadings=0.40, file = "EFA_big5.doc")

# Confirmatory factor analysis
# see the Exercise part

# Descriptive Statistics and Correlation Analyses -------------------------
# Describe Statistics
added (bigfive, {
  gender = as.factor(gender)
  education = as.factor(education)
}, drop = FALSE)
# Note: comma here denotes all the cases for variables 
Describe(bigfive[, .(E, A, C, N, O, age, education, gender)], plot=TRUE, 
         all.as.numeric=FALSE, file = "describe_big5.doc")

# Correlation
Corr(bigfive[, .(E, A, C, N, O)], file = "cor_big5.doc")

# Tidy Report of Regression Models ----------------------------------------
# Regression models include Linear Model, Generalized Linear Model, Linear Mixed Model, and Generalized Linear Mixed Model
lm_wrong = lm(E ~ A + C + N + O, data=bigfive)
model_summary(lm_wrong, file = "lm_wrong1.doc")
print_table(lm_wrong, file="lm_wrong2.doc")

# Exercise 2 --------------------------------------------------------------
# Question: Is neuroticism related to gender and age?
# You need to:
  #1. Verify and save the factor structure of big-five using CFA
  #2. Recompute the score of each dimension: use sum scores (ignore missing values)
  #3. Get and save the descriptive statistics of gender, age
  #4. Compute and save the correlation between gender, age (save tables and plots)
  #5. Compute and save the regression analysis between gender/age and neuroticism while controling for other subscales
# Reverse scoring items: E1, E2, C4, C5, O2, O5，A1
# Reminder1: Spearman correlation should be used when one of the variables is ordinal
# Reminder2: use fiml to deal with missing values for CFA
# Functions you may use: SUM(), CFA(), Describe(), lm(), model_summary(), print_table()


# Exercise 2 with answers -------------------------------------------------
#1. Verify the factor structure of big-five using CFA
CFA(bigfive, "Ef =~ E[1:5]; Af =~ A[1:5]; Cf =~ C[1:5]; Nf =~ N[1:5]; Of =~ O[1:5]", 
    missing = "fiml")

#2. Recompute the score of each dimension: use sum scores
added (bigfive, {
  gender = as.factor(gender)
  education = as.factor(education)
  Es = SUM(bigfive, "E", 1:5, rev=c("E1", "E2"), likert=1:6)
  As = SUM(bigfive, vars = c("A1", "A2", "A3", "A4", "A5"), rev="A1", likert=1:6)
  Cs = SUM(bigfive, "C", 1:5, rev=c(4, 5), likert=1:6)
  Ns = SUM(bigfive, "N", 1:5, likert=1:6)
  Os = SUM(bigfive, "O", 1:5, rev=c(2, 5), likert=1:6)
}, drop = FALSE)

#3. Get and save the descriptive statistics of gender, age
Describe(bigfive[, .(Es, As, Cs, Ns, Os, age, gender)], plot=TRUE, 
         all.as.numeric=FALSE, file = "describe_big5_new.doc")

#4. Compute and save the correlation between gender, age (two separate files)
Corr(bigfive[, .(Es, As, Cs, Ns, Os)], method = "spearman", file = "cor_big5_spearman.doc", 
     plot.file = "cor_big5_spearman.png")
Corr(bigfive[, .(Es, As, Cs, Ns, Os)], method = "pearson", file = "cor_big5_pearson.doc", 
     plot.file = "cor_big5_pearson.png")

#5. Compute and save the regression analysis between gender/age and big-five personality
lm_g_a = lm(Ns ~ age + gender + As + Cs + Es + Os, data=bigfive)
model_summary(lm_g_a, file = "lm_g_a.doc")

# Plot data: A tough but beautiful journey --------------------------------
library(ggplot2)
# scatter plots
scatter_plot <- ggplot(data = bigfive, aes(x = E, y = A)) + geom_point() 
scatter_plot
# another way
ggplot() + geom_point(data = bigfive, aes(x = E, y = A))

# scatter plots with color
bigfive$gender <- as.factor(bigfive$gender)
ggplot() + 
  geom_point(data = bigfive, 
             aes(x = E, 
                 y = A, 
                 color = gender)) +
  scale_color_manual(values = c("tomato2", "midnightblue"))

# scatter plots with new label
ggplot() + 
  geom_point(data = bigfive, 
             aes(x = E, 
                 y = A, 
                 color = gender)) +
  scale_color_manual(values = c("tomato2", "midnightblue")) +
  labs(title = "Relations between Extraversion and Agreeableness", 
       x = "Extraversion", y = "Agreeableness") 

# scatter plots with regression line
ggplot(data = bigfive, aes(x = E, y = A)) + geom_point() +
  labs(title = "Relations between Extraversion and Agreeableness", 
       x = "Extraversion", y = "Agreeableness")  + 
  geom_smooth()

# scatter plots with linear regression line only
ggplot(data = bigfive, aes(x = E, y = A)) + geom_point() +
  labs(title = "Relations between Extraversion and Agreeableness", 
       x = "Extraversion", y = "Agreeableness")  + 
  geom_smooth(method = lm, se = FALSE)

