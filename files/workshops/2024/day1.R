############################
### HDFS 2024 R Workshop ###
############################

###Day 1 Basic R and Data Wrangling###
#We will introduce the basic R/Rstudio
#As well as tidyverse, bruceR, and some base R package

###If you have never used R before, this clip will help you a lot!
#Here are some basic rules for RStudio
#https://youtu.be/FIrsOBy5k58?si=sBJ7QoFomg5y9Kdz
#The best way to learn R nowadays is using Google/chatGPT!

###Here are the packages that will be used for Day 1
library(bruceR)
library(haven)
#@@use install.packages("package_name") to install the package you don't have
## Introduction of BruceR:
#https://www.rdocumentation.org/packages/bruceR/versions/2023.9 

###Some cool shortcuts:
#1. tab completion
#2. <- : assign =  "option" + "-" or ("Alt" + "-" for windows)
#3. %>% : pipeline = "command" + "shift" + "m" or ("Ctl" + "Shift" + "m")
#4. run selected lines: "command" + "return" ("Ctl"+"Enter")

###working directory:
#1. @@how you organize your file in your laptop is more important!@@
getwd()
setwd("./Output") # represent "current working directory"

### importing data example of using MIDUS (Midlife in the U.S.) study
m2data <- read_dta("./Data/m2.dta")
m2biodata <- read_dta("./Data/m2_bio.dta")
# = equals to <- 
# these datasets are so rich, we may select the variables into sub-datasets

### Selecting the variables we need
#1.MIDUS 2 BIOMARKER we will be using select function from dplyr package
m2biodata2 <-  m2biodata %>% 
select(c(M2ID,  #identifier
         B4QCT_EA,B4QCT_PA, B4QCT_SA, B4QCT_EN, B4QCT_PN, B4QCT_MD, #childhood maltreatment
         B4QCESD,B4QPS_PS, B4QSA_SA, B4QSC_SC, #CESD,Perceived Stress,Anxiety,Self-control
         B4QSUGS,B4QSTGS, B4QSUGF, B4QSTGF, B4QSTGFA, B4QSUGFA)) #support/strain vars
# df <- df %>% select(c())   @@c() means combining elements into one vector
# a good way to understand a function is by ?function()
#2.MIDUS 2
m2data2 <- m2data %>% 
  select(c(M2ID, #identifier for joint table
           B1PB1, B1PAGE_M2, B1PRSEX, #Education, Age, Sex
           B1PA58, #living with a drinker during childhood 
           B1SE11L, #parental divorce
           B1PB3A #working status
           ))
#3. merge two dataset using merge()
m2df <- merge(m2data2, m2biodata2, all.y = TRUE, by = "M2ID")
# so that all rows in m2bio are kept (all.y) 
# what if I want all rows in m2data?
# your try here:
m2df_allm2 <- 
  
Describe(m2df) #quick look function
summary(m2df) #quick look function 2
ls(m2df) #List all variables in the dataset
#4.remove all intermediate files
rm(m2biodata,m2biodata2,m2data,m2data2)

### Recode/Reshape variables
#1. Renaming variables
m2df <- m2df %>% 
  rename(Sex = B1PRSEX) %>%  #(new_name = old name)
  rename(Depressive_Symptoms = B4QCESD) %>% 
  rename(Social_Anxiety = B4QSA_SA) %>% 
  rename(Self_Control = B4QSC_SC) %>% 
  rename(Perceived_Stress = B4QPS_PS) %>% 
  rename(Lived_with_Alcoholic = B1PA58) %>% 
  rename(Parental_Divorce = B1SE11L) %>% 
  rename(Occupational_Status = B1PB3A) %>% 
  rename(Age = B1PAGE_M2) %>% 
  rename(Education = B1PB1)
#2. reshape, changing the format of variables
#Sex
summary(m2df$Sex)
m2df$Sex <- factor(m2df$Sex,levels = c (1 , 2), labels = c("Male", "Female"))
#factor() makes a variable into a factor variable
#DO NOT run it twice... or...
#Parental_Divorce
summary(m2df$Parental_Divorce)
m2df$Parental_Divorce <- factor(m2df$Parental_Divorce,
                                levels = c (1 , 2), labels = c("Yes", "No"))
