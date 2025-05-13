# Author: Nolan Henze
# Description: This code is looking at SNAP and Income and how they interact with 
# each other. The code utilizes random forests to do so.

rm(list = ls())

library(tidyverse)    
library(lubridate)    
library(ggplot2)      
library(data.table)   
library(randomForest)

# 1. Load the data from a CSV file and clean it
all <- read.csv("data/drake_export_v8_2024-02-13_100754_rev2_nolatlong.csv.crdownload") %>%
  mutate(
    served_date = ymd(served_date),
    dob = ymd(dob)                   
  )

# 2. Count the number of visits by year and calculate average income per year
count_by_year <- all %>%
  mutate(year = lubridate::year(served_date)) %>%  # Extract the year from the served_date column
  group_by(year) %>%  # Group the data by year
  summarise(
    count_served = n(),  # Count the number of visitors in each year
    average_income = mean(annual_income, na.rm = TRUE)  # Calculate the average income for each year, ignoring NAs
  ) %>%
  ungroup() %>%
  mutate(
    baseline_income = average_income[year == 2018],  # Use the average income of 2018 as the baseline
    cum_percent_change = round(((average_income - baseline_income) / baseline_income) * 100, 1)  # Calculate the cumulative percentage change in income compared to 2018
  ) %>%
  select(year, count_served, average_income, cum_percent_change)  # Select relevant columns

# 3. Create data frame for food inflation by year
food_inflation <- data.frame(
  year = 2018:2024,  # Inflation data for years 2018 to 2024
  food_inflation = c(0, 1.9, 5.3, 9.2, 19.1, 24.9, 27.2)  # Manual inflation percentage values
)

# 4. Create a data frame of visits by year
visits <- data.frame(
  year = count_by_year$year,
  visits = count_by_year$count_served
)

# 5. Merge visits with food inflation and cumulative income change
visits_with_inflation <- visits %>%
  merge(food_inflation, by = "year") %>%  # Merge visits data with food inflation
  merge(count_by_year[, c("year", "cum_percent_change","average_income")], by = "year") %>%  # Add cumulative income change
  mutate(income_vs_inflation = cum_percent_change - food_inflation)  # Calculate the difference between income change and food inflation

# 6. Prepare data for plot excluding 2018 and 2024
plot_data <- visits_with_inflation %>%
  filter(year != 2018, year != 2024)  # Remove data for 2018 and 2024

# 7. Determine maximum values for scaling the chart
max_visits <- max(plot_data$visits, na.rm = TRUE)  # Max visits
max_income_vs_inflation <- max(abs(plot_data$income_vs_inflation) + 3.6, na.rm = TRUE) 

# 8. Create a bar and line plot comparing visits and income vs food inflation
ggplot(plot_data, aes(x = year)) +
  geom_bar(aes(y = visits), stat = "identity", fill = "skyblue", alpha = 0.7) +  # Bar plot for visits
  geom_line(
    aes(y = income_vs_inflation * max_visits / max_income_vs_inflation),  # Line plot for income vs inflation scaled to visit count
    color = "darkgreen", size = 1.5, group = 1
  ) +
  scale_y_continuous(
    name = "Visits",
    sec.axis = sec_axis(
      ~ . * max_income_vs_inflation / max_visits,  # Secondary axis for income vs inflation
      name = "Avg Income - Food Inflation (%)"
    )
  ) +
  labs(
    title = "Visits vs Vistor Avg Buying Power",
    x = "Year"
  ) +
  theme_minimal()

# 9. Prepare data for SNAP status transitions (whether visitors joined or left SNAP)
all_clean <- all %>%
  mutate(
    served_date = ymd(served_date),
    snap = tolower(snap_household) %in% c("yes", "y", "true", "1"),  # Create a logical variable for SNAP status
    quarter = floor_date(served_date, "quarter")  # Create quarter variable from served_date
  )

