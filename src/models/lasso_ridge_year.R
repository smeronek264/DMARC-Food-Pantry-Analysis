# Author: Sophie Meronek
# Description: Created a lasso and ridge regression of a poisson plot to see if we
# could have any significant predictors. Overall the model did not do well predicting
# number of visits.

rm(list = ls()) 

# Load necessary libraries
library(ggplot2)           # For creating various plots
library(RColorBrewer)      # For color palettes
library(tidyverse)         # For efficient data manipulation and plotting
library(pROC)              # For ROC curve analysis
library(glmnet)            # For lasso and ridge regression models
library(lubridate)         # For easy manipulation of date and time variables
library(sf)                # For spatial data handling (shapefiles)
library(dplyr)             # For data manipulation
library(tigris)            # For working with US Census shapefiles

# Load dataset
visits_household_year = read.csv("data/visits_household_year.csv")

# Remove rows with missing values
data_set = visits_household_year[complete.cases(visits_household_year), ]

# Basic data visualization
ggplot(data = data_set) +
  geom_bar(aes(x = num_visits))  # Bar plot of number of visits

ggplot(data = data_set) +
  geom_point(aes(x = n_female, y = log(num_visits)))  # Scatter plot of num_visits vs n_female

##### SPLITTING THE DATA INTO TRAINING AND TESTING SETS #####
RNGkind(sample.kind = "default")  # Set kind of random number generator
set.seed(122111598)               # Set seed for reproducibility

# Create training and testing index (70% train, 30% test)
train.idx = sample(x = 1:nrow(data_set), size = floor(0.7 * nrow(data_set)))
train.df = data_set[train.idx, ]     # Training data
test.df = data_set[-train.idx, ]     # Testing data

# Remove any remaining incomplete rows in training set
train.df <- train.df[complete.cases(train.df), ]

##### DESIGN MATRICES FOR GLMNET #####
# Create design matrix for training data (excluding intercept)
x.train <- model.matrix(num_visits ~ snap_household + annual_income + fed_poverty_level +
                          homeless + n_household + n_female + n_child +
                          n_elderly + n_black + n_american_Indian + n_multi_Race +
                          n_hispanic + served_month, data = train.df)[, -1]

# Create design matrix for testing data (excluding intercept)
x.test <- model.matrix(num_visits ~ snap_household + annual_income + fed_poverty_level +
                         homeless + n_household + n_female + n_child +
                         n_elderly + n_black + n_american_Indian + n_multi_Race +
                         n_hispanic + served_month, data = test.df)[, -1]

# Define response variables for training and testing
y.train = as.vector(train.df$num_visits)
y.test = as.vector(test.df$num_visits)

##### CROSS-VALIDATION FOR LASSO AND RIDGE #####
# Perform cross-validation for Lasso (alpha = 1) with Poisson family
lr_lasso_cv <- cv.glmnet(x.train, y.train, family = "poisson", alpha = 1)

# Perform cross-validation for Ridge (alpha = 0) with Poisson family
lr_ridge_cv <- cv.glmnet(x.train, y.train, family = "poisson", alpha = 0)

# Plot CV results for Lasso and Ridge
plot(lr_lasso_cv)
plot(lr_ridge_cv)

# Extract best lambda values
best_lasso_lambda = lr_lasso_cv$lambda.min
best_ridge_lambda = lr_ridge_cv$lambda.min

##### FITTING FINAL MODELS #####
# Fit final Lasso model using best lambda
final_lasso = glmnet(x.train, y.train, family = "poisson", alpha = 1, lambda = best_lasso_lambda)

# Fit final Ridge model using best lambda
final_ridge = glmnet(x.train, y.train, family = "poisson", alpha = 0, lambda = best_ridge_lambda)

##### PREDICTIONS #####
# Generate predictions on test set using Lasso and Ridge
lasso_pred <- as.vector(predict(final_lasso, x.test, type = "response"))
ridge_pred <- as.vector(predict(final_ridge, x.test, type = "response"))

# Add predictions to test dataframe
test.df$l_prediction = lasso_pred
test.df$r_prediction = ridge_pred

# Plot observed vs predicted values
plot(test.df$num_visits, test.df$l_prediction, main = "Observed vs Predicted Counts", 
     xlab = "Observed", ylab = "Predicted")
abline(0, 1, col = "red")  # Line y = x for reference

##### MODEL PERFORMANCE METRICS #####
# Calculate RMSE and MAE for Lasso
rmse_lasso <- sqrt(mean((test.df$num_visits - test.df$l_prediction)^2))
mae_lasso <- mean(abs(test.df$num_visits - test.df$l_prediction))

# Calculate RMSE and MAE for Ridge
rmse_ridge <- sqrt(mean((test.df$num_visits - test.df$r_prediction)^2))
mae_ridge <- mean(abs(test.df$num_visits - test.df$r_prediction))

# Print performance metrics
print(paste("Lasso RMSE:", rmse_lasso))
print(paste("Lasso MAE:", mae_lasso))
print(paste("Ridge RMSE:", rmse_ridge))
print(paste("Ridge MAE:", mae_ridge))

##### COEFFICIENTS #####
# Extract coefficients from Lasso and Ridge models
lr_lasso_coeff = coef(lr_lasso_cv, s = "lambda.min") %>% as.matrix()
lr_ridge_coeff = coef(lr_ridge_cv, s = "lambda.min") %>% as.matrix()

# Print coefficients
print("Lasso Coefficients:")
print(lr_lasso_coeff)

print("Ridge Coefficients:")
print(lr_ridge_coeff)

# Calculate residuals for both models
test.df$lasso_resid <- test.df$num_visits - test.df$l_prediction
test.df$ridge_resid <- test.df$num_visits - test.df$r_prediction

# Plot residuals vs predicted for Lasso
ggplot(test.df, aes(x = l_prediction, y = lasso_resid)) +
  geom_point(alpha = 0.5) +
  geom_hline(yintercept = 0, color = "red", linetype = "dashed") +
  labs(title = "Lasso: Residuals vs Predicted",
       x = "Predicted Counts", y = "Residuals") +
  theme_minimal()

# Plot residuals vs predicted for Ridge
ggplot(test.df, aes(x = r_prediction, y = ridge_resid)) +
  geom_point(alpha = 0.5) +
  geom_hline(yintercept = 0, color = "blue", linetype = "dashed") +
  labs(title = "Ridge: Residuals vs Predicted",
       x = "Predicted Counts", y = "Residuals") +
  theme_minimal()
