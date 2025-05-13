# Author: Sophie Meronek
# Description: This code creates different visualizations of how the pantries 
# by the number of new visitors.
# Disclaimer: This was organized by CHATGPT

rm(list = ls()) 

# ============================================================
# LOAD LIBRARIES
# ============================================================

# Install required packages if not already installed
# install.packages(c("ggmap", "dplyr", "ggplot2", "scales", "viridis", "lubridate", "tidyr"))

library(ggmap)
library(dplyr)
library(ggplot2)
library(scales)
library(viridis)
library(lubridate)
library(tidyr)

source("src/clean_data_code/new_data_clean.R")

# ============================================================
# 1. TOP 5 PANTRIES BY TOTAL HOUSEHOLDS SERVED OVERALL
# ============================================================

# Find top 5 pantry locations by total number of households served
top_pantries <- pantry_visit %>%
  group_by(location) %>%
  summarise(numHouse = sum(numHouse), .groups = 'drop') %>%
  arrange(desc(numHouse)) %>%
  slice_head(n = 5)

# Filter full data for those top 5 pantry locations
top_pantry_visit <- pantry_visit %>%
  filter(location %in% top_pantries$location)

# Time series plot for people served over time by top 5 pantries
ggplot(top_pantry_visit, aes(x = roundMonth, y = numPeople, color = location)) +
  geom_line(size = 1) +
  geom_point(size = 2) +
  labs(
    title = "Number of People Served Over Time by Top 5 Locations",
    x = "Month",
    y = "Number of People",
    color = "Location"
  ) +
  theme_minimal()

# ============================================================
# 2. TOP PANTRIES IN 2024
# ============================================================

# Filter data to only include records from 2024
pantry_visit2024 <- subset(pantry_visit, servedYear == 2024)

# Identify top locations in 2024 by total people served
top_pantries2024 <- pantry_visit2024 %>%
  group_by(location) %>%
  summarise(numPeople = sum(numPeople), .groups = 'drop') %>%
  arrange(desc(numPeople))

# Filter full dataset for these top pantries from 2022 onward
top_pantry_visit2024 <- pantry_visit %>%
  filter(location %in% top_pantries2024$location & servedYear >= 2022)

# Time series plot
ggplot(top_pantry_visit2024, aes(x = roundMonth, y = numPeople, color = location)) +
  geom_line(size = 1, alpha = 0.7) +
  geom_point(size = 2, alpha = 0.7) +
  labs(
    title = "Number of People Served Over Time by Location (Top 2024 Pantries)",
    x = "Month",
    y = "Number of People",
    color = "Location"
  ) +
  scale_x_date(
    breaks = seq(floor_date(min(top_pantry_visit2024$roundMonth), "year"),
                 ceiling_date(max(top_pantry_visit2024$roundMonth), "month"),
                 by = "6 months"),
    date_labels = "%b %Y"
  ) +
  scale_color_viridis_d(option = "D") +
  theme_minimal()

# ============================================================
# 3. TOP GROWTH LOCATIONS (2023 vs 2024)
# ============================================================

# Filter data for 2023 and 2024
difference2023_2024 <- pantry_visit %>%
  filter(servedYear %in% c(2023, 2024))

# Identify top 5 locations by absolute increase in people served
top5_locations <- difference2023_2024 %>%
  group_by(location, servedYear) %>%
  summarise(total_people = sum(numPeople, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = servedYear, values_from = total_people, names_prefix = "year_") %>%
  mutate(diff_people = year_2024 - year_2023) %>%
  arrange(desc(diff_people)) %>%
  slice_head(n = 5) %>%
  pull(location)

# Filter time series data for those top growth locations
top_diff_ts <- difference2023_2024 %>%
  filter(location %in% top5_locations)

# Time series plot for increase in people served
ggplot(top_diff_ts, aes(x = roundMonth, y = numPeople, color = location)) +
  geom_line(size = 1, alpha = 0.7) +
  geom_point(size = 2, alpha = 0.7) +
  labs(
    title = "Top 5 Locations by Increase in People Served (2023 vs 2024)",
    x = "Month",
    y = "Number of People",
    color = "Location"
  ) +
  scale_x_date(
    breaks = seq(floor_date(min(top_diff_ts$roundMonth), "year"),
                 ceiling_date(max(top_diff_ts$roundMonth), "month"),
                 by = "4 months"),
    date_labels = "%b %Y"
  ) +
  scale_color_viridis_d(option = "D") +
  theme_minimal()

# ============================================================
# 4. PROPORTIONAL GROWTH ANALYSIS (2023 to 2024)
# ============================================================

# Compute proportional growth in people served
prop_people_diff <- difference2023_2024 %>%
  group_by(location, servedYear) %>%
  summarise(total_people = sum(numPeople, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = servedYear, values_from = total_people, names_prefix = "year_") %>%
  mutate(
    diff_people = year_2024 - year_2023,
    prop_diff_people = (year_2024 - year_2023) / year_2023
  ) %>%
  arrange(desc(prop_diff_people)) %>%
  slice_head(n = 5)

# Filter for locations with top proportional growth
jump_people_pantry_visit <- pantry_visit %>%
  filter(location %in% prop_people_diff$location)

# Plot proportional growth time series
ggplot(jump_people_pantry_visit, aes(x = roundMonth, y = numPeople, color = location)) +
  geom_line(size = 1, alpha = 0.7) +
  geom_point(size = 2, alpha = 0.7) +
  labs(
    title = "Number of People Served Over Time (Top 5 Pantries by Proportional Growth)",
    x = "Month",
    y = "Number of People",
    color = "Location"
  ) +
  theme_minimal()

# ============================================================
# 5. SUMMARY TABLE OF PEOPLE AND HOUSEHOLD GROWTH
# ============================================================

# Compute growth in households served
house_diff <- difference2023_2024 %>%
  group_by(location, servedYear) %>%
  summarise(total_house = sum(numHouse, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = servedYear, values_from = total_house, names_prefix = "year_") %>%
  mutate(
    diff_house = year_2024 - year_2023,
    prop_diff_house = (year_2024 - year_2023) / year_2023
  )

# Combine people and household growth
final_diff <- left_join(prop_people_diff, house_diff, by = "location") %>%
  mutate(
    prop_diff_people = round(prop_diff_people * 100, 1),
    prop_diff_house = round(prop_diff_house * 100, 1)
  )

print(final_diff)