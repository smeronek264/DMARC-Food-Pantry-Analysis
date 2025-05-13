# Author: Sophie Meronek
# Description: Will read in the 2024 Red Barrel data
# Disclaimer: I utilized ChatGPT to create this code since it was
# reading in excel sheets

# install.package("readxl")

library(readxl)
library(tidyverse)
library(lubridate)
library(ggplot2)
library(dplyr)

data_path = "data/data_raw/RB_2024.xlsx"

# Function to read multiple sheets from an Excel file
multiplesheets <- function(fname) {
  sheets <- readxl::excel_sheets(fname)
  tibble <- lapply(sheets, function(x) readxl::read_excel(fname, sheet = x))
  data_frame <- lapply(tibble, as.data.frame)
  names(data_frame) <- sheets
  print(data_frame)
}

# Path to the Excel file

# Call the function on
RB_2024_All= multiplesheets(data_path)

RB2024_raw = data.frame()


for (i in RB_2024_All) {
  
  curr_sect <- i %>%
    mutate(
      Date_num = as.integer(DATE),
      clean_location = gsub("\\s*\\(.*\\)", "", LOCATION),
      clean_Date = as.Date(Date_num, origin = "1899-12-30")
    )
  
  RB2024_raw <- rbind(RB2024_raw, curr_sect)  # Append to RB2024_raw
}


RB2024 <- dplyr::select(RB2024_raw, `clean_Date`, `clean_location`, `ITEMS`, `VALUE`)
RB2024 = RB2024[complete.cases(RB2024), ]
RB2024 = RB2024[order(as.Date(RB2024$clean_Date, format="%Y/%m/%d")),]