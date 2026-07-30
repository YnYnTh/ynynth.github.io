# GIMME original codes from https://github.com/mkullar/DataDrivenEmotionDynamics
# TANG Yingying 5/9/2024 at University of Texas at Austin
# presented at Beijing Forestry University

# How to run code --------------------------------------------------------
# Highlight and click Run
# Windows: CTRL + Enter
# Mac: Command + Enter
# or just move the cursor into that line and click Run

# Packages: They’re like apps you download for R ----------------------------------------------------------------
# “Packages are collections of R functions, data, and compiled code in a well-defined format. 
# The directory where packages are stored is called the library. 
# R comes with a standard set of packages. Others are available for download and installation. 
# Once installed, they have to be loaded into the session to be used.” 

# before you can load these libraries, you need to install them first
# frequent use packages in R
install.packages("tidyverse")
install.packages("haven")
install.packages("psych")

# helpful package written by Dr. BAO Han-Wu-Shuang
install.packages("bruceR")

##GIMME packages
#devtools::install_github("GatesLab/gimme/tree/master/gimme", force= TRUE, dependencies = TRUE)
devtools::install_github("GatesLab/gimme/gimme", force=TRUE)
install.packages("perturbR")

library(gimme)
library(perturbR)

library(dplyr)
library(data.table)
library(imputeTS)
library(pracma)
library(bruceR)

#1. Pre-processing ESM data
# Impute data in order to use standardized residuals of time-series data
#read in esmdata from your local filepath
esmdata <- read.csv("esmdata.csv") 
# or we can use bruceR to import data (including TXT, CSV, Excel, SPSS, Stata, ...)
esmdata <- import("esmdata.csv")

# Objects: They save stuff for you ----------------------------------------
# object <- fuction(x)
# which means ‘object is created from function(x)’. 
# An object is anything created in R. 
# It could be a variable, a collection of variables, a statistical model, etc.

# Assignment operator: 
# <- assign values ( = can also assign values, but it doesn’t store the used values outside of a function)
# Mac shortcut: "option" + "-"
# Windows shortcut: "alt" + "-"

# Functions: They do stuff for you ----------------------------------------
# c() Function: Combine things like thing1, thing2, thing3, …
# “c” stands for combine. Use this to combine values into a vector.

# check the data
##1. Environment panel, click to view
##2. use str function
str(esmdata)
##3. use head/tail function
head(esmdata)

##4. use dim function
dim(esmdata)

# descriptive stats
# mean and sd
mean(esmdata$Angry, na.rm = TRUE) # $ means access variable in the data.frame/list
sd(esmdata$Angry, na.rm = TRUE)
# we can also do this to multiple variables
lapply(esmdata, function(x) {
  mean(x, na.rm = TRUE)
})
# simple practice in bruceR
Describe(esmdata)
## save the descriptive stats into a word doc
Describe(esmdata, file = "descriptive stats")

# correlation between variables
Corr(esmdata)
Corr(esmdata, file = "correlation")

# imputation
#create a new df to avoid changing the original dataset
b1var <- esmdata 
#pick the variables that we want to use as a "full" dataset
shortem <- c("moniker", "time", "Happy_e","Enthusiastic","Pleased", "Relaxed", "Nervous", "Sad", "Irritated", "Angry", "Stressed", "MWoccur", "EmotionChronometry")

#assign new value to b1var
b1var <- b1var[shortem] #use [] to select elements

#pick the variables that need to be imputed
imputevar <- c("Happy_e","Enthusiastic","Pleased", "Relaxed", "Nervous", "Sad", "Irritated", "Angry", "Stressed", "MWoccur", "EmotionChronometry")

#change the type of a variable
b1var$moniker <- as.factor(b1var$moniker)
#change the name of a variable: moniker into subID
#check the naming
names(b1var)[1] <- "subID"
# names(b1var)[which(names(b1var) == "moniker")] <- "subID"

##### This part will not be covered in the workshop #####
## create individual files and impute data
# create folder
dir.create("step1", showWarnings = FALSE)
#loop through participants
for(i in levels(b1var$subID)) {
  b1varimp <- b1var[b1var$subID == i,]
  for(j in imputevar) {
    b1varimp[,j] <- na_ma(b1varimp[,j], k=2, weighting = "simple")
  }
  #save all files in folder for use at individual level
  savefile <- paste0 ("step1/", i, ".csv", sep = "") #save first preprocessed step here to a folder you name 'step1' (or change the name to what you would like)
  write.csv(b1varimp, file = savefile, row.names = FALSE)
  print(paste("Dataframe Saved:", i))
}
### imputation end here 

# Reduce down the most highly correlating emotion variables used in analysis of input variables
data <- rbindlist(lapply(list.files("step1/", full.names = TRUE), fread), fill = TRUE) #read in individual files from prior step
data$subID <- as.factor(data$subID)

