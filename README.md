
# Analyzing DMARC Food Pantry Visitations
**Authors:** Nolan Henze, Sophie Meronek, Nathan Oelsner, and Eric Pfaffenbach  
**Date:** 5/13/2025  

### Disclaimer:
Some of the code was made using ChatGPT, however, we also wrote a majority of the code ourselves.

## Introduction
This repository contains the code and data required for our Capstone Project for analyzing the visitors of the DMARC Food Pantry.

The goal of this project was to assess the growing need for the food pantries in the DMARC system. Our main goal was to predict the trend of visitors and to characterize the people who are using the food pantries. We collaborated with DMARC Food Pantries, an organization that runs a network of food pantries to help provide those in need with food and other essentials. We also wanted to look into potential ways that DMARC could better support their visitors by highlighting locations that require greater support.

The recommendations will be geared towards DMARC and specifically towards different locations of their food pantries.

## Data Source and Preparation
For this project, we used two datasets: **DMARC Visitation Survey** and **Red Barrel Data**. These datasets were provided to us by DMARC and will not be included in the public repository.

All code involved in cleaning the data can be found in the folder **src/clean_data_code**. There are 3 scripts in this folder for cleaning the Red Barrel Data for each year and 2 scripts for cleaning the DMARC visitor survey.

### DMARC Visitation Survey
The DMARC Visitation Survey is a survey conducted by DMARC to keep track of the people and households using their service. It gathers data on demographics, employment, and program participation. There has been a change in the form used, so there are two codes for cleaning the data.

The original dataset includes the columns: `service_name`, `afn`, `served_date`, `annual_income`, `fed_poverty_level`, `individual_id`, `lmn`, `dob`, `gender`, `race`, `ethnicity`, `education`, `family_type`, `snap_household`, `zip`, `location`, `housing`, `housing_type`, `homeless`, and `income_source`.

The new dataset includes the columns: `primaryKey`, `clientId`, `houseHoldIdAfn`, `middleName`, `dob`, `gender`, `race`, `education`, `foodstamps`, `dietaryIssue`, `veteran`, `service`, `servedDate`, `location`, `locationLat`, `locationLng`, `fiscalYear`, `householdMembers`, `fedPovertyLevel`, `annualIncome`, `incomeSource`, and `category`.

The data will be used to create a few different datasets of aggregated data, while also being used to run several different models.

### Red Barrel Data
The Red Barrel Data is collected from the locations that are a part of the program. It is then stored by year to keep track of the donations made. The data is in Excel format.

The Red Barrel Data has the columns: `LOCATION`, `ITEMS`, `DATE`, and `VALUE`.

The data will be used to examine trends in donations made by the general public at the participating grocery stores.

## Data Preparation
### DMARC Survey
The R scripts `src/clean_data_code/original_data_cleaning.R` and `src/clean_data_code/new_data_clean.R` read raw CSV data, convert date columns to proper formats, and remove invalid birth years. They create demographic indicators, aggregate data to household-visit and household-year levels, and calculate summary statistics like number of visits and average household composition. Finally, they export two cleaned datasets as CSV files for easier reuse, allowing users to avoid rerunning the entire cleaning process. File paths must be updated manually before saving.

### Red Barrel
For the Red Barrel Data, we wanted to look at the monetary value and how it changed based on location and time of year. The CLEANRB file script reads all sheets from an Excel file, cleans dates and location names, combines the data, and selects and sorts relevant columns for analysis. This is done by year.

## Repository Structure
The repository contains the following key sections:

- `src`: Scripts for data analysis and model development.
- `clean_data_code`: The scripts for cleaning the data.
- `models`: The models that were created to analyze the data.
- `visualization_code`: The scripts to show different aspects of the data visually.
- `data`: The original datasets and new aggregated datasets.
- `raw_data`: The original data given to us.
- `outputs`: A few of the visualizations we ended up making.

## Requirements
To run the code in this repository, you will need the following installed:

- **R (version 4.0.0 or higher)**

Required R packages (run the following code to install the packages in R):

```r
install.packages(c("tidyverse", "ggthemes", "logistf", "glmnet", "haven",
                   "knitr", "ggplot2", "RColorBrewer", "pROC", "lubridate",
                   "sf", "dplyr", "tigris", "readxl", "readr", "MASS", "car", "randomForest",
                    "data.table", "purr", "viridis", "scales"  ))
```

