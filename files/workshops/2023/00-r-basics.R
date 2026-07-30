# R Workshop -- Basic Data Analysis
# January 13, 2023
# Yingying Tang

########## THE MOST IMPORTANT THING: How to use help in R #########
# 1.(recommended) Use the 'help()' function; Use the '?' operator; Use 'F1' keyboard shortcuts
help("summary")
?"summary"
?base::summary
# move cursor to the name of the function, then press F1 (or Fn+F1)
summary
# 2. Find corresponding R package under the "Packages" window, better use the search bar
# 3. (not recommended) Find reference manual on the CRAN website: https://cran.r-project.org/
#the R packages update fast and the downloaded manual may be outdate


# How to write and run code --------------------------------------------------------
# Assignment operator: 
# <- assign values ( = can also assign values, but it doesn’t store the used values outside of a function)
  # Mac shortcut: "option" + "-"
  # Windows shortcut: "alt" + "-"

# How to run a line of code:
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
install.packages("tidyverse")
install.packages("haven")
install.packages("psych")

# load libraries 
library(tidyverse) #Opinionated collection of R packages designed for data science
library(haven) #Enables R to read and write various data formats used by other statistical packages
library(psych) #Include functions most useful for personality and psychological research

# Objects: They save stuff for you ----------------------------------------
# object <- fuction(x)
# which means ‘object is created from function(x)’. 
# An object is anything created in R. 
# It could be a variable, a collection of variables, a statistical model, etc.

a <- 5
a

# Functions: They do stuff for you ----------------------------------------
# c() Function: Combine things like thing1, thing2, thing3, …
# “c” stands for combine. Use this to combine values into a vector.
# read: combine 1, 2, 3, 4, 5 and "save to", <-, five_numbers
five_numbers <- c(1, 2, 3, 4, 5)

# print five_numbers by just excecuting/running the name of the object
five_numbers

# Piping, %>%: Write code kinda like you write sentences
# The %>% operator allows you to “pipe” a value forward into an expression or function; 
# something along the lines of x %>% f, rather than f(x). 
# keyboard shortcuts: Ctrl+Shift+M
five_numbers %>% scale()

# Exercise 1 --------------------------------------------------------------
six_numbers <- c(1, 2, 3, 4, 5, "6")
# Compute z-scores for those six numbers, called six_numbers, and then compute the mean
# Functions you may use: typeof(), as.numeric(), mean(), scale()
# Reminder: only numbers can be computed
# use "help" to find how to use these functions


# Exercise 1 Answer -------------------------------------------------
typeof(six_numbers) #"six numbers" is a character object so it can't be calculated
# correct order: convert six_numbers into numbers, and then compute z-scores for five_numbers, and then compute the mean
six_numbers %>% as.numeric() %>% scale() %>% mean() 
