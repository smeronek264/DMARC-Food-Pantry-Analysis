# Author: Eric Pfaffenbach 
# Description: Looked into how many people have visited the pantries over time
# based on what zipcode they put down.

rm(list = ls()) 

# Load necessary libraries
library(tidyverse)
library(lubridate)  
library(haven)    
library(dplyr)   
library(viridis)  

# Read the CSV data into a data frame
visit <- read.csv("data/household_visit.csv")

# Count number of visits per ZIP code (truncated to 5 digits)
zip_counts <- visit %>%
  mutate(zip = substr(zip, 1, 5)) %>%  # Truncate ZIP to 5 characters
  group_by(zip) %>%
  summarise(count = n()) %>%
  arrange(desc(count))  # Sort in descending order of visit count

# Create a vector of all unique ZIP codes in the data
zip_vector <- sort(unique(visit$zip))  # Too many to analyze usefully all at once

# Identify top 5 ZIP codes by number of visits
zip_vector_top5 <- visit %>%
  mutate(zip = substr(zip, 1, 5)) %>%  # Truncate ZIP to 5 characters 
  group_by(zip) %>%
  summarise(count = n()) %>%
  arrange(desc(count)) %>%
  slice_head(n = 5) %>%  # Select top 5 ZIPs
  pull(zip)  # Extract the ZIP values into a vector

# Create a yearly summary table of visits by top 5 ZIP codes (got some help with this Code from ChatGPT)
zip_vector_yearly_counts <- visit %>%
  mutate(zip = substr(zip, 1, 5),         
         served_year = year(ymd(served_date))) %>%      
  filter(zip %in% zip_vector_top5,            
         served_year >= 2018 & served_year <= 2023) %>%   
  group_by(zip, served_year) %>%                  
  summarise(count = n(), .groups = 'drop') %>%     
  pivot_wider(names_from = served_year,            
              values_from = count, 
              values_fill = list(count = 0)) %>%
  arrange(zip)  # Sort by ZIP code

# Display the reshaped yearly ZIP code data table
zip_vector_yearly_counts

# LINE GRAPH (Code help from ChatGPT):

# Convert data to long format for ggplot
zip_vector_yearly_counts_long <- zip_vector_yearly_counts %>%
  pivot_longer(cols = -zip, names_to = "year", values_to = "count") %>%
  mutate(year = as.integer(year))  # Ensure year is numeric for plotting

# Create a line graph of visit trends by ZIP code
ggplot(zip_vector_yearly_counts_long, aes(x = year, y = count, group = zip, color = zip)) +
  geom_line(linewidth = 1) +  
  geom_point(size = 2) +  
  scale_color_manual(values = c("#E69F00", "#56B4E9", "#009E73", 
                                "#F0E442", "#0072B2", "#D55E00", "#CC79A7")) +  # Custom color palette
  labs(title = "Food Pantry Visits Over Time", 
       x = "Year",         
       y = "Visits",               
       color = "ZIP Code") +         
  theme_minimal() +                   
  theme(legend.position = "right",       
        plot.title = element_text(hjust = 0.5))
