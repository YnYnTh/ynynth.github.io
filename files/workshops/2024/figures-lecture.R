# R Workshop -- Plotting data
# January 19, 2024
# Yingying Tang
# Some content was adapted from Crystal Ng (2021, Jan)
# data are from MIDUS Ⅱ and MIDUS Ⅱ biomarker project
# This is a re-anlaysis of Fitzgerald, M., Hamstra, C., & Ledermann, T. (2020). Childhood maltreatment and adult’s provisions of emotional support given to family, friends, and romantic partners: An examination of gender differences. Child Abuse & Neglect, 106, Article 104520. https://doi.org/10.1016/j.chiabu.2020.104520

library(ggplot2)
library(bruceR)
library(tidyverse)
library(haven)

set.wd()

# introduce data
# import data for practice
m2df  <- readRDS("m2df.rds")

### ---------------------------------------------------------------------------###
### How does the data distribute? Is there any ceiling effect or floor effect? ###
### ---------------------------------------------------------------------------###

# 
# # 1. Use bruceR::Describe to get the general distribution of the variables with plots
# m2df_main <- m2df %>% select(c(Childhood_Maltreatment,Emotional_Support_Family,Emotional_Support_Friends,Emotional_Support_Spouses))
# Describe(m2df_main, plot = TRUE)
# 
# # 2. Use hist to plot histograms
# hist(m2df$Childhood_Maltreatment, main = "Histogram of Childhood Maltreatment")
# 

# But we never put these plots in manuscripts

# 3. Use ggplot2 to create descriptive plots
# What is ggplot2: Create Elegant Data Visualisations Using the Grammar of Graphics.
# You can build every graph from the same few basic components (aka main elements of ggplot2 grammar): 
# (a) a data set (data used to construct the graphic), 
# (b) a set of geometric representations (aka geoms): visual marks (e.g., shapes/symbols) that represent data points), and 
# (c) a coordinate system (plot space) & some further elements: faceting, labels, legends

### Syntax ###
# The basic syntax for creating a basic graph in ggplot2 is:
  
  # library(ggplot2)
  # ggplot(data = <DATA>) +                                  # add a new layer/elements with + to the plot space
  # <GEOM>(mapping = aes(<MAPPING variables>), <OPTIONS>) +  # aes stands for aesthetic features
  # <THEME>()                                                # Theme controls the appearance of the plot space

# What I see more often:
# ggplot(data = <DATA>, aes(<MAPPING variables>) + 
# <GEOM>(<OPTIONS>) +
# <THEME>()   

# Different geoms have different features, different options. 
# Full list of available geoms is on the ggplot2 website: https://ggplot2.tidyverse.org/reference/

# box plot
# default box plot
ggplot(data = m2df, aes(x = "", y = Emotional_Support_Friends)) +
  geom_boxplot() +
  labs(title = "Box Plot of Emotional Support to Friends")

# We want to put all three different kinds of emotional supports together
# We need to reshape the data
m2df_long <- m2df %>%
gather(key = "Support_Type", value = "Emotional_Support", Emotional_Support_Friends, Emotional_Support_Family, Emotional_Support_Spouses)
m2df_long$Support_Type <- factor(m2df_long$Support_Type, 
                                    levels = c("Emotional_Support_Friends", "Emotional_Support_Family", "Emotional_Support_Spouses"),
                                    labels = c("Friend Support", "Family Support", "Spousal Support"))

# And then we plot it
ggplot(data = m2df_long, aes(x = "", y = Emotional_Support, group = Support_Type)) +
  geom_boxplot() +
  facet_grid(. ~ Support_Type, scales = "free_x", space = "free_x") + 
  labs(title = "Box Plot of Emotional Support")

# facet_grid(. ~ Sex, scales = "free_x", space = "free_x"):
# . ~ Sex: This specifies the formula for faceting. In this case, it means to create separate panels for each level of the "Support_Type" variable. 
# The dot (.) on the left side of the tilde (~) indicates that the x-axis should be free, allowing different scales for each panel.
# scales = "free_x": This argument ensures that each panel (subplot) on the x-axis has its own scale. 
# Without this, all panels would share the same x-axis scale.
# space = "free_x": This argument allows the panels to have different widths on the x-axis. 
# The default is to make all panels have the same width, but setting space = "free_x" allows for flexibility.

