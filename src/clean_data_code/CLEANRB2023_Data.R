# Author: Sophie Meronek
# Description: Will read in the 2023 Red Barrel data
# Disclaimer: I utilized ChatGPT to create this code since it was
# reading in excel sheets

# install.package("readxl")

library(readxl)
library(tidyverse)
library(lubridate)
library(ggplot2)
library(dplyr)

data_path = "date/data_raw/RB_2023.xlsx"

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
RB_2023_All= multiplesheets(data_path)

RB2023_raw = data.frame()


for (i in RB_2023_All) {
  
  curr_sect <- i %>%
    mutate(
      Date_num = as.integer(DATE),
      clean_location = gsub("\\s*\\(.*\\)", "", LOCATION),
      clean_Date = as.Date(Date_num, origin = "1899-12-30")
    )
  
  RB2023_raw <- rbind(RB2023_raw, curr_sect)  # Append to RB2023_raw
}


RB2023 <- dplyr::select(RB2023_raw, `clean_Date`, `clean_location`, `ITEMS`, `VALUE`)
RB2023 = RB2023[complete.cases(RB2023), ]
RB2023 = RB2023[order(as.Date(RB2023$clean_Date, format="%Y/%m/%d")),]










