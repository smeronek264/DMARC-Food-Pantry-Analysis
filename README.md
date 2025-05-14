# Analyzing DMARC Food Pantry Visitiations

**Authors**: Nolan Henze, Sophie Meronek, Nathan Oelsner, and Eric Pfaffenbach  
**Date**: 5/13/2025

**Disclaimer**: Some of the code was made using CHATGPT, however, we also wrote a majority of the code.

## Introduction

This repository contains the code and data required for our Capston Project for analyzing the visitors of the DMARC Food Pantry.

The goal of this project was to access the growing need for the food pantries in the DMARC system. Our main goal was to predict the trend of visitors and to characterize the people who are using the food pantries. We collaborated with **DMARC Food Pantries**, an organization that runs a network of food pantries to help provide those in need with food and other essentials. We also wanted to look into potential ways that DMARC could better support their visitors by highlighting locations that 

The recommendations will be geared towards DMARC and specifically towards different locations of their food pantries.

## Data Source and Preparation

For this project, we used two datasets: **DMARC Visitation Survey** and **Red Barrel Data**. These datasets were provided to us by DMARC and will not be included in the public repository.

All code involved in cleaning the data can be found in the folder `scr/clean_data_code`. There are 3 scripts in this folder for cleaning the Red Barrel Data for each year and 2 scripts for cleaning the DMARC vistor survey.

### DMARC Visitation Survey

The **DMARC Visitation Survey** is a survey conducted by DMARC to keep track of the people and the household using their service. It gathers data on demographics, employment, and program participation. There has been a change in form used so there is two codes for cleaning the data.

The original dataset includes the columns service_name, afn, served_date, annual_income, fed_poverty_level, individual_id, lmn, dob, gender, race, ethnicity, education, family_type, snap_household, zip, location, housing, housing_type, homless, and income_source.

The new dataset includes the columns primaryKey, clientId, houseHoldIdAfn, middleName, dob, gender, race, education, foodstamps, dietaryIssue, veteran, service, servedDate, location, locationLat, locationLng, fiscalYear, householdMembers, fedPovertyLevel, annualIncome, incomeSource, and category.

The data will be used to create a few different datasets of aggregated data, while also being used to run a few different models.

### Red Barrel Data

The **Red Barrel Data** is collected from the locations that is a part of the program. It is then stored by the year to keep track of the donations made. The data will be in the format of an Excel file.

The Red Barrel Data has the columns LOCATION, ITEMS, DATE, and VALUE.

The data will be used to look into the trends of donations given to by the general public at the particpating grocery stores.

### Data Preparation

#### DMARC Survey

The R scripts `src/clean_data_clean/original_data_cleaning.R` and `src/clean_data_clean/new_data_clean.R` reads raw CSV data, converts date columns to proper formats, and removes invalid birth years. It creates demographic indicators, aggregates data to household-visit and household-year levels, and calculates summary statistics like number of visits and average household composition. Finally, it exports two cleaned datasets as CSV files for easier reuse, allowing users to avoid rerunning the entire cleaning process. File paths must be updated manually before saving.

#### Red Barrel

For the Red Barrel Data, we wanted to look at the monatary value and how it changed based on location and time of the year. The CLEANRB file scripts reads all sheets from an Excel file, cleans dates and location names, combines the data, and selects and sorts relevant columns for analysis. This is done by the year.

## Repository Structure

The repository contains the following key sections:

- **scr**: Scripts for data analysis and model development.
    - **clean_data_code**: The scripts for cleaning the data.
    - **models**: The models that were created to analyze the data.
    - visualization_code**: The scripts to show different aspects of the data visually.
- **data**: The original datasets and new aggregated datasets.
    - **raw_data**: The ordiginal data givent to us.
- **outputs**: A few of the visualizations we ended up make.

## Requirements

To run the code in this repository, you will need the following installed:

- R (version 4.0.0 or higher)
- Required R packages (run the following code to install the packages in R)

```r
install.packages(c("tidyverse", "ggthemes", "logistf", "glmnet", "haven",
                   "knitr", "ggplot2", "RColorBrewer", "pROC", "lubridate",
                   "sf", "dplyr", "tigris"))
```

## Variables

During our exploration, we wanted to look into predicting the trend of visitors per month, the characteristics that impacted the number of visits per household, and the different variables that could lead to more donations in Red Barrel.

In order to look into each of the questions, we used different variables to predict.

For the negative binomial model, and the lasso and ridge regression we looked into how different characterisitcs on the household level affected the number of visitors.

For the time series, we looked into how time affected the number of visitors while also taking into account how COVID could have affected the outcome. In order to reflect the COVID impact, we utilized a dummy boolean variable to show when COVID was.

For SNAP, we looked into how visits change when a person is on SNAP and when they were not on SNAP.

## Methods

The analysis follows these steps:

1. **Data Cleaning and Preprocessing**: Preparing the data for analysis.
2. **Data Explorations**: Looking for noticable trends between varaibles.
3. **Model Training**: Train the different models that we were using.
4. **Potential Conclusions**: Look at the major takeways we have with each model.

### Models Used

#### Lasso and Ridge 

The R script `src/models/lass_ridge_year.R` applies Lasso and Ridge regression with a Poisson model to predict household visit counts using demographic and socioeconomic data. After cleaning and splitting the data, it fits models using cross-validation to find optimal parameters. Predictions are evaluated with RMSE, MAE, and residual plots. Despite the analysis, the models performed poorly, indicating weak predictive power and limited significance of the included variables in forecasting the number of visits. Also this model overall could the wrong model to used, so we ended up trying a negative binomial.

#### Negative Binomial

The R script `src/models/neg_binom_model.R` models the number of pantry visits per household using Negative Binomial regression due to overdispersion in the data. It cleans the dataset, visualizes the distribution, and converts character columns to factors. After fitting the model, it checks for multicollinearity using VIF and removes correlated or insignificant variables. The final model identifies SNAP participation, household size, and poverty level as the most significant predictors of visit frequency.

#### Time Series

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

When looking at the time series models we found that the total 

### Common Characteristics of Visitors

### Red Barrel Conclusions

## Disclaimer

This project was completed for STAT 190: Case Studies in Data Analytics at Drake University. We partnered with DMARC for this project, and all recommendations were tailored to their plans and needs.