##### #####


#reduce down the most highly correlating emotion variables
data$HighCorrNegative <- (data$Angry + data$Irritated)/2 #referred to as "Angry" in manuscript for ease of interpreting
data$HighCorrPositive <- (data$Happy_e + data$Pleased)/2 #referred to as "Happy" in manuscript for ease of interpreting
# we can also use scale to create centered/standardized data

data1 <- data
data1$Sad_z <- scale(data1$Sad)

##### This part will not be covered in the workshop #####
data <- as.data.frame(data)
corrred <- c("subID", "time", "HighCorrPositive", "HighCorrNegative", "Enthusiastic", "Relaxed", "Sad", "Nervous", "Stressed", "MWoccur", "EmotionChronometry")
data <- data[corrred]

# Remove linear trends in data
scaled.dat <- scale(data[,3:11]) #standardize
names <- data[,1:2]
scaled.dat <- cbind(names, scaled.dat)
data <- scaled.dat

dir.create("step2", showWarnings = FALSE)

for(i in levels(data$subID)) {
  data1 <- data[data$subID == i,]
  data1$Enthusiastic <- detrend(data1$Enthusiastic, tt = 'linear')
  data1$Relaxed <- detrend(data1$Relaxed, tt = 'linear')
  data1$Nervous <- detrend(data1$Nervous, tt = 'linear')
  data1$Sad <- detrend(data1$Sad, tt = 'linear')
  data1$HighCorrPositive <- detrend(data1$HighCorrPositive, tt = 'linear') #Happy, Pleased collapsed
  data1$HighCorrNegative <- detrend(data1$HighCorrNegative, tt = 'linear') #Angry, Irritated collapsed
  data1$Stressed <- detrend(data1$Stressed, tt = 'linear')
  data1$MWoccur <- detrend(data1$MWoccur, tt = 'linear')
  data1$EmotionChronometry <- detrend(data1$EmotionChronometry, tt = 'linear')
  savefile <- paste0 ("step2/", i, ".csv", sep = "") #save next preprocessed step here to a folder you name 'step2' (or change the name to what you would like)
  write.csv(data1, file = savefile, row.names = FALSE)
  print(paste("Dataframe Saved:", i))
}

dir.create("finaloutput", showWarnings = FALSE)

# Make sure timing is equally spaced, provide the overnight NA value for overnight spacing of self-report and diurnal time, or exogneous time variable taken as square root of time of day.
datadetrend <- rbindlist(lapply(list.files("step2/", full.names = TRUE), fread), fill = TRUE) #read in individual files from prior step
datadetrend$subID <- as.factor(datadetrend$subID)
diurnaltime <- read.csv("overnightanddiurnaltime.csv") #time=ESM timepoint, contime=the continuous order of timepoint occurrence for ordering, raw time=timepoint by hours in the day, TimeofDay=diurnal time calculated by square root of time based on literature.
diurnaltime <- diurnaltime[, -which(names(diurnaltime) == "raw.time")]
for(i in levels(datadetrend$subID)) {
  datad1 <- datadetrend[datadetrend$subID == i,]
  datad1 <- merge(diurnaltime, datad1, by = "time", all = TRUE)
  datad1$subID[is.na(datad1$subID)] <- datad1$subID[1]
  datad1 <- datad1[order(datad1$contime),]
  remove <- c("time","contime","subID") #remove original time, continuous time, and subID in order to feed into GIMME
  datad1 <- datad1[, !(names(datad1) %in% remove)]
  savefile <- paste0 ("finaloutput/", i, ".csv", sep = "") #save final preprocessed step here to a folder you name 'finaloutput' (or change the name to what you would like)
  write.csv(datad1, file = savefile, row.names = FALSE)
  print(paste("Dataframe Saved:", i))
}
## Pre-processing Complete
##### ##### 

#2. Confirmatory groups GIMME analysis - clinical diagnostic subgroups
########################################################
#   CONFIRMATORY 2-GROUPS: ALL CLINICAL vs. HEALTHY    #
########################################################
csgimme2group <- read.csv("CS-2gimmeGroups.csv", header = FALSE) #read in clinical group assignments
csgimme2group <- as.data.frame(csgimme2group)

# check the assignments
str(csgimme2group)

outputcs2 <- gimme(data = "finaloutput", #folder with individual pre-processed data files named by ID
                   out = "2CS-GIMME_output",  #folder to save output
                   sep = ",",            
                   header = TRUE,        
                   subgroup = TRUE,        
                   confirm_subgroup = csgimme2group, #confirmatory assignments of clinical diagnostic group
                   exogenous = "TimeofDay", #diurnal time of day
                   groupcutoff = .75,       
                   subcutoff = .51         
)        

# get the Q-value for outputcs2
outputcs2[["fit"]][["modularity"]][1]
# -0.0041