## Variables
During our exploration, we wanted to look into predicting the trend of visitors per month, the characteristics that impacted the number of visits per household, and the different variables that could lead to more donations in Red Barrel.

In order to explore each of these questions, we used different variables to predict outcomes.

For the negative binomial model, and the lasso and ridge regression, we looked into how different characteristics at the household level affected the number of visits.

For the time series, we looked into how time affected the number of visitors while also accounting for how COVID may have influenced the outcome. To reflect the COVID impact, we utilized a dummy boolean variable to indicate when COVID occurred.

For SNAP, we examined how visits changed when a person was on SNAP versus when they were not.

## Methods
The analysis follows these steps:

1. **Data Cleaning and Preprocessing**: Preparing the data for analysis.
2. **Data Exploration**: Looking for noticeable trends between variables.
3. **Model Training**: Training the different models that we used.
4. **Potential Conclusions**: Looking at the major takeaways from each model.

## Models Used
### Lasso and Ridge
The R script `src/models/lass_ridge_year.R` applies Lasso and Ridge regression with a Poisson model to predict household visit counts using demographic and socioeconomic data. After cleaning and splitting the data, it fits models using cross-validation to find optimal parameters. Predictions are evaluated with RMSE, MAE, and residual plots. Despite the analysis, the models performed poorly, indicating weak predictive power and limited significance of the included variables in forecasting the number of visits. This model may not have been appropriate, so we also tried a negative binomial model.

### Negative Binomial
The R script `src/models/neg_binom_model.R` models the number of pantry visits per household using Negative Binomial regression due to overdispersion in the data. It cleans the dataset, visualizes the distribution, and converts character columns to factors. After fitting the model, it checks for multicollinearity using VIF and removes correlated or insignificant variables.

### Time Series
The R script `src/models/STAT_190_Time_Series_by_ZIP_Dummy.R` builds time series models to predict monthly food pantry visits by ZIP code. It preprocesses client-level data, aggregates visit counts, and adds a COVID-period dummy variable. Linear models are fitted for each ZIP to analyze trends and forecast future visits. Top ZIP codes are identified, and actual vs. predicted visits are visualized. Growth rates are extracted by ZIP to compare trends, showing how visit frequency changed over time, including during COVID-19.

## Code Execution
To reproduce the results:

1. Download the data and place it into the `data/raw_data/` folder.
2. Download the files into the `src/` directory.
3. Install the required packages by running the setup script.
4. Run and update the script `src/clean_data_code/new_data_clean.R` to create the new datasets to run the models.
5. Run the scripts in `src/models` to see the models described above.
6. Run the scripts in `src/visualization_code` to see some of the characteristics of the data.

## Results
### Time Series
When looking at the time series models, we found that the total number of visits has been increasing over time, which was expected. So we decided to examine trends in different ZIP codes and how time affects those counts. We found that depending on the ZIP code, there could be either an increasing or decreasing number of visitors.

Notably, ZIP code 50301 was heavily utilized, which reflects the fact that it is a P.O. Box and is most likely used by individuals experiencing some form of homelessness. In addition, we found that 50315 also has an increasing number of visitors. This could reflect the fact that the food pantry located in 50315 is experiencing a 200% increase in visitors from 2023 to 2024.

On the other hand, we found that ZIP codes 50314 and 50317 are experiencing a decrease in the number of visitors.

### Common Characteristics of Visitors
For the negative binomial model, we found that SNAP participation, household size, and poverty level were the most significant predictors of visit frequency. This made us interested in how SNAP affects visitation rates. We found that those who are on SNAP saw a decrease in visits after losing SNAP.

We also found that food inflation seems to correlate with the average number of visits. In addition, we observed that the higher someone's income is, the more likely they are to visit the food pantry — which is counterintuitive and may reflect incomplete data or reporting discrepancies.

### Red Barrel Conclusions
Since we found that the number of visitors is increasing, we were interested in how DMARC could leverage donations through the Red Barrel program.

We found that Hy-Vee stores in areas with increased commerce — such as Windsor Heights, Mills Civic, and Urbandale — had the most donations. Additionally, donation levels increased in the final months of the year. This could point toward potential collaboration opportunities between DMARC and Hy-Vee to increase the number of donations.

## Disclaimer
This project was completed for STAT 190: Case Studies in Data Analytics at Drake University. We partnered with DMARC for this project, and all recommendations were tailored to their plans and needs.