# 10. Use data.table for efficient data manipulation
dt <- as.data.table(all)
dt[, snap := tolower(snap_household) %in% c("yes", "y", "true", "1")]
dt[, quarter := as.Date(cut(served_date, "quarter"))]
setorder(dt, afn, served_date)
dt[, snap_lag := shift(snap, 4), by = afn]
dt[, transition_from := fifelse(snap_lag == TRUE & snap == FALSE, "kicked_off_snap",
                                fifelse(snap_lag == FALSE & snap == TRUE, "switch_to_snap", NA_character_))]
dt[, transition_to := fifelse(snap_lag == TRUE & snap == FALSE, "off_snap",
                              fifelse(snap_lag == FALSE & snap == TRUE, "on_snap", NA_character_))]
dt[, status := fifelse(!is.na(snap_lag) & !snap_lag & snap, "switch_to_snap",
                       fifelse(!is.na(snap_lag) & snap_lag & !snap, "kicked_off_snap",
                               fifelse(snap, "on_snap",
                                       fifelse(!is.na(snap_lag) & !snap, "off_snap", "off_snap"))))]

df_snap_transitions2 <- as.data.frame(dt)

# 11. Count the number of transitions by SNAP status and quarter
count_by_status <- df_snap_transitions2 %>%
  group_by(quarter, status) %>%
  summarise(n = n(), .groups = "drop") %>%
  mutate(status = recode(status,
                         on_snap = "On SNAP",
                         off_snap = "Off SNAP",
                         switch_to_snap = "Joined SNAP",
                         kicked_off_snap = "Left SNAP"))

# 12. Plot the number of people in each SNAP status by quarter
ggplot(count_by_status, aes(x = quarter, y = n, fill = status)) +
  geom_col(position = "stack") +  # Stacked bar plot for each status
  labs(title = "SNAP Status by Quarter", x = "Quarter", y = "Number of People") +
  scale_fill_manual(values = c(
    "On SNAP" = "#2B8CBE",
    "Joined SNAP" = "#D0D1E6",
    "Left SNAP" = "#FF6347",
    "Off SNAP" = "#74A9CF"
  )) +
  theme_minimal() +
  theme(legend.position = "top")

# 13. Summarize demographic information for each visitor going based upon their first visit
demo_summary <- all %>%
  arrange(afn, served_date) %>%
  group_by(afn) %>%
  summarise(
    gender = first(na.omit(gender)),  # First non-NA gender
    race = first(na.omit(race)),      # First non-NA race
    education = first(na.omit(education)),  # First non-NA education level
    family_type = first(na.omit(family_type)),  # First non-NA family type
    annual_income_median = median(annual_income, na.rm = TRUE),  # Median annual income
    fed_poverty_level_median = median(fed_poverty_level, na.rm = TRUE),  # Median federal poverty level
    .groups = "drop"
  )

# 14. Create a data frame of SNAP transitions by visitor
df_snap_transitions <- all %>%
  select(afn, snap_household, served_date) %>%
  mutate(snap = tolower(snap_household) %in% c("yes", "y", "true", "1")) %>%
  arrange(afn, served_date) %>%
  group_by(afn) %>%
  mutate(
    snap_lag = lag(snap),  # Get the lagged SNAP status
    kicked_off_snap = if_else(snap_lag == TRUE & snap == FALSE, TRUE, FALSE)  # Identify kicked-off status
  ) %>%
  ungroup()

# 15. Get the dates when visitors were kicked off SNAP
kicked_off_dates <- df_snap_transitions %>%
  filter(kicked_off_snap == TRUE) %>%
  group_by(afn) %>%
  summarise(kickoff_date = min(served_date), .groups = "drop")  # Get the first date kicked off