########################################################
#   CONFIRMATORY 3-GROUPS: MDD vs. BPD vs. HEALTHY     #
########################################################
csgimme3group <- read.csv("CS-3gimmeGroups.csv", header = FALSE)
csgimme3group <- as.data.frame(csgimme3group)

outputcs3 <- gimme(data = "finaloutput",
                   out = "3CS-GIMME_output",  
                   sep = ",",            
                   header = TRUE,        
                   subgroup = TRUE,        
                   confirm_subgroup = csgimme3group, 
                   exogenous = "TimeofDay",
                   groupcutoff = .75,       
                   subcutoff = .51         
)    

# get the Q-value for outputcs3
outputcs3[["fit"]][["modularity"]][1]
# -0.0037

###############################################################
#   CONFIRMATORY 4-GROUPS: MDD vs. REM vs. BPD vs. HEALTHY    #
###############################################################
csgimme4group <- read.csv("CS-4gimmeGroups.csv", header = FALSE)
csgimme4group <- as.data.frame(csgimme4group)

outputcs4 <- gimme(data = "finaloutput",
                   out = "4CS-GIMME_output",  
                   sep = ",",            
                   header = TRUE,        
                   subgroup = TRUE,        
                   confirm_subgroup = csgimme4group, 
                   exogenous = "TimeofDay",
                   groupcutoff = .75,       
                   subcutoff = .51         
)    

# get the Q-value for outputcs4
outputcs4[["fit"]][["modularity"]][1]
# -0.0075

#3. Data-driven groups GIMME analysis - data-driven subgroups
##################################
##     S-GIMME, DATA-DRIVEN     ##
##################################

sgimmefit <- gimme(data = "finaloutput", #folder with individual pre-processed data files named by ID
                   out = "datadrivenGIMME_output", #folder to save output
                   sep = ",",
                   header = TRUE,
                   ar = TRUE,
                   plot = TRUE,
                   subgroup = TRUE,
                   paths = NULL, 
                   exogenous = "TimeofDay",
                   groupcutoff = .75, 
                   subcutoff   = .51) 

# get the Q-value for data-driven groups
sgimmefit[["fit"]][["modularity"]][1]
# 0.1

# The output directory will contain:

# indivPathEstimates: Contains estimate, standard error, p-value, and z-value for each path and each individual
# summaryFit: Contains model fit information for individual-level models. If subgroups are requested, this file also indicates the subgroup membership for each individual.
# summaryPathCountMatrix: Contains counts of total number of paths, both contemporaneous and lagged, estimated for the sample. The row variable is the outcome and the column variable is the predictor variable.
# summaryPathCounts: Contains summary count information for paths identified at the group-, subgroup (if subgroup = TRUE), and individual-level.
# summaryPathPlot: Produced if plot = TRUE. Contains figure with group, subgroup (if subgroup = TRUE), and individual-level paths for the sample. Black paths are group-level, green paths are subgroup-level, and grey paths are individual-level, where the thickness of the line represents the count.
# similarityMatrix: the similarity matrix used to arrive at data-drive subgroups.
# The subgroup output directory (if subgroup = TRUE) will contain:
#   
# subgroupkPathCounts: Contains counts of relations among lagged and contemporaneous variables for the kth subgroup
# subgroupkPlot: Contains plot of group, subgroup, and individual level paths for the kth subgroup. Black represents group-level paths, grey represents individual-level paths, and green represents subgroup-level paths.
# Note: if a subgroup of size n = 1 is discovered, subgroup-level output is not produced. Subgroups of size one can be considered outlier cases
# In individual output directory (where id represents the original file name for each individual):
#   
# idBetas: Contains individual-level estimates of each path for each individual.
# idStdErrors: Contains individual-level standard errors for each path for each individual.
# idPlot: Contains individual-level plots. Red paths represent positive weights and blue paths represent negative weights.

#4. Final GIMME solution evaluation
##########
#ROBUSTNESS VALUES FOR S-GIMME SUBGROUP SOLUTION
##########
#############################################################################
#method 1: looking at robustness of solution to minor perturbation of edges
#############################################################################
similarity <- as.matrix(read.csv("datadrivenGIMME_output/similarityMatrix.csv", header = F)) #read in similarity matrix
evaluatecorr1 <- perturbR(sym.matrix = similarity)
#The VI value for when 20% of nodes are randomly switched:
evaluatecorr1$vi20mark
#The index for when this occurred for the first time in results
min(which(colMeans(evaluatecorr1$VI)>evaluatecorr1$vi20mark))
#The alpha/percent that corresponds with this index:
evaluatecorr1$percent[min(which(colMeans(evaluatecorr1$VI)>evaluatecorr1$vi20mark))]
#  0.4331502
#the ARI values:
evaluatecorr1$ari20mark 
mean(evaluatecorr1$ARI[,which(round(evaluatecorr1$percent, digits = 2) == .20)])
# 0.6441231
