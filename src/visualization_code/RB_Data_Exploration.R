# Author: Sophie Meronek 
# Description: This code will create different graphs of the Red Barrel data.
# The hope was to see any current trends while also looking for potential areas
# of expansion.

# Clear the environment
rm(list=ls())

# ---- 1. Load Required Packages ----
# These libraries are used for reading Excel files, data manipulation, date handling, and plotting.
library(readxl)      # for reading Excel files
library(tidyverse)   # for data wrangling and plotting (includes ggplot2, dplyr, etc.)
library(lubridate)   # for date/time manipulation
library(scales)      # for formatting plot axes, e.g., currency labels

# Load datasets for the years 2022, 2023, and 2024
source("src/clean_data_code/CLEANRB2022_Data.R")
source("src/clean_data_code/CLEANRB2023_Data.R")
source("src/clean_data_code/CLEANRB2024_Data.R")
# ---- 4. Aggregate and Summarize the Data ----

# Summarize total donation value and average donation per record by location for 2022
RB2022_store <- RB2022 %>%
  group_by(clean_location) %>%
  summarise(
    total_value = sum(VALUE, na.rm = TRUE),
    number_records = n()
  ) %>%
  mutate(avg_donation = total_value / number_records)

# Summarize total donation value by location for 2023
RB2023_store <- RB2023 %>%
  group_by(clean_location) %>%
  summarise(total_value = sum(VALUE, na.rm = TRUE))

# Summarize total and average donation value by location for 2024
RB2024_store <- RB2024 %>%
  group_by(clean_location) %>%
  summarise(
    total_value = sum(VALUE, na.rm = TRUE),
    count_entries = n()
  ) %>%
  mutate(avg_value_per_visit = total_value / count_entries)

# Combine all years for overall temporal trends
rb_all <- bind_rows(RB2022, RB2023, RB2024)

# Monthly donations split by year
# Used to analyze trends across months and compare year-to-year performance
month_counts <- rb_all %>%
  mutate(
    round_month = round_date(clean_Date, unit = "month"),
    month = month(clean_Date),
    year = year(clean_Date)
  ) %>%
  group_by(year, month) %>%
  summarise(month_value = sum(VALUE, na.rm = TRUE),
            round_month = first(round_month))

# Combined monthly donations (total for all years), used for seasonality detection
month_counts2 <- rb_all %>%
  mutate(round_month = round_date(clean_Date, unit = "month")) %>%
  group_by(month = month(clean_Date)) %>%
  summarise(month_value = sum(VALUE, na.rm = TRUE),
            round_month = first(round_month))

# Summarize total donations per location per year
rb_summary <- rb_all %>%
  mutate(year = year(clean_Date),
         clean_location_labels = clean_location) %>%
  group_by(clean_location_labels, year) %>%
  summarise(total_value = sum(VALUE, na.rm = TRUE), .groups = "drop")

# Identify top 10 locations by total donations across all years
top_10_locations <- rb_summary %>%
  group_by(clean_location_labels) %>%
  summarise(total_value = sum(total_value)) %>%
  top_n(10, wt = total_value) %>%
  pull(clean_location_labels)

# Filter summary to include only the top 10 locations
rb_top10 <- rb_summary %>%
  filter(clean_location_labels %in% top_10_locations)

# ---- 5. Generate Graphs for Data Analysis and Presentation ----

# Graph: Total Donations by Location in 2022
# Shows which locations contributed most to donations in 2022.
ggplot(RB2022_store) +
  geom_col(aes(x = reorder(clean_location, total_value), y = total_value)) +
  theme(axis.text.x = element_text(angle = 90)) +
  labs(title = "2022 Red Barrel Donations by Location",
       x = "Location", y = "Donation Value ($)")

# Graph: Total Donations by Location in 2023
# Same as above, but for 2023.
ggplot(RB2023_store) +
  geom_col(aes(x = reorder(clean_location, total_value), y = total_value)) +
  theme(axis.text.x = element_text(angle = 90)) +
  labs(title = "2023 Red Barrel Donations by Location",
       x = "Location", y = "Donation Value ($)")

# Graph: Total Donations by Location in 2024
# Bar chart showing which locations had the highest donation totals in 2024.
ggplot(RB2024_store) +
  geom_col(aes(x = reorder(clean_location, total_value), y = total_value), fill = "#009ddc") +
  theme(axis.text.x = element_text(angle = 90)) +
  labs(title = "2024 Red Barrel Donations by Location",
       x = "Location", y = "Donation Value ($)")

# Graph: Average Donation per Visit by Location in 2024
# Highlights how much, on average, each location generates per record.
ggplot(RB2024_store) +
  geom_col(aes(x = reorder(clean_location, avg_value_per_visit), y = avg_value_per_visit)) +
  theme(axis.text.x = element_text(angle = 90)) +
  labs(title = "2024 Avg Donation Value by Location",
       x = "Location", y = "Avg Value per Visit ($)")

# Graph: Monthly Donation Trends (2022–2024)
# Line chart showing donation amounts by month over time. Good for spotting trends and seasonality.
ggplot(month_counts, aes(x = round_month, y = month_value)) +
  geom_point() + geom_line() +
  labs(title = "Monthly Red Barrel Donations (2022–2024)",
       x = "Month", y = "Total Donation Value ($)") +
  theme_bw()

# Graph: Total Donations by Month (aggregated across years)
# Helps identify which months consistently bring in more donations across all years.
ggplot(month_counts2, aes(x = month(round_month), y = month_value)) +
  geom_point() + geom_line() +
  labs(title = "Combined Monthly Red Barrel Donations",
       x = "Month", y = "Total Donation Value ($)") +
  theme_bw()

# Graph: Total Donations by Location and Year
# Compares how each location performed across multiple years.
ggplot(rb_summary, aes(x = reorder(clean_location_labels, total_value), y = total_value, fill = as.factor(year))) +
  geom_col(position = "dodge") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 90)) +
  labs(title = "Donations by Location and Year",
       x = "Location", y = "Donation Value ($)", fill = "Year")

# Graph: Top 10 Locations by Year
# Focuses on the best-performing locations, broken down by year to highlight consistency or trends.
ggplot(rb_top10, aes(x = reorder(clean_location_labels, total_value), y = total_value, fill = as.factor(year))) +
  geom_col(position = "dodge") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 90)) +
  labs(title = "Top 10 Locations by Year",
       x = "Location", y = "Donation Value ($)", fill = "Year")

# Graph: Total Donations by Month (Chronological Order)
# Visualizes how much was raised each calendar month to detect seasonal donation patterns.
# Top 3 months are highlighted for emphasis.
rb_month <- rb_all %>%
  mutate(month = month(clean_Date, label = TRUE, abbr = FALSE)) %>%
  group_by(month) %>%
  summarise(total_value = sum(VALUE, na.rm = TRUE)) %>%
  ungroup() %>%
  mutate(month = factor(month, levels = month.name),
         color = if_else(total_value %in% sort(total_value, decreasing = TRUE)[1:3], "#E69F00", "#56B4E9"))

ggplot(rb_month, aes(x = month, y = total_value, fill = color)) +
  geom_bar(stat = "identity") +
  geom_text(aes(label = dollar(total_value)), vjust = -0.5, size = 3.5) +
  scale_y_continuous(labels = dollar) +
  scale_fill_identity() +
  labs(title = "Total Donations by Month",
       x = "Month", y = "Donation Value ($)") +
  theme_minimal()