# 16. Join visitor data with kicked-off dates and calculate visits before and after kick-off
visits_with_kickoff <- all %>%
  select(afn, served_date, annual_income, fed_poverty_level, gender, race, education, family_type, zip) %>%
  inner_join(kicked_off_dates, by = "afn") %>%
  mutate(
    period = case_when(
      served_date < kickoff_date ~ "before",  # Period before kicked off
      served_date > kickoff_date ~ "after",   # Period after kicked off
      TRUE ~ NA_character_ 
    )
  ) %>%
  filter(!is.na(period))  # Remove rows with NA periods

# 17. Summarize visit counts per period (before and after being kicked off)
visits_summary <- visits_with_kickoff %>%
  group_by(afn, period) %>%
  summarise(
    visits = n(),  # Total visits per period
    years = as.numeric(difftime(max(served_date), min(served_date), units = "days")) / 365.25,  # Years between first and last visit
    .groups = "drop"
  ) %>%
  filter(years > 0) %>%  # Filter out records with less than 1 year of visits
  mutate(visits_per_year = visits / years)  # Calculate visits per year

# 18. Pivot the data to compare before and after visits
visits_wide <- visits_summary %>%
  pivot_wider(
    names_from = period,
    values_from = c(visits, years, visits_per_year),
    names_sep = "_"
  ) %>%
  filter(
    visits_before >= 1,
    visits_after >= 1
  ) %>%
  mutate(
    visits_total = visits_before + visits_after,  # Total visits before and after
    visit_difference = visits_per_year_before - visits_per_year_after  # Difference in visits per year before and after
  )

# 19. Join demographic summary to visits data
visits_wide <- visits_wide %>%
  left_join(demo_summary, by = "afn")

# 20. Build a random forest model to predict visit differences based on various variables
visits_wide$gender <- factor(visits_wide$gender)
visits_wide$race <- factor(visits_wide$race)
visits_wide$education <- factor(visits_wide$education)
visits_wide$family_type <- factor(visits_wide$family_type)

set.seed(3344)
train.idx <- sample(1:nrow(visits_wide), size = 0.7 * nrow(visits_wide))  # Randomly split into train/test

train.df <- visits_wide[train.idx, ]  # Training data
test.df <- visits_wide[-train.idx, ]  # Testing data

# 21. Train a random forest model to predict visit difference
set.seed(468)
rf_model <- randomForest(
  visit_difference ~ . - afn,  # Predict visit_difference excluding id
  data = train.df,
  ntree = 1000,  # Number of trees in the forest
  mtry = 4,      # Number of variables to consider at each split
  importance = TRUE  # Calculate variable importance
)

# 22. Plot variable importance from the random forest model
varImpPlot(rf_model, type = 1)

# 23. Create a data frame for variable importance and plot it
vi <- as.data.frame(importance(rf_model, type = 1))
vi$Variable <- rownames(vi)

vi <- vi %>%
  filter(!Variable %in% c("gender", "visits_per_year_before", "years_after", 
                          "years_before", "visits_per_year_after", 
                          "visits_before", "visits_after", "visits_total"))

# Plot variable importance from the random forest model
ggplot(vi, aes(x = reorder(Variable, `%IncMSE`), y = `%IncMSE`)) +
  geom_col() +  # Create a bar chart of variable importance
  coord_flip() +  # Flip the axes to make the labels readable
  labs(
    title = "Variable Importance in Predicting Post-SNAP User Visits",  # Add title
    x = "Variables",  # X-axis label
    y = "Increase in MSE (%)"  # Y-axis label
  ) +
  theme_minimal()

# Create a 'year' column based on the 'served_date' column
all <- all %>%
  mutate(year = year(served_date))

# Calculate the percentage of visitors with 0 income by year
zero_income_by_year <- all %>%
  group_by(year) %>%  # Group data by year
  summarise(
    total_visitors = n(),  # Count total visitors for each year
    zero_income_visitors = sum(annual_income == 0, na.rm = TRUE)  # Count visitors with zero income
  ) %>%
  mutate(percent_zero_income = round(100 * zero_income_visitors / total_visitors, 1))  # Calculate percentage of zero income visitors

