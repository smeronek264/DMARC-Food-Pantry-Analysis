# Author: Nathan Oelsner
# Description: Created a time series model to predict the number of visits
# Also created a dummy variable to account of COVID years.

rm(list = ls())
library(tidyverse)
library(lubridate)
library(haven)
library(dplyr)

all <- read.csv(choose.files(), header=T) # File name is "Visit_Data"

# Ensure dob and served_date are in Date format and replace invalid years with NA
all$dob <- ymd(all$dob) 
all$served_date <- ymd(all$served_date) 


# Replace invalid years with NA
all$dob[year(all$dob) < 1900 | year(all$dob) > 2024] <- NA

#### PERSON

unique(all$education)

all <- all %>%
  mutate(
    Female = ifelse(gender == "Woman (girl)",1,0),
    Child = ifelse(as.numeric(interval(dob,served_date)) < 18, 1, 0),
    Elderly = ifelse(as.numeric(interval(dob,served_date)) >= 60, 1, 0),
    Black = ifelse(race == "Black/African American",1,0),
    American_Indian = ifelse(race == "American Indian/Alaskan Native",1,0),
    Multi_Race = ifelse(race == "Multi-Race",1,0),
    Hispanic = ifelse(ethnicity == "Hispanic or Latino",1,0)
  )

# Note: a visit is defined by unique combination of HOUSEHOLD and visit date.
# Create visit-level data frame:
household_visit <- all %>%
  group_by(afn, served_date) %>%
  # now, we take summarise to get the traits that make sense for a visit
  summarise(
    afn = first(afn),
    snap_household = first(snap_household),
    annual_income = first(annual_income),
    fed_poverty_level = first(fed_poverty_level),
    homeless = first(homeless),
    n_household = n(), # how many people for that afn on served_date (# in household)
    zip = first(zip), # because, by definition, they all have the same zip
    location = first(location), # because, all going to same location
    # surely there are more things you'd want to summarise
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
    served_day_of_month = mday(served_date),
    round_month = round_date(served_date, unit = "month")
  )

monthly_counts <- household_visit %>% 
  group_by(round_month) %>% 
  summarise(num_VISITS = n(),
            num_PEOPLE_SERVED = sum(n_household))

head(monthly_counts)



# Plot number of visits per month
plot(monthly_counts$round_month, monthly_counts$num_VISITS)

dim(monthly_counts)

# Make our own time variable from 1 to 74 (January 2018 to February 2024)
Time = 1:74
plot(Time, monthly_counts$num_VISITS)



# Make linear model that models number of visits over time
m1 = lm(monthly_counts$num_VISITS ~ Time)
summary(m1)
# It's poopoo. p-value is 0.983 and R^2 is basically 0

# Generate predictions
predictions_m1 <- predict(m1)

# Plot actual values
plot(Time, monthly_counts$num_VISITS, pch = 16, col = "blue",
     xlab = "Time", ylab = "Number of Visits", main = "Predictions Over Time")

# Add predicted values as a red line
lines(Time, predictions_m1, col = "red", lwd = 2)



# Add Dummy Variable to account for 2020-2022
household_visit <- household_visit %>%
  mutate(covid_period = ifelse(served_date >= "2020-03-01" & served_date <= "2022-06-30", 1, 0))

monthly_counts <- household_visit %>% 
  group_by(round_month) %>% 
  summarise(num_VISITS = n(),
            num_PEOPLE_SERVED = sum(n_household),
            covid_period = first(covid_period)) # Include COVID dummy

m1d = lm(num_VISITS ~ Time + covid_period, data = monthly_counts)
summary(m1d)

predictions_m1d <- predict(m1d)

# Plot actual vs predicted values
plot(Time, monthly_counts$num_VISITS, pch = 16, col = "blue",
     xlab = "Time", ylab = "Number of Visits", main = "Improved Model with COVID Adjustment")

# Add the new predictions as a red line
lines(Time, predictions_m1d, col = "red", lwd = 2)



# Convert Time index to actual dates (assuming it starts from Jan 2018)
start_date <- as.Date("2018-01-01")
Time_dates <- seq(start_date, by = "month", length.out = length(Time))

# Generate yearly intervals for x-axis
year_ticks <- seq(from = as.Date(format(min(Time_dates), "%Y-01-01")), 
                  to = as.Date(format(max(Time_dates), "%Y-01-01")), 
                  by = "year")

# Extend future_Time for future months (e.g., 12 months)
future_months <- 24
future_Time <- seq(max(Time) + 1, max(Time) + future_months, by = 1)  # Extend Time index

# Create a data frame for future data, including polynomial terms
future_data <- data.frame(
  Time = future_Time,
  covid_period = 0
)

# Predict future values using the model
future_predictions_m1d <- predict(m1d, newdata = future_data)

# Create future dates corresponding to the future Time
future_Time_dates <- seq(max(Time_dates) + 30, by = "month", length.out = future_months)

# Extend x-axis with future dates
future_year_ticks <- seq(from = as.Date(format(min(future_Time_dates), "%Y-01-01")),
                         to = as.Date(format(max(future_Time_dates), "%Y-01-01")),
                         by = "year")

# Find the minimum and maximum values of both actual and predicted data
y_min <- min(c(monthly_counts$num_VISITS, predictions_m1d, future_predictions_m1d))
y_max <- max(c(monthly_counts$num_VISITS, predictions_m1d, future_predictions_m1d))

# Plot actual data points with extended xlim to include future predictions
plot(Time_dates, monthly_counts$num_VISITS, pch = 16, col = "blue",
     xlab = "Year (Monthly Data Points)", ylab = "Number of Visits", main = "Monthly DMARC Food Pantry Visits Over Time",
     xaxt = "n", xlim = c(min(Time_dates), max(future_Time_dates)), 
     ylim = c(y_min, y_max), las = 1)

# Custom yearly x-axis labels
year_ticks_combined <- c(year_ticks, future_year_ticks)  # Combine original and future ticks
axis(1, at = year_ticks_combined, labels = format(year_ticks_combined, "%Y"))

# Add the prediction line for the actual modeled data
lines(Time_dates, predictions_m1d, col = "red", lwd = 2)

# Add the future predictions as a dashed red line
lines(future_Time_dates, future_predictions_m1d, col = "red", lwd = 2, lty = 2)  # Dashed red line for future predictions
