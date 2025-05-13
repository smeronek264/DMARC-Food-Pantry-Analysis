# Author: Sophie Meronek
# Description: This code will take in the new data and clean the columns then aggregate
# the data into visit level then to pantry level.

rm(list = ls()) 

# Load required libraries
library(tidyverse)   # Includes ggplot2, dplyr, tidyr, readr, etc.
library(lubridate)   # For working with dates
library(haven)       # For reading SPSS, Stata, SAS files (not used here, but loaded)
library(dplyr)       # Data manipulation (redundant since loaded with tidyverse)
library(readr)       # Reading CSVs (redundant since loaded with tidyverse)

# Read in the dataset from CSV
all = read.csv("data/data_raw/DMARC Data 2018-2024 copy.csv")

# Truncate servedDate to just the date part (first 10 characters, e.g., "2023-01-01")
all$servedDate = substring(all$servedDate, 0, 10)

# Convert `dob` and `servedDate` to date format
all$dob <- ymd(all$dob) 
all$servedDate <- ymd(all$servedDate) 

# Create new binary indicator columns
all <- all %>%
  mutate(
    Female = ifelse(gender == "Woman (girl)", 1, 0),  # 1 if female, else 0
    Child = ifelse(as.numeric(interval(dob, servedDate)) < 18, 1, 0),  # 1 if under 18
    Elderly = ifelse(as.numeric(interval(dob, servedDate)) >= 60, 1, 0),  # 1 if 60 or older
    Black = ifelse(race == "Black/African American", 1, 0),  # 1 if Black
    American_Indian = ifelse(race == "American Indian/Alaskan Native", 1, 0),  # 1 if AI/AN
    Multi_Race = ifelse(race == "Multi-Race", 1, 0),  # 1 if Multi-Race
    foodstamps = ifelse(foodstamps == "Yes", 1, 0)  # Convert foodstamps to binary
  )

# Remove irrelevant or identifying columns
selected_col_data <- all[, !(names(all) %in% c("primaryKey", "clientId", "middleName", "locationLat", "locationLng"))]

# Aggregate to the visit level by household ID and date
visit_level = selected_col_data %>% 
  group_by(servedDate, houseHoldIdAfn) %>% 
  summarise(
    afn = first(houseHoldIdAfn),  # Household ID
    foodstamps = first(foodstamps),  # Take first instance of foodstamps indicator
    annualIncome = first(annualIncome),  # First income value
    fedPovertyLevel = first(fedPovertyLevel),  # First poverty level
    householdMembers = first(householdMembers),  # Size of household
    location = first(location),  # Pantry location
    # Demographic summaries (summing across household members)
    n_female = sum(Female),
    n_child = sum(Child),
    n_elderly = sum(Elderly),
    n_black = sum(Black),
    n_american_Indian = sum(American_Indian),
    n_multi_Race = sum(Multi_Race)
  ) %>%
  # Create new date features
  mutate(
    servedYear = year(servedDate),
    servedMonth = month(servedDate),
    servedDayOfMonth = mday(servedDate),
    roundMonth = floor_date(servedDate, unit = "month")  # Round date to first of the month
  )

# Summarise at the pantry location & month level
pantry_visit = visit_level %>% 
  group_by(location, servedMonth, servedYear) %>% 
  summarise(
    numPeople = sum(householdMembers),  # Total number of people served
    numHouse = n(),  # Number of household visits
    location = first(location),
    roundMonth = first(roundMonth),  # Month bucket
    # Average metrics across visits
    foodstamps = mean(foodstamps),
    annualIncome = mean(annualIncome),
    fedPovertyLevel = mean(fedPovertyLevel),
    householdMembers = mean(householdMembers),  # Average household size
    # Average demographic composition per visit
    n_female = mean(n_female),
    n_child = mean(n_child),
    n_elderly = mean(n_elderly),
    n_black = mean(n_black),
    n_american_Indian = mean(n_american_Indian),
    n_multi_Race = mean(n_multi_Race)
  )
