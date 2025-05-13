# Author: Eric Pfaffenbach
# Description: Created a negative binomial model and removed variables with high
# multicollinearity.

rm(list = ls()) 

# import libraries
library(ggplot2)
library(dplyr)
library(tidyverse)
library(lubridate)
library(haven)
library(MASS)
library(car)

# Read in the new CSV file with the clean data code
visits_household_year = read.csv("data/visits_household_year.csv")

# Plot histogram of number of visits per household-year
ggplot(visits_household_year, aes(x = num_visits)) +
  geom_histogram(binwidth = 1, fill = "steelblue", color = "white") +
  scale_x_continuous(breaks = seq(0, max(visits_household_year$num_visits), by = 5)) +
  labs(title = "Distribution of Number of Visits", x = "Number of Visits", y = "Count")

# Summary statistics and frequency table for number of visits
summary(visits_household_year$num_visits)
table(visits_household_year$num_visits)

# As we can see, num_visits is extremely right skewed. Let's use a Negative Binomial Regression Model
# Preprocessing: ungroup, remove ID, convert character columns to factors, and drop missing values (got help from ChatGPT for this code)
df <- visits_household_year %>%
  dplyr::ungroup() %>%
  dplyr::select(-afn) %>%
  mutate(across(where(is.character), as.factor)) %>%
  na.omit()

# Inspect structure and summary of outcome variable
str(df)
summary(df$num_visits)

# Fit initial Negative Binomial regression model
nb_model <- glm.nb(num_visits ~ . - zip - served_year - served_month, data = df)
summary(nb_model)

# Most predictors are statistically significant at common significance levels

# Check for Multicollinearity:
vif(nb_model)

# Variables 'n_elderly' and 'n_household' show high multicollinearity; remove 'n_elderly'
nb_model2 <- glm.nb(num_visits ~ . - zip - served_year - served_month - n_elderly, data = df)
summary(nb_model2)

# Re-check VIF after removing 'n_elderly'
vif(nb_model2)

# Refine model by removing additional less significant variables:
# homeless, n_american_Indian, n_child, n_female
nb_model3 <- glm.nb(num_visits ~ . - zip - served_year - served_month - n_elderly - homeless - n_american_Indian - n_child - n_female, data = df)
summary(nb_model3)

# Final model summary: 
# Variables with strongest significance include snap_household, n_household, and fed_poverty_level