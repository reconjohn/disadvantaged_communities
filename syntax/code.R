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


folder_name <- "./data"
download_zip <- function(url, folder){
  zip_file <- paste0(folder_name,"/",folder,".zip")
  download.file(url, zip_file, mode = "wb")
  unzip(zip_file, exdir = paste0(folder_name,"/",folder))
}

download_csv <- function(url, folder){
  file <- paste0(folder_name,"/",folder,"/",folder,".csv")
  download.file(url, file, mode = "wb")
}

#CEJST
folder <- "cejst"
download_csv("https://static-data-screeningtool.geoplatform.gov/data-versions/1.0/data/score/downloadable/1.0-communities.csv",
             folder)
download_zip("https://static-data-screeningtool.geoplatform.gov/data-versions/1.0/data/score/downloadable/1.0-shapefile-codebook.zip",
         folder)
unzip(paste0(folder_name,"/",folder,"/",list.files(paste0(folder_name,"/",folder)) %>% tail(n = 1)), 
      exdir = paste0(folder_name,"/",folder))

cejst <- st_read(paste0(folder_name,"/",folder,"/",
                        list.files(paste0(folder_name,"/",folder),pattern=".shp"))) %>% 
  rename(GEOID = GEOID10) %>%
  dplyr::select(GEOID) %>%
  left_join(read_csv(file = paste0(folder_name,"/",folder,"/",folder,".csv")) %>%
              rename(GEOID = `Census tract 2010 ID`), by = "GEOID") %>%
  dplyr::select(-`County Name`,-`State/Territory`) %>% 
  st_transform(4269)

unlink(paste0(folder_name,"/",folder,".zip"))

#DAC
folder <- "dac"
download_zip("https://energyjustice.egs.anl.gov/resources/serve/DAC/DAC%20Shapefiles%20(v2022c).zip",
         folder)
dac <- st_read(paste0(folder_name,"/",folder,"/",
                      list.files(paste0(folder_name,"/",folder),pattern=".shp"))) %>% 
  dplyr::select(GEOID, population:eal_npctl) %>% 
  st_transform(4269)

unlink(paste0(folder_name,"/",folder,".zip"))

#EJ
folder <- "ej"
download_zip("https://gaftp.epa.gov/EJScreen/2023/2.22_September_UseMe/EJSCREEN_2023_Tracts_with_AS_CNMI_GU_VI.gdb.zip",
         folder)
ej <- st_read(paste0(folder_name,"/",folder,"/",
                     list.files(paste0(folder_name,"/",folder)))) %>% 
  dplyr::select(ID, ACSTOTPOP:P_D5_PWDIS) %>%
  rename(GEOID = ID)

unlink(paste0(folder_name,"/",folder,".zip"))


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