# We can add lines to show if they are statistically different using "ggsignif"
# install.packages("ggsignif")

ggplot()

# Is there any difference between male and female respondents?
# First, we need to exclude 
m2df_long_no_na <- m2df_long %>% 
  filter(!is.na(Sex))

# Use ggplot to plot it
ggplot(data = m2df_long_no_na, aes(x = as.factor(Sex), y = Emotional_Support, group = interaction(Sex, Support_Type))) +
  geom_boxplot() +
  facet_grid(. ~ Support_Type, scales = "free_x", space = "free_x") + 
  labs(title = "Box Plot of Emotional Support")

# We want to make it like something published in Science
ggplot(data = m2df_long_no_na, aes(x = as.factor(Sex), y = Emotional_Support, group = interaction(Sex, Support_Type), fill = as.factor(Sex))) +
  geom_boxplot(width = 0.6, outlier.shape = NA) + 
  # width: adjust box plot aesthetics to make it more narrow; outlier.shape = NA: remove outliers
  facet_grid(. ~ Support_Type, scales = "free_x", space = "free_x") + 
  labs(title = "Box Plot of Emotional Support by Gender", x = "Gender", y = "Emotional Support") + 
  # define plot title and axis labels 
  scale_x_discrete("Sex",labels = c("0" = "Male", "1" = "Female")) + 
  # define x-axis labels 
  geom_jitter(width = 0.15, shape = 21, color = 'gray75', fill = 'gray80', size = 0.7) + 
  # add dots for individual scores
  stat_summary(fun = mean, geom = 'point', shape = 21, size = 3, fill = "white") +  
  # add the mean value of each group # fill change the legend, use colour to change in the main plot
  theme(text = element_text(family = "sans"), 
        # change font, windows system see windowsFonts(). Sorry I don't have a Mac :(
        panel.background = element_rect(fill = "white"), 
        # set panel background to white 
        panel.border = element_rect(color = "black", fill = NA, size = 0.5) 
        # set panel border to black 
        ) +
  scale_fill_manual(breaks = c("0","1"),
                    values = c("gray30", "gray90"),
                    name = "Gender",
                    labels = c("Male", "Female")) # customize color

# Save the plot
# 1) use "Export" 
# 2) use ggsave

# ggplot code
# create a new object, so we can save it!
box_plot <- ggplot(data = m2df_long_no_na, aes(x = as.factor(Sex), y = Emotional_Support, group = interaction(Sex, Support_Type), fill = as.factor(Sex))) +
  geom_boxplot(width = 0.6, outlier.shape = NA) +
  facet_grid(. ~ Support_Type, scales = "free_x", space = "free_x") +
  labs(title = "Box Plot of Emotional Support by Gender", x = "Gender", y = "Emotional Support") +
  scale_x_discrete("Sex", labels = c("0" = "Male", "1" = "Female")) +
  geom_jitter(width = 0.15, shape = 21, color = 'gray75', fill = 'gray80', size = 0.7) +
  stat_summary(fun = mean, geom = 'point', shape = 21, size = 3, fill = "white") +
  theme(text = element_text(family = "sans"),
        panel.background = element_rect(fill = "white"),
        panel.border = element_rect(color = "black", fill = NA, size = 0.5)) +
  scale_fill_manual(breaks = c("0", "1"),
                    values = c("gray30", "gray90"),
                    name = "Gender",
                    labels = c("Male", "Female"))

# save the plot to a file (e.g., in PNG format)
ggsave("Support_Box_Plot.png", plot = box_plot, width = 5, height = 6, units = "in")

  
# We have a lot more data point than the example, a violin plot is more suitable for us
# We only need to change the name of the plot
ggplot(data = m2df_long, aes(x = as.factor(Sex), y = Emotional_Support, group = interaction(Sex, Support_Type), fill = as.factor(Sex))) +
  geom_violin(width = 0.6, trim = FALSE, scale = "width", fill = "gray") + 
  # Use geom_violin instead of geom_boxplot
  facet_grid(. ~ Support_Type, scales = "free_x", space = "free_x") +
  labs(title = "Violin Plot of Emotional Support by Gender", x = "Gender", y = "Emotional Support") +
  scale_x_discrete("Sex", labels = c("0" = "Male", "1" = "Female")) +
  geom_jitter(width = 0.15, shape = 21, color = 'gray75', fill = 'gray80', size = 0.7) +
  stat_summary(fun = mean, geom = 'point', shape = 21, size = 3, fill = "white") +
  theme(text = element_text(family = "sans"),
        panel.background = element_rect(fill = "white"),
        panel.border = element_rect(color = "black", fill = NA, size = 0.5)) +
  scale_fill_manual(breaks = c("0", "1"),
                    values = c("gray30", "gray90"),
                    name = "Gender",
                    labels = c("Male", "Female"))

