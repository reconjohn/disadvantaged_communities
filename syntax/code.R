# libraries
library(tidyr)
library(dplyr)
library(stringr)
library(readxl)
library(stringdist)
library(tidyverse)
library(openxlsx)
library(readr)
library(scales)
library(sf)
library(stargazer)
library(Hmisc)


# necessary_dirs <- c("data",
#                     "data/raw",
#                     "data/derived",
#                     "output",
#                     "results",
#                     "syntax"
# )
# lapply(necessary_dirs, function(i) {
#   if(!dir.exists(i)) {
#     dir.create(i)
#   }
# })
# 
# 

## download geospatial data from each website
# for cejst: "https://screeningtool.geoplatform.gov/en/downloads"
# for dac: "https://energyjustice.egs.anl.gov/"
# for ej: "https://www.epa.gov/ejscreen/download-ejscreen-data"

# getOption('timeout')
# options(timeout=100)

# Define folder name
folder_name <- "./data"

# General download function
download_file <- function(url, folder, file_name = NULL, is_zip = FALSE, extract_nested_zip = FALSE){
  file_path <- file.path(folder_name, folder)
  if (!dir.exists(file_path)) dir.create(file_path, recursive = TRUE)
  file <- ifelse(is.null(file_name), basename(url), file_name)
  dest_file <- file.path(file_path, file)
  download.file(url, dest_file, mode = "wb")
  
  if (is_zip) {
    unzip(dest_file, exdir = file_path)
    
    nested_zip_file <- list.files(file_path, pattern = ".zip$", full.names = TRUE)
    if (extract_nested_zip) {
      if (length(nested_zip_file) > 0) unzip(nested_zip_file %>% tail(n=1), exdir = file_path)
    }
    unlink(nested_zip_file)
  }
}

# CEJST
folder <- "cejst"
download_file("https://static-data-screeningtool.geoplatform.gov/data-versions/1.0/data/score/downloadable/1.0-communities.csv", folder, "1.0-communities.csv")
download_file("https://static-data-screeningtool.geoplatform.gov/data-versions/1.0/data/score/downloadable/1.0-shapefile-codebook.zip", folder, is_zip = TRUE, extract_nested_zip = TRUE)

cejst_files <- list.files(file.path(folder_name, folder), pattern = ".shp$", full.names = TRUE)
cejst <- st_read(cejst_files) %>% 
  rename(GEOID = GEOID10) %>%
  dplyr::select(GEOID) %>%
  left_join(read_csv(file.path(folder_name, folder, "1.0-communities.csv")) %>% 
              rename(GEOID = `Census tract 2010 ID`), by = "GEOID") %>%
  dplyr::select(-`County Name`, -`State/Territory`) %>%
  st_transform(4269)

# DAC
folder <- "dac"
download_file("https://energyjustice.egs.anl.gov/resources/serve/DAC/DAC%20Shapefiles%20(v2022c).zip", folder, is_zip = TRUE)

dac_files <- list.files(file.path(folder_name, folder), pattern = ".shp$", full.names = TRUE)
dac <- st_read(dac_files) %>%
  dplyr::select(GEOID, population:eal_npctl) %>%
  st_transform(4269)

# EJ
folder <- "ej"
download_file("https://gaftp.epa.gov/EJScreen/2023/2.22_September_UseMe/EJSCREEN_2023_Tracts_with_AS_CNMI_GU_VI.gdb.zip", folder, is_zip = TRUE)

ej_files <- list.files(file.path(folder_name, folder), pattern = ".gdb$", full.names = TRUE)
ej <- st_read(ej_files) %>%
  dplyr::select(ID, ACSTOTPOP:P_D5_PWDIS) %>%
  rename(GEOID = ID)


# data aggregation
DAC <- ej %>% 
  dplyr::select(GEOID) %>% 
  st_join(cejst %>% 
            rename(ID = GEOID) %>% 
            dplyr::select(ID), largest = TRUE) 


DAC_whole <- DAC %>% 
  left_join(ej %>% 
              st_drop_geometry(), by = "GEOID") %>% 
  left_join(cejst %>%
              st_drop_geometry() %>% 
              left_join(dac %>% 
                          st_drop_geometry(), by = "GEOID") %>% 
              rename(ID = GEOID), by = "ID")
  
write_csv(DAC_whole %>% 
            st_drop_geometry() %>% 
            dplyr::select(-ID), "./results/DAC.csv")

save(DAC, file = "./results/DAC.Rdata")


## short version 
# r regex 
ft <- c(grep(pattern="90th",
             colnames(cejst)), 
        grep(pattern="underinvestment|mine|FUDS",
             colnames(cejst)),
        grep(pattern="low income|low HS",
             colnames(cejst)))

ord <- c(ft[duplicated(ft)],
         which(colnames(cejst) == "Identified as disadvantaged"))

nm <- colnames(cejst)[ord[order(ord)]][-31:-33] # remove duplicated variables for (island areas)

nm <-  nm %>%
  gsub(".*for (.*?) and.*", "\\1", .) %>%
  ifelse(sapply(strsplit(.," "), length) > 12,
         gsub(".*by (.*?) or.*", "\\1", .), .) %>%
  ifelse(sapply(strsplit(., " "), length) > 10,
         gsub("^(.*?) as.*", "\\1", .), .) %>%
  ifelse(sapply(strsplit(., " "), length) > 9,
         gsub(".*at (.*?) in.*", "\\1", .), .) %>%
  ifelse(sapply(strsplit(., " "), length) > 7,
         gsub(".*federal (.*?)$", "\\1", .), .) %>%
  ifelse(sapply(strsplit(., " "), length) > 7,
         gsub(".*historic (.+) and.*", "\\1", .), .) %>%
  ifelse(sapply(strsplit(., " "), length) > 5,
         gsub(".*Used (.+) \\(FUDS\\).*", "\\1", .), .) %>%
  ifelse(sapply(strsplit(., " "), length) > 3,
         gsub(".*one (.*?)$", "\\1", .), .) %>%
  gsub("^(.*?),.*", "\\1", .) %>% 
  gsub(".*as (.*?)$", "\\1", .) %>% 
  tolower()

colnames(cejst)[ord[order(ord)]][-31:-33] <- nm

cejst <- cejst %>% 
  dplyr::select(GEOID, ord[order(ord)][-31:-33]) 



DAC_sub <- DAC %>% 
  left_join(ej %>% 
              st_drop_geometry() %>% 
              dplyr::select(matches("GEOID|PCT|D2|D5")) %>% 
              dplyr::select(!matches("P_|1960")), by = "GEOID") %>% 
  left_join(cejst %>%
              st_drop_geometry() %>% 
              left_join(dac %>% 
                          st_drop_geometry() %>% 
                          dplyr::select(GEOID, DACSCORE), by = "GEOID") %>% 
              rename(ID = GEOID), by = "ID")

write_csv(DAC_sub %>% 
            st_drop_geometry() %>% 
            dplyr::select(-ID), "./results/DAC_s.csv")

