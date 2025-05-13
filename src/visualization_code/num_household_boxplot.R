# Load and execute Negative Binomial model script
source("src/models/neg_binom_model.R")

# Create a new categorical variable 'hh_group' by binning the 'n_household' variable into groups
df$hh_group <- cut(df$n_household,
                   breaks = c(0, 2, 4, 6, Inf),           
                   labels = c("1–2", "3–4", "5–6", "7+")) 

# Generate a boxplot showing the distribution of 'num_visits' for each 'hh_group'
ggplot(df, aes(x = hh_group, y = num_visits)) + 
  geom_boxplot(fill = "lightblue", outlier.shape = NA) +   
  coord_flip() +                                            
  scale_y_continuous(limits = c(0, 15)) +                   
  labs(
    title = "Number of Visits by Household Size Group",     
    x = "Household Size Group",                           
    y = "Number of Visits"                              
  ) +
  theme_minimal()                                         