# Plot the percentage of visitors with zero income by year
ggplot(zero_income_by_year, aes(x = factor(year), y = percent_zero_income)) +
  geom_col(fill = "#FF9999") +  # Bar chart with a custom color
  labs(
    title = "Percent of Visitors with $0 Annual Income by Year",  # Add title
    x = "Year",  # X-axis label
    y = "Percent with $0 Income"  # Y-axis label
  ) +
  theme_minimal()  # Use minimal theme for clean visualization

# Get the first annual income and total visits per visitor
visits_per_visitor <- all %>%
  group_by(afn) %>%  # Group by id
  summarise(
    total_visits = n(),  # Count total visits per visitor
    first_income = first(na.omit(annual_income)),
    .groups = "drop"
  )

# Group data by income group and calculate averages
avg_visits_by_income_group <- visits_per_visitor %>%
  mutate(income_group = if_else(first_income == 0, "Zero Income", "More Than Zero")) %>%  # Classify visitors into income groups
  group_by(income_group) %>%  # Group data by income group
  summarise(
    avg_visits = mean(total_visits),  # Calculate the average number of visits for each group
    n_visitors = n(),  # Count the number of visitors in each income group
    .groups = "drop"  # Ungroup after summarizing
  )

# Print the summary of average visits by income group
print(avg_visits_by_income_group)

# Calculate the standard deviation of income by year
income_sd_by_year <- all %>%
  mutate(year = year(served_date)) %>%  # Extract year from served_date
  group_by(year) %>%  # Group data by year
  summarise(
    income_sd = sd(annual_income, na.rm = TRUE),  # Calculate the standard deviation of income for each year
    .groups = "drop"  # Ungroup after summarizing
  )

# Print the standard deviation of income by year
print(income_sd_by_year)

# Assign income bracket by thirds based on first income value
visitor_income <- all %>%
  group_by(afn) %>%  # Group data by id
  summarise(
    first_income = first(na.omit(annual_income)),  # Get the first non-missing annual income for each visitor
    .groups = "drop"  # Ungroup after summarizing
  ) %>%
  filter(!is.na(first_income)) %>%  # Filter out missing income values
  mutate(
    income_bracket = ntile(first_income, 3)  # Assign visitors to income brackets (1 = bottom third, 3 = top third)
  )

# Count the number of visits per person per year
visits_by_year <- all %>%
  mutate(year = year(served_date)) %>%  # Extract year from served_date
  group_by(afn, year) %>%  # Group by id and year
  summarise(
    visits = n(),  # Count the number of visits for each visitor per year
    .groups = "drop"  # Ungroup after summarizing
  )

# Join income bracket data and calculate average visits per bracket per year
bracket_visits <- visits_by_year %>%
  left_join(visitor_income, by = "afn") %>%  # Join with income bracket data
  filter(!is.na(income_bracket)) %>%  # Filter out rows with missing income brackets
  group_by(year, income_bracket) %>%  # Group by year and income bracket
  summarise(
    avg_visits = mean(visits),  # Calculate the average number of visits for each income bracket per year
    n_visitors = n(),  # Count the number of visitors in each income bracket per year
    .groups = "drop"  # Ungroup after summarizing
  )

# Label the income brackets for clarity
bracket_visits <- bracket_visits %>%
  mutate(
    bracket_label = factor(
      income_bracket,
      levels = 1:3, 
      labels = c("Bottom Third", "Middle Third", "Top Third")  # Label the income brackets
    )
  )

bracket_visits <- bracket_visits %>%
  filter(year != 2024)

# Plot average visits per year by income bracket
ggplot(bracket_visits, aes(x = year, y = avg_visits, color = bracket_label)) +
  geom_line(size = 1.2) +
  labs(
    title = "Average Visits per Year by Income Bracket",
    x = "Year", 
    y = "Average Visits",  
    color = "Income Bracket"  
  ) +
  theme_minimal()
