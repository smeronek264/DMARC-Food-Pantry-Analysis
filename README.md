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

For data preparation for the DMARC survey, we turned different demographics such as age, race, gender, and food stamps into binary terms (1 for true and 0 for false).

Once we had created these binary variables, we needed to aggregate the individual data to the household level. This was done by grouping each household together and then taking the sum of all demographic attributes to determine how many of each category were in the household. For example, if 4 individuals had a 1 in the value for **CHILDREN**, then the household demographic would show 4 elderly individuals.

#### Red Barrel

For the Red Barrel Data, we wanted to look at the monatary value and how it changed based on location and time of the year. To do this, we decided to 

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

Below is a list of predictor (X) variables used to predict the outcome (Y) variables.

### Predictor Variables (X)
- **hhsize**: The number of people in a household.
- **female**: The number of females in a household.
- **hispanic**: The number of Hispanics in a household.
- **black**: The number of Black individuals in a household.
- **kids**: The number of children (under 18) in a household.
- **elderly**: The number of seniors (over 60) in a household.
- **education**: The number of people with a college degree in a household.
- **married**: The number of married individuals in a household.

### Outcome Variables (Y)
- **FSFOODS**: The household lacks enough food and/or variety.
- **FSSTATUS**: The household lacks food security.

## Methods

The analysis follows these steps:

1. **Data Cleaning and Preprocessing**: Preparing the data for analysis.
2. **Model Training**: Training a predictive model using the CPS data.
3. **Model Application**: Applying the model to ACS data to predict food insecurity in Iowa.
4. **Aggregation**: Aggregating household-level predictions to the PUMA level.

The model is trained using the CPS data and tested for accuracy. For each outcome variable (Y), two Bernoulli models are trained with a logit link function using Lasso (where unimportant variables have coefficients set to zero) and Ridge (where unimportant variables have coefficients close to zero). Since food insecurity is a binary outcome (insecurity exists or not), the logit link ensures the output remains between 0 and 1. The models are evaluated using testing data, and the one with the highest Area Under the Curve (AUC) on a ROC plot is selected as the best model. Finally, the best model is used to predict food insecurity in the ACS data, and weighted means are calculated for each PUMA to identify regions with the highest probabilities of food insecurity.

## Code Execution

To reproduce the results:

1. Download the data and place it into the `data/raw_data/` folder.
2. Download the files into the `src/` directory.
3. Install the required packages by running the setup script.
4. Run and update the script `src/clean_data_code/new_data_clean.R` to create the new datasets to run the models.
5. Run the scripts in `src/models` to see the models described above.
6. Run the scripts in `src/visualization_code` to see some of the characteristics of the data. 

## Disclaimer

This project was completed for STAT 190: Case Studies in Data Analytics at Drake University. We partnered with DMARC for this project, and all recommendations were tailored to their plans and needs.
