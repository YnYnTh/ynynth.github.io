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
m2df <- m2df %>%
  mutate(Depression = case_when(
    Depressive_Symptoms <= 16 ~ 0,
    Depressive_Symptoms >  16 ~ 1,
    TRUE ~ NA_real_
  ))

m2df$Depression <- factor(m2df$Depression,
                          levels = c (0 , 1), labels = c("No depression", "Depression"))

Freq(m2df$Depression)

# 2. Check the histogram, distributions, and descriptives of IVs and the DV

# Histogram
m2df %>% 
  filter(!is.na(Depression)) %>%
  ggplot(aes(x = Depression)) + 
  geom_bar()

hist(m2df$Perceived_Stress, main = "Histogram of Perceived Stress")

hist(m2df$Social_Anxiety, main = "Histogram of Social Anxiety")

# Distribution and Descriptives (only study variables)
m2df_study <- m2df %>% select(c(Age, Sex, Depression, Perceived_Stress, Social_Anxiety))

Describe(m2df_study, plot = TRUE, file = "Descriptives.doc")


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
m2df_no_na <- m2df %>%
  mutate(Education_Recode = case_when(
    Education %in% 1:5 ~ 0,
    Education %in% 6:8 ~ 1,
    Education %in% 9:12 ~ 2,
    TRUE ~ NA_real_
  )) %>%
  filter(!is.na(Education_Recode))

# Create a horizontal violin plot
ggplot(m2df_no_na, aes(x = as.factor(Education_Recode), y = Social_Anxiety, fill = as.factor(Education_Recode))) +
  geom_violin(trim = FALSE, draw_quantiles = c(0.25, 0.5, 0.75), size = 0.6) +
  geom_jitter(width = 0.15, shape = 21, color = 'gray75', fill = 'gray80', size = 0.7) +
  labs(title = "Violin plot of social anxiety",
       x = "Social Anxiety",
       y = "Educational attainment") +
  scale_x_discrete(labels = c('0' = "Low", '1' = "Medium", '2' = "High")) +
  scale_fill_manual(values = c("#8ec1da", "#ededed", "#d47364"),
                    name = "Education",
                    labels = c("Low", "Medium","High")) + 
  theme(panel.background = element_rect(fill = "white"),
        panel.border = element_rect(color = "black", fill = NA, size = 0.6)) +  
  coord_flip()



# 4. The main effects and interaction effects of IVs on DV when controlling Covs
m2df <- m2df %>%
  mutate(grand_mean_center(m2df, "Perceived_Stress", add.suffix = "_C"))

# using interactions 
library(interactions)

Mod <- lm(Social_Anxiety ~ Perceived_Stress_C*Depression + Age + Sex, data = m2df)

summary(Mod)

# using PROCESS
PROCESS(m2df, y="Social_Anxiety", x="Perceived_Stress_C", mods="Depression", covs = c("Age", "Sex"))


# 5. We want to plot the simple slopes. The figure should look like this:
# a. The title of the plot should be 'Interaction Plot Between Depression and Perceived Stress'
# b. The title of legend is "Depression", the labels of legend are "Yes" and "No".
# c. The color for individuals with and without depression should be "#298c8c" and "#f1a226"
# d. The background of the plot should be "white". The border of the panel should be black with a size of 0.6, no grid.
# e. All texts in the plot are black.
# f. Confidence intervals.
# g. Save the plot as "Depression x Perceived Stress.PNG" in the current folder. Make sure the size of figure is good.


# plot simple slope
Int_plot <- interact_plot(model = Mod, pred = "Perceived_Stress_C", modx = "Depression",
                          modx.labels = c("No", "Yes"), main.title = "Interaction Plot Between Depression and Perceived Stress",
                          interval = T, legend.main = "Depression", colors = c("#298c8c","#f1a226"), line.thickness = 0.8)

Simple_Final <- Int_plot + 
  labs(x = "Perceived Stress", y = "Social Anxiety") +
  theme(text = element_text(family = "sans", color = "black"),
        panel.background = element_rect(fill = "white"),
        panel.grid = element_blank(),
        panel.border = element_rect(color = "black", fill = NA, size = 0.5))

# save the plot to a file (e.g., in PNG format)
ggsave("Depression x Perceived Stress.PNG", plot = Simple_Final, width = 8, height = 6, units = "in")


