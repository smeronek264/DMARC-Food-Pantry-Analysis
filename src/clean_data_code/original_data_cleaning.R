# Authors: Sophie Meronek and Eric Pfaffenbach
# Description: This code will take in a csv file and will create 2 new csv files of 
# cleaned data. In order to clean the data we changed any column that was supposed
# to be a date into date format. Then we aggregated the data so it was looking
# at each household's visit.  Which we then used to look at the household level for 
# year.

# NOTE:
# The user will need to change the spots marked in lines 92 and 93 to include their own
# path.

rm(list = ls())  # Clear the environment

# Load required libraries
library(tidyverse)
library(lubridate)
library(haven)
library(dplyr)
library(MASS)
library(ggplot2)
library(car)

# Load raw data
all <- read.csv("data/raw_data/drake_export_v8_2024-02-13_100754_rev2_nolatlong.csv")

# Convert date columns to Date format
all$dob <- ymd(all$dob) 
all$served_date <- ymd(all$served_date) 

# Set invalid years in DOB to NA (outside reasonable bounds)
all$dob[year(all$dob) < 1900 | year(all$dob) > 2024] <- NA

#### INDIVIDUAL LEVEL VARIABLES ####

# Create binary indicators for demographic characteristics
all <- all %>%
  mutate(
    Female = ifelse(gender == "Woman (girl)", 1, 0),
    Child = ifelse(as.numeric(interval(dob, served_date)) < 18, 1, 0),
    Elderly = ifelse(as.numeric(interval(dob, served_date)) >= 60, 1, 0),
    Black = ifelse(race == "Black/African American", 1, 0),
    American_Indian = ifelse(race == "American Indian/Alaskan Native", 1, 0),
    Multi_Race = ifelse(race == "Multi-Race", 1, 0),
    Hispanic = ifelse(ethnicity == "Hispanic or Latino", 1, 0)
  )

# Create visit-level data (grouped by household and visit date)
household_visit <- all %>%
  group_by(afn, served_date) %>%
  summarise(
    afn = first(afn),
    snap_household = first(snap_household),
    annual_income = first(annual_income),
    fed_poverty_level = first(fed_poverty_level),
    homeless = first(homeless),
    n_household = n(),  # Number of individuals in the household on that visit
    zip = first(zip),  # All members share the same ZIP
    location = first(location),  # All visited the same location
    n_female = sum(Female),
    n_child = sum(Child),
    n_elderly = sum(Elderly),
    n_black = sum(Black),
    n_american_Indian = sum(American_Indian),
    n_multi_Race = sum(Multi_Race),
    n_hispanic = sum(Hispanic)
  ) %>%
  mutate(
    served_year = year(served_date),
    served_month = month(served_date),
    served_day_of_month = mday(served_date)
  )

# Aggregate data to household-year level
visits_household_year <- household_visit %>% 
  group_by(afn, served_year) %>% 
  summarise(
    afn = first(afn),
    num_visits = n(),  # Total number of visits that year
    snap_household = first(snap_household),
    annual_income = first(annual_income),
    fed_poverty_level = first(fed_poverty_level),
    homeless = first(homeless),
    n_household = first(n_household),  # Household size on one of the visits
    zip = first(zip),
    n_female = mean(n_female),  # Average number of females per visit
    n_child = mean(n_child),    # Average number of children per visit
    n_elderly = mean(n_elderly),  # Average number of elderly per visit
    n_black = mean(n_black),
    n_american_Indian = mean(n_american_Indian),
    n_multi_Race = mean(n_multi_Race),
    n_hispanic = mean(n_hispanic),
    served_year = first(served_year),
    served_month = factor(first(served_month), levels = 1:12, 
                          labels = c("January", "February", "March", "April", "May", "June", 
                                     "July", "August", "September", "October", "November", "December"))
  )

# These lines will create 2 csv files. This way the person running the code, will only
# need to run the cleaning code once.  This will also prevent the user from having to 
# wait for the code to run every single time they wish to check our results. 
write_csv(visits_household_year, "(update to your path)\\data\\visits_household_year.csv")
write_csv(household_visit, "(update to your path)\\data\\household_visit.csv")