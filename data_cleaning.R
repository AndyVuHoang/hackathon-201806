# Ideally this would be replaced with creating a `.Rproject` file 
# used in conjunction with the `here` package 
# setwd('C:\\Users\\reulogio\\Desktop\\throwaway\\hackathon')

# Created By: Raul Eulogio


# Purpose -----------------------------------------------------------------

# This script was created to clean xlsx file and return tidy csv files. 
# Serves as a run only once script, where loading csv files into working
# environment is recommended path since running/sourcing this script everytime 
# to load data would take a while. 

# Load Packages -----------------------------------------------------------

# If needed this would handle downloading all dependencies (except `here` package)
# install.packages("tidyverse")
library(magrittr)
library(here)
here::here()

# Other Dependencies (From tidyverse):
# dplyr
# purrr
# readxl
# lubridate
# tidyr

# Get file path
file_path <- here::here("hackathon_20180621.xlsx") 


# Load Data ---------------------------------------------------------------

# Load data into a list of dataframes
my_data <- file_path %>%
  readxl::excel_sheets() %>%
  purrr::set_names() %>%
  purrr::map(readxl::read_xlsx, path = file_path)

# Create dataframes for each sheet
chemistry <- my_data[["Chemistry"]]
bacteria <- my_data[["Bacteria"]]
nutrients <- my_data[["Nutrients"]]
site_list <- my_data[["SiteList"]]
central_coast_standards <- my_data[["CentralCoastStandards"]]
la_basin_standards <- my_data[["LABasinStandards"]]

# Chemistry ---------------------------------------------------------------

# Data cleaning
chemistry <- chemistry %>%
  # Lower caps everything 
  dplyr::mutate(TestMaterial = tolower(TestMaterial)) %>%
  dplyr::mutate(ParameterCode = tolower(ParameterCode)) %>%
  dplyr::mutate(SampleType = tolower(SampleType)) %>%
  dplyr::mutate(Units = tolower(Units)) %>%
  dplyr::mutate(TeamNumber = tolower(TeamNumber)) %>%
  # Remove character string representing NA
  dplyr::mutate(TeamNumber = replace(TeamNumber, TeamNumber == 'n/a', NA)) %>%
  # Convert SampleCollectionTime to datetime format
  dplyr::mutate(SampleCollectionTime = lubridate::as_datetime(SampleCollectionTime)) %>%
  # Convert SampleDate to date format
  dplyr::mutate(SampleDate = lubridate::as_date(SampleDate))

# Bacteria ----------------------------------------------------------------

# Data Cleaning 
bacteria <- bacteria %>%
  # Lower caps everything
  dplyr::mutate(TestMaterial = tolower(TestMaterial)) %>%
  dplyr::mutate(SampleType = tolower(SampleType)) %>%
  # Replace misspelling of word
  dplyr::mutate(ParameterCode = replace(ParameterCode, ParameterCode == "E. Coil", "E. Coli")) %>%
  # Change format for time variables
  dplyr::mutate(SampleCollectionTime = strftime(SampleCollectionTime, format = "%H:%M:%S", tz = 'UTC')) %>%
  dplyr::mutate(IncubatorEntryTime = strftime(IncubatorEntryTime, format = "%H:%M:%S", tz = 'UTC')) %>%
  dplyr::mutate(ResultReadTime = strftime(ResultReadTime, format = "%H:%M:%S", tz = 'UTC'))

# Nutrients ---------------------------------------------------------------

# Remove whitespace from column names to make more readable
names(nutrients) <- gsub(" ", "", names(nutrients))

# Data Cleaning 
nutrients <- nutrients %>%
  # Lower caps everything
  dplyr::mutate(SampleDate = lubridate::as_date(SampleDate)) %>%
  dplyr::mutate(SampleTime = strftime(SampleTime, format = "%H:%M:%S", tz = 'UTC'))


# In case there would be benefits to create datetime columns from date and time columns here's how to do so 
# nutrients %>%
  # tidyr::unite(col = "CollectionDatetime", c("SampleDate", "SampleTime"), sep = " ")
  # OR: dplyr::mutate(SampleCol = paste(SampleDate, SampleTime))

# Site List ---------------------------------------------------------------

# Remove whitespace from column names to make more readable
names(site_list) <- gsub(" ", "", names(site_list))

# Data Cleaning 
site_list <- site_list %>%
  # Lower caps
  dplyr::mutate(SamplingFrequency = tolower(SamplingFrequency)) %>%
  # Separate Column containing Lat and Long to two columns
  tidyr::separate(`GeographicCoordinates(DecimalDegrees)`, c("Longitude", "Latitude"), sep = ",")


# Clean Standard Column Names ---------------------------------------------

names(central_coast_standards) <- gsub(" ", "", names(central_coast_standards))
names(la_basin_standards) <- gsub(" ", "", names(la_basin_standards))

# Output CSV Files --------------------------------------------------------
clean_data = list("Chemistry" = chemistry, 
                  "Bacteria" = bacteria, 
                  "Nutrients" = nutrients, 
                  "SiteList" = site_list, 
                  "CentralCoastStandards" = central_coast_standards, 
                  "LABasinStandards" = la_basin_standards)

# Create array containing output file name and path
csv_names <- sprintf("data/%s.csv", names(my_data))

# Here we're checking if any of the previously created csv files exist in the
# data directory. If not then the for-loop will run and output csv files. 
if (any(!file.exists(csv_names))) {
  # for-loop to create new csv files with tidy data
  for (i in 1:length(clean_data)){
    clean_data[[i]] %>%
      readr::write_csv(path = csv_names[[i]])
  }
  print("Done")
} else {
  print("CSV files have already been created!")
  print("To load data into working environment load CSV files directly using read_csv/read.csv.")
}


