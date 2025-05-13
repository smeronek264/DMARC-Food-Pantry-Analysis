# Author: Nathan Oelsner
# Description: Created a time series model to predict the number of visits
# Also created a dummy variable to account of COVID years.  This is grouped
# by the zipcodes to see if there are different trends.

rm(list = ls())
library(tidyverse)
library(lubridate)
library(haven)
library(dplyr)
library(ggplot2)
library(purrr)

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


# Add Dummy Variable to account for 2020-2022
household_visit <- household_visit %>%
  mutate(covid_period = ifelse(served_date >= "2020-03-01" & served_date <= "2022-06-30", 1, 0))



monthly_counts_by_zip <- household_visit %>% 
  group_by(zip, round_month) %>% 
  summarise(num_VISITS = n(),
            num_PEOPLE_SERVED = sum(n_household),
            covid_period = first(covid_period),
            .groups = "drop"
  ) %>%
  ungroup()

# Add a time index for each ZIP (e.g., 1 to N months per ZIP)
monthly_counts_by_zip <- monthly_counts_by_zip %>%
  group_by(zip) %>%
  arrange(round_month) %>%
  mutate(Time = row_number()) %>%
  ungroup()


# Split data by ZIP
data_by_zip <- split(monthly_counts_by_zip, monthly_counts_by_zip$zip)

# Fit models
models_by_zip <- map(data_by_zip, ~ lm(num_VISITS ~ Time + covid_period, data = .x))

predictions_by_zip <- map2(data_by_zip, models_by_zip, ~ {
  .x$predicted <- predict(.y, newdata = .x)
  .x  # return df with predictions
})


top_zips <- household_visit %>%
  group_by(zip) %>%
  summarise(total_visits = n()) %>%
  arrange(desc(total_visits)) %>%
  slice_head(n = 6) %>%
  pull(zip)

top_zips


top_zip_data <- monthly_counts_by_zip %>% 
  filter(zip %in% top_zips)




# Plot a ZIP
zip_to_plot <- "50317"  # or any ZIP in your data
df_plot <- predictions_by_zip[[zip_to_plot]]

plot(df_plot$round_month, df_plot$num_VISITS, type = "p", col = "blue",
     xlab = "Month", ylab = "Number of Visits", main = paste("ZIP", zip_to_plot))
lines(df_plot$round_month, df_plot$predicted, col = "red", lwd = 2)







# Step 1: Get top 10 ZIPs again
top_zips <- monthly_counts_by_zip %>%
  group_by(zip) %>%
  summarise(total_visits = sum(num_VISITS)) %>%
  arrange(desc(total_visits)) %>%
  slice_head(n = 9) %>%
  pull(zip)

# Step 2: Build prediction data for each zip
predicted_zip_data <- map_dfr(top_zips, function(z) {
  df <- monthly_counts_by_zip %>% filter(zip == z) %>% arrange(round_month)
  last_time <- max(df$Time)
  
  # Fit model
  model <- lm(num_VISITS ~ Time + covid_period, data = df)
  
  # Actual fitted values
  df$predicted <- predict(model, newdata = df)
  
  # Create future data (e.g., next 12 months)
  future_time <- (last_time + 1):(last_time + 12)
  future_df <- data.frame(
    Time = future_time,
    covid_period = 0
  )
  future_df$predicted <- predict(model, newdata = future_df)
  future_df$zip <- z
  future_df$round_month <- max(df$round_month) + months(1:12)
  future_df$num_VISITS <- NA
  
  # Combine actual + future
  bind_rows(df, future_df)
})



ggplot(predicted_zip_data, aes(x = round_month, y = num_VISITS)) +
  geom_line(color = "steelblue") +
  geom_line(aes(y = predicted), color = "red", linetype = "solid") +
  facet_wrap(~ zip, ncol = 3, scales = "free_y") +  # change ncol as needed
  labs(title = "Monthly Food Pantry Visits by Top ZIP Codes",
       x = "Month",
       y = "Number of Visits") +
  theme_minimal() +
  theme(
    strip.text = element_text(size = 10, face = "bold"),
    axis.text.x = element_text(angle = 45, hjust = 1)
  )



# Get top 10 zips again
top_zips <- monthly_counts_by_zip %>%
  group_by(zip) %>%
  summarise(total_visits = sum(num_VISITS)) %>%
  arrange(desc(total_visits)) %>%
  slice_head(n = 9) %>%
  pull(zip)

# Extract model coefficients for each ZIP
zip_model_equations <- map_dfr(top_zips, function(z) {
  df <- monthly_counts_by_zip %>% filter(zip == z) %>% arrange(round_month)
  model <- lm(num_VISITS ~ Time + covid_period, data = df)
  coefs <- coef(model)
  
  tibble(
    zip = z,
    time_coef = round(coefs[["Time"]], 2),
  )
})

zip_growth_rates_ordered <- zip_model_equations %>%
  arrange(desc(time_coef))
print(zip_growth_rates_ordered)