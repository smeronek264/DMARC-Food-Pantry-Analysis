# Author: Eric Pfaffenbach
# Description: Creates a line graph looking at the federal poverty level and 
# number of visits.

rm(list = ls()) 

# Load and execute Negative Binomial model script
source("src/models/neg_binom_model.R")

# Got help from ChatGPT with the code for the line plot and dataframe

# Create a new dataframe 'df_fine' with finer poverty level bins
df_fine <- df %>%
  filter(!is.na(fed_poverty_level)) %>%
  mutate(poverty_bin_fine = cut(fed_poverty_level,
                                breaks = c(0, 50, 100, 150, 200, 250, 300, Inf), # Define breakpoints for bins
                                labels = c("<50%", "50–100%", "100–150%", "150–200%", "200–250%", "250–300%", ">300%"))) # Assign labels to each bin

# Create a line plot showing average visits per poverty level group
df_fine %>%
  filter(!is.na(poverty_bin_fine)) %>%  # Remove NA rows
  group_by(poverty_bin_fine) %>%
  summarise(mean_visits = mean(num_visits, na.rm = TRUE)) %>% # Calculate mean number of visits per group
  ggplot(aes(x = poverty_bin_fine, y = mean_visits, group = 1)) +
  geom_line(color = "darkgreen", size = 1.2) +
  geom_point(color = "darkgreen", size = 3) +
  labs(
    title = "Average Visits by Federal Poverty Level Groups",
    x = "Federal Poverty Level",
    y = "Average Number of Visits"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(
      size = 18,        # Bigger font size
      face = "bold",    # Make title bold
      hjust = 0.5,      # Center title horizontally
      vjust = 1,        # Adjust vertical spacing of title
      margin = margin(b = 10)  # Add space below title
    ),
    plot.title.position = "panel"  # Title positioned within the panel area
  )