#Lived_with_Alcoholic
summary(m2df$Lived_with_Alcoholic)
m2df$Lived_with_Alcoholic <- factor(m2df$Lived_with_Alcoholic,
                                levels = c (1 , 2), labels = c("Yes", "No"))

#3. computing variables
#let's use childhood_maltreatment as an example
#before computing, we need to take a look
summary(m2df$B4QCT_MD)
#let's recode 98 or 8 to NA using an easy way (R Base)
m2df$B4QCT_EA[m2df$B4QCT_EA == 98] <- NA
# df$var[condition: when df$var's value is 98 ] assign NA to it
m2df$B4QCT_PA[m2df$B4QCT_PA == 98] <- NA
m2df$B4QCT_SA[m2df$B4QCT_SA == 98] <- NA
m2df$B4QCT_EN[m2df$B4QCT_EN == 98] <- NA
m2df$B4QCT_PN[m2df$B4QCT_PN == 98] <- NA
m2df$B4QCT_MD[m2df$B4QCT_MD == 8] <- NA

m2df <-  m2df %>% 
  mutate(Childhood_Maltreatment = 
           rowSums(select(.,starts_with("B4QCT")), na.rm = TRUE))
           #mutate() generate a new variable for you
           #na.rm = TRUE will sum up all the available values
summary(m2df$Childhood_Maltreatment)


#Emotional_Support_Family:B4QSUGFA, B4QSTGFA
summary(m2df$B4QSUGFA)
m2df$B4QSTGFA[m2df$B4QSTGFA == 8] <- NA
m2df$B4QSUGFA[m2df$B4QSUGFA == 8] <- NA

m2df <-  m2df %>% 
  mutate(Emotional_Support_Family = ((5-B4QSTGFA) + B4QSUGFA)/2)

#Covariates
summary(m2df$Depressive_Symptoms)
m2df$Depressive_Symptoms[m2df$Depressive_Symptoms == 98] <- NA
summary(m2df$Perceived_Stress)
m2df$Perceived_Stress[m2df$Perceived_Stress == 98] <- NA
summary(m2df$Self_Control)
m2df$Self_Control[m2df$Self_Control == 8] <- NA
summary(m2df$Occupational_Status)
m2df$Occupational_Status[m2df$Occupational_Status == 9] <- NA
m2df$Occupational_Status[m2df$Occupational_Status == 7] <- NA
summary(m2df$Education)
m2df$Education[m2df$Education == 97] <- NA


Describe(m2df)


### Selecting Participants
#1. What if I want my data exclusively containing people with High School or lower?
m2df_hs <- m2df %>% 
  filter(Education <= 5)
#filter function is your good friend to do this task
#What if I only want to study those who were 65 and above?
#Your code below:
m2df_65 <- 

###Linear Models will be covered tomorrow

#1. ttest
TTEST(data = m2df, y = "Perceived_Stress", x = "Sex", test.sided = "=")

#2. ANOVA/MANOVA
# do practice one first before running this one
MANOVA(data = m2df, dv = "Social_Anxiety", between = "Education", covariate = "Age") %>% 
  EMMEANS(by = "Education")

#3. Chi-square
table(x = m2df$Lived_with_Alcoholic, y = m2df$Parental_Divorce)
chisq.test(x = m2df$Lived_with_Alcoholic, y = m2df$Parental_Divorce)

### Save and export your data file
#saveRDS(your_data_frame, "your_data_frame.rds")
saveRDS(m2df, "m2df.rds")

### Practice prompts
#1. Recode Education, varname: Education in to 1 = below High School 2= HS/GED 3. college and above

#2. Create the construct: Emotional_Support_Friends; B4QSUGF, B4QSTGF

#3. A researcher is interested in combining MIDUS 2 and MIDUS 3 data
        #but only those who finished both (had any value in MIDUS 3)