# It is super easy to use Chatgpt to generate codes. 
# We don't have to remember everything. 
# We just need to have a figure in mind and describe it. 

### -----------------------------------------------###
### How can I plot the link between two variables? ###
### -----------------------------------------------###

# Use ggplot2 to create scatter plots
ggplot(data = m2df, aes(x = Childhood_Maltreatment, y = Emotional_Support_Friends)) +
  geom_point() +
  labs(title = "Associations between Childhood Maltreatment and Emotional Support to Friends")

# We add a regression line
ggplot(data = m2df, aes(x = Childhood_Maltreatment, y = Emotional_Support_Friends)) +
  geom_point() +
  labs(title = "Associations between Childhood Maltreatment and Emotional Support to Friends") +
  geom_smooth(method = lm, se = FALSE)

### --------------------------------------------------------###
### How can I plot the interactive effect of two variables? ###
### --------------------------------------------------------###

# We can get use the "interactions" package
# install.packages("interactions")
library(interactions)

# Regression with the interaction term
# center variable 
m2df$Childhood_Maltreatment_C <- scale(m2df$Childhood_Maltreatment, center = T)
m2df$Self_Control_C <- scale(m2df$Self_Control, center = T)
m2df$Age_C <- scale(m2df$Age_C, center = T)

# Build regression model with lm function
Mod_Int <- lm(Emotional_Support_Family ~ Childhood_Maltreatment_C*Sex +  Self_Control_C +
                # Depressive_Symptoms + Social_Anxiety + Perceived_Stress 
               + Lived_with_Alcoholic + Age + Occupational_Status, data = m2df)
summary(Mod_Int)

# Get the coefficients for plotting simple slopes 
Sim_Slope <- sim_slopes(model = Mod_Int, pred = "Childhood_Maltreatment_C", modx = "Sex")

# Plotting simple slopes
interact_plot(model = Mod_Int, pred = "Childhood_Maltreatment_C", modx = "Sex")

# adjust the figure
Int_plot <- interact_plot(model = Mod_Int, pred = "Childhood_Maltreatment_C", modx = "Sex",
              modx.labels = c("Male", "Female"), main.title = "Interaction Plot Between Men and Women’s Maltreatment and Emotional Support Given to Family",
              interval = T, legend.main = "Gender", colors = c("black","black"), line.thickness = 0.8)

Int_plot + 
  labs(x = "Childhood Maltreatment (CTQ)", y = "Emotional Support Given to Partner") +
  theme(text = element_text(family = "sans", color = "black"),
        panel.background = element_rect(fill = "white"),
        panel.grid = element_blank(),
        panel.border = element_rect(color = "black", fill = NA, size = 0.5))

# We can also do the analysis and plot together, but it does not support providing different arguments to each function.
probe_interaction(model = Mod_Int, pred = "Childhood_Maltreatment_C", modx = "Sex",
                   modx.labels = c("Male", "Female"), main.title = "Interaction Plot Between Men and Women’s Maltreatment and Emotional Support Given to Family",
                   interval = T, legend.main = "Gender", colors = c("black","black"), line.thickness = 0.8)

# Extend: Johnson-Neyman Method for reporting interaction models 
# johnson_neyman finds so-called "Johnson-Neyman" intervals for understanding where simple slopes
# are significant in the context of interactions in multiple linear regression.
# johnson_neyman also returns ggplot objects
# johnson_neyman(model = Mod_Int, pred = predictor, modx = continous_moderator)

# Extend: What if I want to use FIML for missing data?
# We can use lavaan package and use SEM model
# See https://web.pdx.edu/~newsomj/semclass/ho_simple%20slopes.pdf
# In our case:
library(lavaan)
m2df$Sex <- as.numeric(m2df$Sex)
m2df$MalxSex <- m2df$Childhood_Maltreatment_C*m2df$Sex
m2df$Lived_with_Alcoholic <- as.numeric(m2df$Lived_with_Alcoholic)
m2df$Age_C <- as.numeric(m2df$Age, center = T)

Int_Mod_Sem = 'Emotional_Support_Family ~ b1*Childhood_Maltreatment_C + b2*Sex + b3*MalxSex + 
              b4*Self_Control_C + b5*Lived_with_Alcoholic + b6*Age_C + b7*Occupational_Status

              # constraints for simple slopes
              # NEW(LOW_W MED_W HIGH_W SIMP_LO SIMP_MED SIMP_HI);
              
              # simple slope equations for continous variables; 
              # LOW_W := mean - mean*(sqrt(pers)) ; #-1 SD below mean of W; 
              # MED_W := mean ; # mean of W;
              # HIGH_W := mean + mean*(sqrt(pers)); # +1 SD below mean of W;
              LOW_W := 0;
              HIGH_W := 1;
              
              # Now calc simple slopes for each value of W;
              SIMP_LO := b1 + b3*LOW_W;
              # SIMP_MED := b1 + b3*MED_W; 
              SIMP_HI := b1 + b3*HIGH_W;
'
fit <-  sem(Int_Mod_Sem, data = m2df, fixed.x=FALSE, mimic = "mplus", estimator="mlr", missing = "FIML")
summary(fit)
# In summary, SIMP_LO, (SIMP_MED), and SIMP_HI provide parameters for slopes
# In our case, the slope for sex = 0 (Male) is -0.21, and the slope for sex = 1 (Female) is -0.14

# Create a dataset for the lines (if we pre-center all the control variables; if not, this can not provide accurate plot)
# below is an example for dichotomous moderator
# intercept = 3.529, b1 = -0.210, b2 = 0.057, b3 = 0.070
# sd(m2df$Childhood_Maltreatment_C, na.rm = T) = 1; MEAN = 0
# these values come from "fit" object
Intercept <- 3.529
b1 <- -0.210
b2 <- 0.057
b3 <- 0.070
x_mean <- 0
x_sd <- sd(m2df$Childhood_Maltreatment_C, na.rm = T)
Y_lowX_lowW  <- Intercept + b1*(x_mean-x_sd) + b2*0 + b3*0*(x_mean-x_sd)
Y_highX_lowW <-  Intercept + b1*(x_mean+x_sd) + b2*0 + b3*0*(x_mean+x_sd)
Y_lowX_highW  <- Intercept + b1*(x_mean-x_sd) + b2*1 + b3*1*(x_mean-x_sd)
Y_highX_highW <- Intercept + b1*(x_mean+x_sd) + b2*1 + b3*1*(x_mean+x_sd)

simple_lines_data <- data.frame(
  x = c(x_mean-x_sd, x_mean+x_sd),  # X-axis values
  SIMP_LO = c(Y_lowX_lowW, Y_highX_lowW),  # Y-axis values for Low W
  SIMP_HI = c(Y_lowX_highW, Y_highX_highW)   # Y-axis values for HIGH W
)
# reshape the data to long format
simple_lines_data_long <- tidyr::pivot_longer(simple_lines_data, cols = starts_with("SIMP"), names_to = "Line", values_to = "Y")

# Plot the lines using ggplot 
ggplot(simple_lines_data_long, aes(x = x, y = Y, color = Line, linetype = Line)) +
  geom_line(size = 1) +
  labs(title = "Interaction Plot Between Men and Women’s Maltreatment and Emotional Support Given to Partner.",
       x = "Childhood Maltreatment (CTQ)", 
       y = "Emotional Support Given to Partner") + # change it to your variables
  theme(text = element_text(family = "sans", color = "black"),
        panel.background = element_rect(fill = "white"),
        panel.grid = element_blank(),
        panel.border = element_rect(color = "black", fill = NA, size = 0.5)) +
  scale_color_manual(values = c("SIMP_LO" = "black", "SIMP_HI" = "black"),
                     labels = c("SIMP_LO" = "Female", "SIMP_HI" = "Male"),
                     name = "Sex") + # change it to your variables
  scale_linetype_manual(values = c("SIMP_LO" = "dotted", "SIMP_HI" = "solid"),
                        labels = c("SIMP_LO" = "Female", "SIMP_HI" = "Male"),
                        name = "Sex") + # change it to your variables
  theme(legend.position = "right") + 
  guides(color = guide_legend(override.aes = list(size = 5)))   # Change size of shapes in legend
  
